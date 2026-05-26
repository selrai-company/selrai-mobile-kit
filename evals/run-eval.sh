#!/usr/bin/env bash
# selrai-mobile-kit template-picker eval harness
# Reads template-picker-eval.jsonl, classifies each case via local Gemma (or rule fallback),
# scores accuracy, prints passed=N/12. Exit 0 on >= 10/12, exit 1 otherwise.
#
# Usage:
#   cd selrai-mobile-kit && bash evals/run-eval.sh
#
# Dependencies: ollama (optional), jq
# Pass bar: 10/12

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVAL_FILE="$SCRIPT_DIR/template-picker-eval.jsonl"
PASS_BAR=10
TOTAL=12

if [ ! -f "$EVAL_FILE" ]; then
  echo "ERROR: eval file not found at $EVAL_FILE" >&2
  exit 2
fi

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required. Install via: brew install jq  OR  apt install jq" >&2
  exit 2
fi

# Detect Gemma availability and best model
GEMMA_AVAILABLE=false
GEMMA_MODEL=""

if command -v ollama &>/dev/null; then
  MODEL_LIST=$(ollama list 2>/dev/null || true)
  if echo "$MODEL_LIST" | grep -qi "gemma4"; then
    GEMMA_AVAILABLE=true
    GEMMA_MODEL="gemma4"
  elif echo "$MODEL_LIST" | grep -qi "gemma2"; then
    GEMMA_AVAILABLE=true
    GEMMA_MODEL="gemma2:2b"
  elif echo "$MODEL_LIST" | grep -qi "gemma"; then
    GEMMA_AVAILABLE=true
    GEMMA_MODEL=$(echo "$MODEL_LIST" | grep -i gemma | head -1 | awk '{print $1}')
  fi
fi

if [ "$GEMMA_AVAILABLE" = true ]; then
  echo "Using Gemma model: $GEMMA_MODEL"
else
  echo "Gemma not available. Using rule-based fallback for all cases."
fi

# Rule-based classifier
# Returns: pt-companion | service-quote | creator-companion | xero-companion
rule_classify() {
  local business="$1"
  local audience="$2"
  local text
  text=$(echo "$business" | tr '[:upper:]' '[:lower:]')

  # PT keywords (checked first - PT industry intent dominates over backoffice glance)
  if echo "$text" | grep -qiE "trainer|training|fitness|workout|exercise|gym|client check|health coach|coaching|personal train|physiotherapy|physio|pilates|yoga instructor"; then
    # Ambiguous case: fitness + content signals both present - prefer pt-companion
    echo "pt-companion"
    return
  fi

  # Xero / accounting / bookkeeping keywords (before service-quote so a bookkeeper-on-Xero
  # without explicit trade keywords routes to xero-companion, not service-quote)
  if echo "$text" | grep -qiE "xero|bookkeeper|bookkeeping|accountant|accounting|cash flow|cashflow|accounts receivable|aged receivables|profit and loss|balance sheet|chart of accounts"; then
    echo "xero-companion"
    return
  fi

  # Service-quote keywords
  if echo "$text" | grep -qiE "quote|quoting|on-site|onsite|field service|install|installation|repair|plumber|plumbing|electrician|electrical|landscaping|lawn|cleaning|tradesperson|trade|contractor|builder|maintenance|locksmith|pest control|handyman"; then
    echo "service-quote"
    return
  fi

  # Creator-companion keywords
  if echo "$text" | grep -qiE "content|creator|social media|posting|schedule post|influencer|brand|ghl|gohighlevel|marketing|newsletter|podcast|youtube|tiktok|instagram|blog"; then
    echo "creator-companion"
    return
  fi

  # Audience tie-breaker
  if [ "$audience" = "customer" ]; then
    echo "pt-companion"
  else
    echo "service-quote"
  fi
}

# Gemma classifier - returns one of the 4 template names or empty on failure
gemma_classify() {
  local business="$1"
  local audience="$2"
  local phone_today="$3"

  local prompt="You are a mobile app template classifier. Return ONLY one of these four exact strings with no other text: pt-companion OR service-quote OR creator-companion OR xero-companion

Business: $business
Audience: $audience
Phone test today: $phone_today

Rules:
- pt-companion: fitness, personal trainer, workout, coaching clients, health tracking, exercise, gym
- service-quote: trade, quoting, field service, on-site, installation, repair, plumbing, electrical, lawn, cleaning, invoice
- creator-companion: content creation, social media, posting, scheduling, creator, influencer, brand, GHL, marketing
- xero-companion: owner on Xero glancing at cash flow, accounts receivable, BAS, bookkeeping, accounting numbers from a phone

Return ONLY one template name. No explanation. No punctuation."

  local raw
  raw=$(echo "$prompt" | ollama run "$GEMMA_MODEL" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' || true)

  # Validate output is one of the 4 valid templates
  if [[ "$raw" == "pt-companion" || "$raw" == "service-quote" || "$raw" == "creator-companion" || "$raw" == "xero-companion" ]]; then
    echo "$raw"
  else
    echo ""
  fi
}

# Run evals
passed=0
failed=0
i=0

while IFS= read -r line; do
  [ -z "$line" ] && continue
  i=$((i + 1))

  id=$(echo "$line" | jq -r '.id')
  business=$(echo "$line" | jq -r '.business')
  audience=$(echo "$line" | jq -r '.audience')
  phone_today=$(echo "$line" | jq -r '.phone_today')
  expected=$(echo "$line" | jq -r '.expected_template')

  # Classify
  predicted=""
  method="rules"

  if [ "$GEMMA_AVAILABLE" = true ]; then
    predicted=$(gemma_classify "$business" "$audience" "$phone_today")
    if [ -n "$predicted" ]; then
      method="gemma"
    fi
  fi

  # Fall back to rules if Gemma unavailable or returned invalid output
  if [ -z "$predicted" ]; then
    predicted=$(rule_classify "$business" "$audience")
    method="rules"
  fi

  if [ "$predicted" = "$expected" ]; then
    result="PASS"
    passed=$((passed + 1))
  else
    result="FAIL"
    failed=$((failed + 1))
  fi

  printf "%-6s %-20s expected=%-18s got=%-18s method=%s\n" "$id" "$result" "$expected" "$predicted" "$method"

done < "$EVAL_FILE"

echo ""
echo "passed=$passed/$TOTAL"

if [ "$passed" -ge "$PASS_BAR" ]; then
  echo "RESULT: PASS (>= $PASS_BAR required)"
  exit 0
else
  echo "RESULT: FAIL (< $PASS_BAR required)"
  exit 1
fi
