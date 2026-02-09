from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, Iterable, List
import xml.etree.ElementTree as ET


def _to_str_id(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, (int, float)):
        return str(int(value))
    return str(value).strip()


def _element_to_record(elem: ET.Element) -> Dict[str, Any]:
    record: Dict[str, Any] = {}
    record.update(elem.attrib)
    for child in elem:
        if child.text and child.text.strip():
            record[child.tag] = child.text.strip()
    return record


def _normalize_record(record: Dict[str, Any], idx: int) -> Dict[str, Any]:
    raw_id = (
        record.get("id")
        or record.get("_id")
        or record.get("msg_id")
        or record.get("transaction_id")
    )
    record["id"] = _to_str_id(raw_id or (idx + 1))

    if "timestamp" not in record and "date" in record:
        record["timestamp"] = record["date"]

    return record


def parse_sms_xml(xml_path: Path | str) -> List[Dict[str, Any]]:
    xml_path = Path(xml_path)
    tree = ET.parse(xml_path)
    root = tree.getroot()

    transactions: List[Dict[str, Any]] = []
    sms_elements = list(root.findall(".//sms"))
    if not sms_elements and root.tag == "sms":
        sms_elements = [root]

    for idx, sms in enumerate(sms_elements):
        record = _element_to_record(sms)
        transactions.append(_normalize_record(record, idx))

    return transactions


def save_transactions_json(transactions: Iterable[Dict[str, Any]], out_path: Path | str) -> None:
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as handle:
        json.dump(list(transactions), handle, indent=2, ensure_ascii=False)


def load_transactions_json(json_path: Path | str) -> List[Dict[str, Any]]:
    json_path = Path(json_path)
    with json_path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def main() -> int:
    parser = argparse.ArgumentParser(description="Parse MoMo SMS XML into JSON.")
    parser.add_argument(
        "--xml",
        dest="xml_path",
        default=Path("data/raw/modified_sms_v2.xml"),
        help="Path to the XML file.",
    )
    parser.add_argument(
        "--out",
        dest="out_path",
        default=Path("data/processed/transactions.json"),
        help="Where to write JSON output.",
    )

    args = parser.parse_args()
    transactions = parse_sms_xml(Path(args.xml_path))
    save_transactions_json(transactions, Path(args.out_path))
    print(f"Parsed {len(transactions)} transactions -> {args.out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
