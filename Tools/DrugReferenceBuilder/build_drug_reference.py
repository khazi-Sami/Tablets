#!/usr/bin/env python3
import argparse
import csv
import json
import re
import sys
import urllib.request
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
DEFAULT_CONFIG = ROOT / "sources_config.json"
DEFAULT_OUTPUT = ROOT.parents[1] / "Tablets" / "Resources" / "DrugReference" / "drug_reference_starter.json"
SAFETY_NOTES = [
    "Use only as prescribed by your doctor.",
    "Ask your doctor or pharmacist if you have questions.",
    "This is reference information only.",
]
BANNED_WORDING = [
    "safe for you",
    "recommended dose",
    "you should take",
    "cures",
    "guaranteed",
    "no need to worry",
    "everything is okay",
]
SALT_MAP = {
    "hydrochloride": "hcl",
    "hcl": "hcl",
    "sodium": "sodium",
    "potassium": "potassium",
    "besylate": "besylate",
    "besilate": "besylate",
}
COMMON_STARTER = [
    ("Paracetamol", "Paracetamol", ["Acetaminophen"], ["Acetaminophen", "PCM"], ["tablet", "syrup"], ["May be prescribed for pain or fever management."]),
    ("Metformin", "Metformin Hydrochloride", ["Glucophage"], ["Metformin HCl"], ["tablet", "extended-release tablet"], ["May be prescribed for type 2 diabetes management."]),
    ("Amlodipine", "Amlodipine Besylate", ["Norvasc"], [], ["tablet"], ["May be prescribed for blood pressure management."]),
    ("Telmisartan", "Telmisartan", ["Micardis"], [], ["tablet"], ["May be prescribed for blood pressure management."]),
    ("Aspirin", "Aspirin", ["Ecosprin"], ["Acetylsalicylic Acid"], ["tablet"], ["May be prescribed for heart or pain-related care depending on your doctor's advice."]),
    ("Atorvastatin", "Atorvastatin Calcium", ["Lipitor"], [], ["tablet"], ["May be prescribed for cholesterol management."]),
    ("Pantoprazole", "Pantoprazole Sodium", ["Protonix"], [], ["tablet"], ["May be prescribed for stomach acid-related care."]),
    ("Azithromycin", "Azithromycin", ["Azithral", "Zithromax"], [], ["tablet", "suspension"], ["May be prescribed as an antibiotic when a doctor decides it is needed."]),
    ("Levothyroxine", "Levothyroxine Sodium", ["Synthroid"], [], ["tablet"], ["May be prescribed for thyroid hormone replacement."]),
    ("Losartan", "Losartan Potassium", ["Cozaar"], [], ["tablet"], ["May be prescribed for blood pressure management."]),
]


@dataclass
class SourceFile:
    name: str
    url: str = ""
    downloadedAt: str = ""


@dataclass
class MedicineRecord:
    displayName: str
    genericName: str
    brandNames: set[str] = field(default_factory=set)
    synonyms: set[str] = field(default_factory=set)
    dosageForms: set[str] = field(default_factory=set)
    commonUses: set[str] = field(default_factory=set)
    safetyNotes: set[str] = field(default_factory=set)
    source: set[str] = field(default_factory=set)

    def merge(self, other: "MedicineRecord") -> None:
        if not self.displayName:
            self.displayName = other.displayName
        if len(other.genericName) > len(self.genericName):
            self.genericName = other.genericName
        self.brandNames.update(clean_list(other.brandNames))
        self.synonyms.update(clean_list(other.synonyms))
        self.dosageForms.update(clean_list(other.dosageForms))
        self.commonUses.update(clean_list(other.commonUses))
        self.safetyNotes.update(clean_list(other.safetyNotes))
        self.source.update(clean_list(other.source))


def clean_spaces(value: str) -> str:
    return re.sub(r"\s+", " ", value or "").strip()


def clean_list(values: Any) -> list[str]:
    output: list[str] = []
    if values is None:
        return output
    if isinstance(values, str):
        values = re.split(r"[;|]", values)
    for value in values:
        text = clean_spaces(str(value))
        if text and text.lower() not in {item.lower() for item in output}:
            output.append(text)
    return output


def remove_strengths(value: str) -> str:
    text = re.sub(r"\b\d+(\.\d+)?\s*(mg|mcg|g|ml|iu|%)\b", " ", value, flags=re.IGNORECASE)
    text = re.sub(r"\b\d+(\.\d+)?\s*/\s*\d+(\.\d+)?\s*(mg|mcg|g|ml)\b", " ", text, flags=re.IGNORECASE)
    return clean_spaces(text)


def normalize_key(value: str) -> str:
    text = remove_strengths(value).lower()
    text = text.replace("&", " and ")
    text = re.sub(r"[/,+()\\[\\]{}]", " ", text)
    text = re.sub(r"[^a-z0-9 ]+", " ", text)
    tokens = []
    for token in clean_spaces(text).split(" "):
        tokens.append(SALT_MAP.get(token, token))
    return clean_spaces(" ".join(tokens))


