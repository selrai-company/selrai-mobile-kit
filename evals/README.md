# Template Picker Evals

Tests the `mobile-template-pick` skill's classification logic against 12 labelled cases.

Pass bar: **10/12**. Below 10 blocks ship.

## Run (macOS / Linux)

```bash
cd selrai-mobile-kit
bash evals/run-eval.sh
```

## Run (Windows)

```powershell
cd selrai-mobile-kit
.\evals\run-eval.ps1
```

## What it tests

12 cases in `template-picker-eval.jsonl`:

| Cases | Template |
|---|---|
| ev-01, ev-02, ev-03 | pt-companion (personal trainer / fitness coach) |
| ev-04, ev-05, ev-06 | service-quote (trade, field service) |
| ev-07, ev-08, ev-09 | creator-companion (social media, GHL) |
| ev-10 | Ambiguous: fitness coaching + online programs. Expected: pt-companion |
| ev-11, ev-12 | xero-companion (owner on Xero, bookkeeper) |

## How it classifies

1. If `ollama` is installed and a Gemma model is available, it sends each case to Gemma and validates the response.
2. If Gemma is unavailable or returns an unexpected value, it falls back to keyword rules.

The harness reports which method was used per case.

## Output shape

```
ev-01  PASS                 expected=pt-companion      got=pt-companion      method=gemma
ev-10  PASS                 expected=pt-companion      got=pt-companion      method=rules
ev-12  PASS                 expected=xero-companion    got=xero-companion    method=rules
...
passed=12/12
RESULT: PASS (>= 10 required)
```

Exit code 0 = pass. Exit code 1 = fail. Exit code 2 = missing dependency.

## Updating the eval set

If a new template is added, or keyword rules change, update `template-picker-eval.jsonl` first.
Add new cases from the bottom. Do not remove existing cases without a written reason in the commit message.

Phase 0.3 target: expand to 20 cases covering edge inputs (non-English business names, very short descriptions, punctuation-heavy inputs).
