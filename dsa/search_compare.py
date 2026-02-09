"""Compare linear search vs dictionary lookup for transactions."""

from __future__ import annotations

import argparse
import random
import time
from pathlib import Path
from typing import Any, Dict, List, Tuple

try:
    from dsa.parse_xml import load_transactions_json, parse_sms_xml
except ImportError:  # Allows running as a script: python dsa/search_compare.py
    from parse_xml import load_transactions_json, parse_sms_xml


def linear_search(transactions: List[Dict[str, Any]], target_id: str) -> Dict[str, Any] | None:
    for tx in transactions:
        if str(tx.get("id")) == target_id:
            return tx
    return None


def dict_lookup(tx_index: Dict[str, Dict[str, Any]], target_id: str) -> Dict[str, Any] | None:
    return tx_index.get(target_id)


def _build_index(transactions: List[Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
    return {str(tx.get("id")): tx for tx in transactions}


def _measure(fn, *args, repeats: int = 10_000) -> Tuple[float, Any]:
    start = time.perf_counter()
    result = None
    for _ in range(repeats):
        result = fn(*args)
    duration = time.perf_counter() - start
    return duration, result


def _load_transactions(xml_path: Path, json_path: Path) -> List[Dict[str, Any]]:
    if json_path.exists():
        return load_transactions_json(json_path)
    if xml_path.exists():
        return parse_sms_xml(xml_path)
    raise FileNotFoundError(
        "No transaction data found. Provide XML at data/raw/modified_sms_v2.xml "
        "or JSON at data/processed/transactions.json."
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare linear search and dictionary lookup.")
    parser.add_argument(
        "--xml",
        dest="xml_path",
        default=Path("data/raw/modified_sms_v2.xml"),
        help="Path to the XML file.",
    )
    parser.add_argument(
        "--json",
        dest="json_path",
        default=Path("data/processed/transactions.json"),
        help="Path to the JSON file.",
    )
    parser.add_argument(
        "--repeats",
        dest="repeats",
        type=int,
        default=10_000,
        help="Number of repeated lookups for timing.",
    )

    args = parser.parse_args()
    transactions = _load_transactions(Path(args.xml_path), Path(args.json_path))

    if len(transactions) < 20:
        print(f"Warning: only {len(transactions)} records available; requirement is 20.")

    sample = transactions[:20]
    if not sample:
        print("No transactions available to test.")
        return 1

    target = random.choice(sample)
    target_id = str(target.get("id"))

    index = _build_index(sample)

    linear_time, _ = _measure(linear_search, sample, target_id, repeats=args.repeats)
    dict_time, _ = _measure(dict_lookup, index, target_id, repeats=args.repeats)

    print("DSA Comparison ({} repeats)".format(args.repeats))
    print(f"Linear search: {linear_time:.6f}s")
    print(f"Dictionary lookup: {dict_time:.6f}s")
    if dict_time > 0:
        print(f"Speedup: {linear_time / dict_time:.2f}x")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
