# selrai-mobile-kit template-picker eval harness (PowerShell mirror of run-eval.sh)
# Reads template-picker-eval.jsonl, classifies each case via local Gemma (or rule fallback),
# scores accuracy, prints passed=N/10. Exit 0 on >= 8/10, exit 1 otherwise.
#
# Usage:
#   cd selrai-mobile-kit; .\evals\run-eval.ps1
#
# Dependencies: ollama (optional), jq (optional, falls back to PowerShell JSON parsing)
# Pass bar: 8/10

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EvalFile = Join-Path $ScriptDir "template-picker-eval.jsonl"
$PassBar = 8
$Total = 10

if (-not (Test-Path $EvalFile)) {
    Write-Error "ERROR: eval file not found at $EvalFile"
    exit 2
}

# Detect Gemma availability and best model
$GemmaAvailable = $false
$GemmaModel = ""

$OllamaExists = $null
try { $OllamaExists = (Get-Command ollama -ErrorAction Stop).Source } catch {}

if ($OllamaExists) {
    $ModelList = ollama list 2>$null
    if ($ModelList -match "gemma4") {
        $GemmaAvailable = $true
        $GemmaModel = "gemma4"
    } elseif ($ModelList -match "gemma2") {
        $GemmaAvailable = $true
        $GemmaModel = "gemma2:2b"
    } elseif ($ModelList -match "gemma") {
        $GemmaAvailable = $true
        $GemmaModel = ($ModelList -split "`n" | Where-Object { $_ -match "gemma" } | Select-Object -First 1).Split(" ")[0].Trim()
    }
}

if ($GemmaAvailable) {
    Write-Output "Using Gemma model: $GemmaModel"
} else {
    Write-Output "Gemma not available. Using rule-based fallback for all cases."
}

# Rule-based classifier
function Invoke-RuleClassify {
    param([string]$Business, [string]$Audience)

    $text = $Business.ToLower()

    # PT keywords - checked first (ambiguous fitness+content resolves to pt-companion)
    if ($text -match "trainer|training|fitness|workout|exercise|gym|client check|health coach|coaching|personal train|physiotherapy|physio|pilates|yoga instructor") {
        return "pt-companion"
    }

    # Service-quote keywords
    if ($text -match "quote|quoting|on-site|onsite|field service|install|installation|repair|plumber|plumbing|electrician|electrical|landscaping|lawn|cleaning|tradesperson|trade|contractor|builder|maintenance|locksmith|pest control|handyman") {
        return "service-quote"
    }

    # Creator-companion keywords
    if ($text -match "content|creator|social media|posting|schedule post|influencer|brand|ghl|gohighlevel|marketing|newsletter|podcast|youtube|tiktok|instagram|blog") {
        return "creator-companion"
    }

    # Audience tie-breaker
    if ($Audience -eq "customer") { return "pt-companion" }
    return "service-quote"
}

# Gemma classifier
function Invoke-GemmaClassify {
    param([string]$Business, [string]$Audience, [string]$PhoneToday)

    $Prompt = @"
You are a mobile app template classifier. Return ONLY one of these three exact strings with no other text: pt-companion OR service-quote OR creator-companion

Business: $Business
Audience: $Audience
Phone test today: $PhoneToday

Rules:
- pt-companion: fitness, personal trainer, workout, coaching clients, health tracking, exercise, gym
- service-quote: trade, quoting, field service, on-site, installation, repair, plumbing, electrical, lawn, cleaning, invoice
- creator-companion: content creation, social media, posting, scheduling, creator, influencer, brand, GHL, marketing

Return ONLY one template name. No explanation. No punctuation.
"@

    try {
        $Raw = ($Prompt | ollama run $GemmaModel 2>$null).Trim().ToLower() -replace '\s', ''
        $Valid = @("pt-companion", "service-quote", "creator-companion")
        if ($Valid -contains $Raw) { return $Raw }
    } catch {}

    return ""
}

# Run evals
$Passed = 0
$Failed = 0

Get-Content $EvalFile | ForEach-Object {
    $Line = $_.Trim()
    if ([string]::IsNullOrEmpty($Line)) { return }

    $Case = $Line | ConvertFrom-Json

    $Id = $Case.id
    $Business = $Case.business
    $Audience = $Case.audience
    $PhoneToday = $Case.phone_today.ToString().ToLower()
    $Expected = $Case.expected_template

    # Classify
    $Predicted = ""
    $Method = "rules"

    if ($GemmaAvailable) {
        $Predicted = Invoke-GemmaClassify -Business $Business -Audience $Audience -PhoneToday $PhoneToday
        if ($Predicted -ne "") { $Method = "gemma" }
    }

    if ($Predicted -eq "") {
        $Predicted = Invoke-RuleClassify -Business $Business -Audience $Audience
        $Method = "rules"
    }

    if ($Predicted -eq $Expected) {
        $Result = "PASS"
        $Passed++
    } else {
        $Result = "FAIL"
        $Failed++
    }

    Write-Output ("{0,-6} {1,-20} expected={2,-18} got={3,-18} method={4}" -f $Id, $Result, $Expected, $Predicted, $Method)
}

Write-Output ""
Write-Output "passed=$Passed/$Total"

if ($Passed -ge $PassBar) {
    Write-Output "RESULT: PASS (>= $PassBar required)"
    exit 0
} else {
    Write-Output "RESULT: FAIL (< $PassBar required)"
    exit 1
}