def make_id(name: str, index: int) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", normalize_key(name)).strip("_")
    return f"{slug or 'medicine'}_{index:03d}"


def add_record(records: dict[str, MedicineRecord], record: MedicineRecord) -> None:
    generic = clean_spaces(record.genericName or record.displayName)
    display = clean_spaces(record.displayName or generic)
    if not generic or not display:
        return
    key = normalize_key(generic)
    if not key:
        return
    record.genericName = generic
    record.displayName = display
    record.brandNames = set(clean_list(record.brandNames))
    record.synonyms = set(clean_list(record.synonyms))
    record.dosageForms = set(clean_list(record.dosageForms))
    record.commonUses = set(clean_list(record.commonUses))
    record.source = set(clean_list(record.source))
    if key in records:
        records[key].merge(record)
    else:
        records[key] = record


def download_openfda(config: dict[str, Any]) -> tuple[list[dict[str, Any]], SourceFile | None]:
    source = config.get("openFDA_NDC", {})
    if not source.get("enabled") or not source.get("url"):
        return [], None
    url = source["url"]
    try:
        print(f"Downloading {url}")
        with urllib.request.urlopen(url, timeout=40) as response:
            data = json.loads(response.read().decode("utf-8"))
        return data.get("results", []), SourceFile(name=source.get("name", "openFDA NDC"), url=url, downloadedAt=str(date.today()))
    except Exception as error:
        print(f"Warning: openFDA download failed: {error}", file=sys.stderr)
        return [], None


def ingest_openfda(records: dict[str, MedicineRecord], rows: list[dict[str, Any]]) -> None:
    for row in rows:
        generic = clean_spaces(row.get("generic_name") or "")
        brand = clean_spaces(row.get("brand_name") or "")
        dosage_form = clean_spaces(row.get("dosage_form") or "")
        if not generic and not brand:
            continue
        display = remove_strengths(generic or brand)
        record = MedicineRecord(
            displayName=display,
            genericName=remove_strengths(generic or brand),
            brandNames=set(clean_list([brand] if brand else [])),
            dosageForms=set(clean_list([dosage_form] if dosage_form else [])),
            safetyNotes=set(SAFETY_NOTES),
            source={"openFDA NDC"},
        )
        add_record(records, record)


def ingest_rxnorm(records: dict[str, MedicineRecord], folder: Path) -> SourceFile | None:
    conso = folder / "RXNCONSO.RRF"
    if not conso.exists():
        print(f"Warning: RxNorm file not found: {conso}", file=sys.stderr)
        return None
    useful_ttys = {"IN", "PIN", "BN", "SCD", "SBD", "SY"}
    seen = 0
    with conso.open("r", encoding="utf-8", errors="ignore") as handle:
        for line in handle:
            parts = line.rstrip("\n").split("|")
            if len(parts) < 15:
                continue
            sab = parts[11]
            tty = parts[12]
            name = remove_strengths(parts[14])
            if sab != "RXNORM" or tty not in useful_ttys or not name:
                continue
            if tty == "BN":
                record = MedicineRecord(displayName=name, genericName=name, brandNames={name}, safetyNotes=set(SAFETY_NOTES), source={"RxNorm"})
            elif tty == "SY":
                record = MedicineRecord(displayName=name, genericName=name, synonyms={name}, safetyNotes=set(SAFETY_NOTES), source={"RxNorm"})
            else:
                record = MedicineRecord(displayName=name, genericName=name, safetyNotes=set(SAFETY_NOTES), source={"RxNorm"})
            add_record(records, record)
            seen += 1
            if seen > 100000:
                break
    return SourceFile(name="RxNorm release files", url=str(folder), downloadedAt=str(date.today()))


def ingest_india_overrides(records: dict[str, MedicineRecord], csv_path: Path) -> SourceFile | None:
    if not csv_path.exists():
        print(f"Warning: India override CSV not found: {csv_path}", file=sys.stderr)
        return None
    with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            record = MedicineRecord(
                displayName=clean_spaces(row.get("displayName", "")),
                genericName=clean_spaces(row.get("genericName", "")),
                brandNames=set(clean_list(row.get("brandNames", ""))),
                synonyms=set(clean_list(row.get("synonyms", ""))),
                dosageForms=set(clean_list(row.get("dosageForms", ""))),
                commonUses=set(clean_list(row.get("commonUses", ""))),
                safetyNotes=set(clean_list(row.get("safetyNotes", "")) or SAFETY_NOTES),
                source={clean_spaces(row.get("source", "")) or "Manual India override"},
            )
            add_record(records, record)
    return SourceFile(name="India/common brand overrides", url=str(csv_path), downloadedAt=str(date.today()))


