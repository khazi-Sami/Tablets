# Drug Reference Builder

This folder contains the developer-only build-time pipeline for the Tablets offline drug reference.

The iOS app never downloads medicine data. Run this tool manually on your Mac, review the output, then bundle the generated file in:

`Tablets/Resources/DrugReference/drug_reference_starter.json`

The generated data is reference-only. It is not medical advice, not prescribing guidance, not dosage advice, and not a replacement for a doctor or pharmacist.

## Sources

Supported inputs:

- FDA/openFDA NDC public drug listing JSON, downloaded only by this Mac-side script when configured.
- RxNorm RRF release files from a local folder, if you already downloaded them.
- Manual India/common brand override CSV, reviewed by the developer.

The app must not include huge raw FDA, DailyMed, RxNorm, or scraped website archives. The app bundles only the cleaned small JSON.

## Commands

```bash
cd Tools/DrugReferenceBuilder
python3 build_drug_reference.py --mode starter
python3 build_drug_reference.py --mode full
python3 build_drug_reference.py --mode starter --input-rxnorm ./rxnorm/
python3 build_drug_reference.py --mode starter --include-india-overrides ./india_overrides_sample.csv
```

Default output:

`../../Tablets/Resources/DrugReference/drug_reference_starter.json`

## Safety Rules

Generated entries must use cautious wording:

- Use only as prescribed by your doctor.
- Ask your doctor or pharmacist if you have questions.
- This is reference information only.

Never generate wording such as:

- safe for you
- recommended dose
- you should take
- cures
- guaranteed

If a source does not safely provide a common use, leave `commonUses` empty. Do not invent treatment claims.

