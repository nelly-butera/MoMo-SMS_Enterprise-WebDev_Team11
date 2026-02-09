"""Plain Python REST API for MoMo SMS transactions."""

from __future__ import annotations

import base64
import json
import os
import sys
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, Dict, List, Tuple
from urllib.parse import parse_qs, urlparse

REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from dsa.parse_xml import load_transactions_json, parse_sms_xml  # noqa: E402

DATA_DIR = REPO_ROOT / "data"
DEFAULT_XML = DATA_DIR / "raw" / "modified_sms_v2.xml"
FALLBACK_XML = DATA_DIR / "raw" / "momo.xml"
DEFAULT_JSON = DATA_DIR / "processed" / "transactions.json"

API_USER = os.getenv("API_USER", "admin")
API_PASS = os.getenv("API_PASS", "admin123")


def _load_transactions() -> List[Dict[str, Any]]:
    if DEFAULT_JSON.exists():
        return load_transactions_json(DEFAULT_JSON)
    if DEFAULT_XML.exists():
        return parse_sms_xml(DEFAULT_XML)
    if FALLBACK_XML.exists():
        return parse_sms_xml(FALLBACK_XML)
    return []


def _build_index(transactions: List[Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
    return {str(tx.get("id")): tx for tx in transactions}


def _next_id(transactions: List[Dict[str, Any]]) -> str:
    numeric_ids = [int(tx_id) for tx_id in (str(tx.get("id")) for tx in transactions) if tx_id.isdigit()]
    if numeric_ids:
        return str(max(numeric_ids) + 1)
    return str(len(transactions) + 1)


class TransactionsAPI(BaseHTTPRequestHandler):
    server_version = "MoMoSMS/1.0"

    transactions: List[Dict[str, Any]] = _load_transactions()
    tx_index: Dict[str, Dict[str, Any]] = _build_index(transactions)

    def _send_json(self, status: HTTPStatus, payload: Dict[str, Any] | List[Dict[str, Any]]) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_error(self, status: HTTPStatus, message: str) -> None:
        self._send_json(status, {"error": message})

    def _parse_json_body(self) -> Dict[str, Any] | None:
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            return None
        raw = self.rfile.read(length).decode("utf-8")
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            self._send_error(HTTPStatus.BAD_REQUEST, "Invalid JSON payload.")
            return None

    def _is_authorized(self) -> bool:
        header = self.headers.get("Authorization", "")
        if not header.startswith("Basic "):
            return False
        try:
            encoded = header.split(" ", 1)[1].strip()
            decoded = base64.b64decode(encoded).decode("utf-8")
            username, password = decoded.split(":", 1)
        except Exception:
            return False
        return username == API_USER and password == API_PASS

    def _require_auth(self) -> bool:
        if self._is_authorized():
            return True
        self.send_response(HTTPStatus.UNAUTHORIZED)
        self.send_header("WWW-Authenticate", 'Basic realm="MoMoSMS API"')
        self.end_headers()
        return False

    def _route(self) -> Tuple[str, str | None, Dict[str, List[str]]]:
        parsed = urlparse(self.path)
        parts = parsed.path.strip("/").split("/")
        if len(parts) == 0 or parts[0] != "transactions":
            return "", None, {}
        tx_id = parts[1] if len(parts) > 1 and parts[1] else None
        return parts[0], tx_id, parse_qs(parsed.query)

    def do_GET(self) -> None:
        if not self._require_auth():
            return

        cls = self.__class__
        resource, tx_id, query = self._route()
        if resource != "transactions":
            self._send_error(HTTPStatus.NOT_FOUND, "Resource not found.")
            return

        if tx_id is None:
            limit = None
            if "limit" in query:
                try:
                    limit = int(query["limit"][0])
                except (ValueError, TypeError):
                    self._send_error(HTTPStatus.BAD_REQUEST, "limit must be an integer.")
                    return
            data = cls.transactions if limit is None else cls.transactions[:limit]
            self._send_json(HTTPStatus.OK, data)
            return

        tx = cls.tx_index.get(tx_id)
        if not tx:
            self._send_error(HTTPStatus.NOT_FOUND, "Transaction not found.")
            return
        self._send_json(HTTPStatus.OK, tx)

    def do_POST(self) -> None:
        if not self._require_auth():
            return

        cls = self.__class__
        resource, tx_id, _ = self._route()
        if resource != "transactions" or tx_id is not None:
            self._send_error(HTTPStatus.NOT_FOUND, "Resource not found.")
            return

        payload = self._parse_json_body()
        if payload is None:
            return
        if not isinstance(payload, dict):
            self._send_error(HTTPStatus.BAD_REQUEST, "Payload must be a JSON object.")
            return

        tx_id = str(payload.get("id") or _next_id(cls.transactions))
        if tx_id in cls.tx_index:
            self._send_error(HTTPStatus.CONFLICT, "Transaction ID already exists.")
            return

        payload["id"] = tx_id
        cls.transactions.append(payload)
        cls.tx_index[tx_id] = payload
        self._send_json(HTTPStatus.CREATED, payload)

    def do_PUT(self) -> None:
        if not self._require_auth():
            return

        cls = self.__class__
        resource, tx_id, _ = self._route()
        if resource != "transactions" or tx_id is None:
            self._send_error(HTTPStatus.NOT_FOUND, "Resource not found.")
            return

        payload = self._parse_json_body()
        if payload is None:
            return
        if not isinstance(payload, dict):
            self._send_error(HTTPStatus.BAD_REQUEST, "Payload must be a JSON object.")
            return

        existing = cls.tx_index.get(tx_id)
        if not existing:
            self._send_error(HTTPStatus.NOT_FOUND, "Transaction not found.")
            return

        payload["id"] = tx_id
        existing.clear()
        existing.update(payload)
        self._send_json(HTTPStatus.OK, existing)

    def do_DELETE(self) -> None:
        if not self._require_auth():
            return

        cls = self.__class__
        resource, tx_id, _ = self._route()
        if resource != "transactions" or tx_id is None:
            self._send_error(HTTPStatus.NOT_FOUND, "Resource not found.")
            return

        existing = cls.tx_index.pop(tx_id, None)
        if not existing:
            self._send_error(HTTPStatus.NOT_FOUND, "Transaction not found.")
            return

        for idx, tx in enumerate(list(cls.transactions)):
            if str(tx.get("id")) == tx_id:
                del cls.transactions[idx]
                break
        self._send_json(HTTPStatus.OK, {"deleted": tx_id})


def run(host: str = "127.0.0.1", port: int = 8000) -> None:
    server = ThreadingHTTPServer((host, port), TransactionsAPI)
    print(f"Serving on http://{host}:{port}")
    server.serve_forever()


if __name__ == "__main__":
    run()