def ingest_common_starter(records: dict[str, MedicineRecord]) -> SourceFile:
    for display, generic, brands, synonyms, forms, uses in COMMON_STARTER:
        add_record(
            records,
            MedicineRecord(
                displayName=display,
                genericName=generic,
                brandNames=set(brands),
                synonyms=set(synonyms),
                dosageForms=set(forms),
                commonUses=set(uses),
                safetyNotes=set(SAFETY_NOTES),
                source={"Curated starter seed"},
            ),
        )
    return SourceFile(name="Curated starter seed", downloadedAt=str(date.today()))


def score_for_starter(record: MedicineRecord) -> tuple[int, str]:
    has_brand = 1 if record.brandNames else 0
    has_form = 1 if record.dosageForms else 0
    short_name = 1 if len(record.displayName) <= 34 else 0
    return (has_brand + has_form + short_name, record.displayName.lower())


def to_json_records(records: dict[str, MedicineRecord], mode: str) -> list[dict[str, Any]]:
    values = list(records.values())
    values.sort(key=score_for_starter, reverse=True)
    if mode == "starter":
        values = values[:500]
    else:
        values.sort(key=lambda item: item.displayName.lower())

    output = []
    for index, record in enumerate(values, start=1):
        generic = clean_spaces(record.genericName)
        display = clean_spaces(record.displayName or generic)
        if not generic or not display:
            continue
        safety = clean_list(record.safetyNotes) or SAFETY_NOTES
        for note in SAFETY_NOTES:
            if note.lower() not in {item.lower() for item in safety}:
                safety.append(note)
        output.append(
            {
                "id": make_id(generic, index),
                "displayName": display,
                "genericName": generic,
                "brandNames": sorted(clean_list(record.brandNames), key=str.lower),
                "synonyms": sorted(clean_list(record.synonyms), key=str.lower),
                "dosageForms": sorted(clean_list(record.dosageForms), key=str.lower),
                "commonUses": sorted(clean_list(record.commonUses), key=str.lower),
                "safetyNotes": safety,
                "source": " / ".join(sorted(clean_list(record.source), key=str.lower)),
                "lastUpdated": str(date.today()),
            }
        )
    return output


def validate_payload(payload: dict[str, Any]) -> None:
    ids = set()
    medicines = payload.get("medicines")
    if not isinstance(medicines, list):
        raise ValueError("medicines must be an array")
    for index, medicine in enumerate(medicines):
        if not medicine.get("id") or not medicine.get("displayName"):
            raise ValueError(f"medicine at index {index} is missing id/displayName")
        if medicine["id"] in ids:
            raise ValueError(f"duplicate id: {medicine['id']}")
        ids.add(medicine["id"])
        for key in ["brandNames", "synonyms", "dosageForms", "commonUses", "safetyNotes"]:
            if not isinstance(medicine.get(key), list):
                raise ValueError(f"{medicine['id']} field {key} must be an array")
        combined = json.dumps(medicine, ensure_ascii=False).lower()
        for banned in BANNED_WORDING:
            if banned in combined:
                raise ValueError(f"{medicine['id']} contains banned wording: {banned}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Build Tablets offline drug reference JSON.")
    parser.add_argument("--mode", choices=["starter", "full"], default="starter")
    parser.add_argument("--config", default=str(DEFAULT_CONFIG))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--input-rxnorm")
    parser.add_argument("--include-india-overrides")
    args = parser.parse_args()

    with Path(args.config).open("r", encoding="utf-8") as handle:
        config = json.load(handle)

    records: dict[str, MedicineRecord] = {}
    source_files: list[SourceFile] = [ingest_common_starter(records)]

    openfda_rows, openfda_source = download_openfda(config)
    if openfda_source:
        ingest_openfda(records, openfda_rows)
        source_files.append(openfda_source)

    if args.input_rxnorm:
        rx_source = ingest_rxnorm(records, Path(args.input_rxnorm))
        if rx_source:
            source_files.append(rx_source)

    if args.include_india_overrides:
        override_source = ingest_india_overrides(records, Path(args.include_india_overrides))
        if override_source:
            source_files.append(override_source)

    medicines = to_json_records(records, args.mode)
    payload = {
        "version": "1.0",
        "lastUpdated": str(date.today()),
        "sourceNote": "Generated from public drug naming/listing datasets. Reference only, not medical advice.",
        "sourceFiles": [source.__dict__ for source in source_files],
        "medicines": medicines,
    }
    validate_payload(payload)

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=False).encode("utf-8")
    output_path.write_bytes(encoded)

    size_mb = len(encoded) / (1024 * 1024)
    print(f"Validation passed")
    print(f"Entry count: {len(medicines)}")
    print(f"Output: {output_path}")
    print(f"Output size: {len(encoded)} bytes ({size_mb:.2f} MB)")
    if args.mode == "full" and size_mb > 10:
        print("Warning: full output is larger than 10 MB. Review before bundling in the app.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
