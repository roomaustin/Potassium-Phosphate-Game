#requires -Version 7.0
<#
PotassiumPhosphateGame.ps1
Author: 0DLCLLC

A self-contained terminal game (PowerShell) for reasoning + computation around:
"potassium phosphate" -> K3PO4 -> components.

Runs on macOS/Linux/Windows with PowerShell 7+ (pwsh).

How to run (macOS/Linux):
  pwsh -NoProfile -ExecutionPolicy Bypass -File ./PotassiumPhosphateGame.ps1

If your terminal isn't interactive, the script runs a short demo and exits.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Interactive {
    # True when stdin and stdout are terminals (best-effort)
    try {
        return ([Console]::IsInputRedirected -eq $false) -and ([Console]::IsOutputRedirected -eq $false)
    } catch {
        return $true
    }
}

function Pause-Game([string]$Message = "Press Enter to continue...") {
    if (Test-Interactive) {
        try { [void](Read-Host $Message) } catch {}
    }
}

function Clear-Safe {
    if (Test-Interactive) {
        try { Clear-Host } catch {}
    }
}

function Show-Banner {
    Clear-Safe
    @"
============================================================
 Potassium Phosphate — Reasoning + Computation Mini-Game
 Author: 0DLCLLC
============================================================

Ethics: type 'r' anytime to reveal the solution.
"@ | Write-Host
}

function Show-Score {
    param(
        [int]$Score,
        [int]$Unsafe
    )
    "" | Write-Host
    ("Score: {0}  |  Unsafe positives: {1}" -f $Score, $Unsafe) | Write-Host
    "" | Write-Host
}

function Show-Reveal {
    param(
        [string]$PlainText,
        [string]$Formula,
        [int]$KCount,
        [int]$GroupCount,
        [int]$AtomK,
        [int]$AtomP,
        [int]$AtomO,
        [int]$NetCharge
    )

    "" | Write-Host
    "=== REVEAL (ethical disclosure) ===" | Write-Host
    ("{0} → {1}" -f $PlainText, $Formula) | Write-Host
    ("Component-groups: {0}×K + {1}×(PO4)" -f $KCount, $GroupCount) | Write-Host
    ("Atomic totals   : K={0}, P={1}, O={2}" -f $AtomK, $AtomP, $AtomO) | Write-Host
    ("Net charge      : {0}" -f $NetCharge) | Write-Host
    "==================================" | Write-Host
    "" | Write-Host
}

function Read-Choice {
    param([string]$Prompt = "> ")

    if (-not (Test-Interactive)) {
        return $null
    }

    try {
        $ans = Read-Host $Prompt
        if ($null -eq $ans) { return "" }
        return $ans.Trim()
    } catch {
        return ""
    }
}

function Apply-Hint {
    param(
        [string[]]$Hints,
        [ref]$HintIndex,
        [ref]$Score
    )

    "" | Write-Host
    if ($HintIndex.Value -lt $Hints.Length) {
        $i = $HintIndex.Value
        ("HINT {0}/{1}: {2}" -f ($i+1), $Hints.Length, $Hints[$i]) | Write-Host
        $HintIndex.Value++
        $Score.Value -= 1
    } else {
        "No more hints. Use 'r' to reveal the full answer." | Write-Host
    }
    Pause-Game
}

function Step-Loop {
    param(
        [int]$StepNumber,
        [string]$PlainText,
        [string]$Formula,
        [ref]$Score,
        [ref]$Unsafe,
        [string[]]$Hints
    )

    $hintIndex = 0

    while ($true) {
        Show-Banner
        Show-Score -Score $Score.Value -Unsafe $Unsafe.Value

        switch ($StepNumber) {
            1 {
@"
STEP 1/3 — Normalize
Phrase: "$PlainText"

1) Use a chemical formula token: $Formula
2) Use a Caesar cipher shift token: SHIFT+3
3) Use a GPS coordinate format

(Enter 1/2/3, h=hint, r=reveal, q=quit)
"@ | Write-Host
            }
            2 {
@"
STEP 2/3 — Decompose
You chose: $Formula

1) 3×K and 1×(PO4)
2) 1×K and 3×(PO4)
3) 3×P and 4×O and 1×K

(Enter 1/2/3, h=hint, r=reveal, q=quit)
"@ | Write-Host
            }
            3 {
@"
STEP 3/3 — State the solution

1) potassium phosphate → K3PO4 → components: 3×K + 1×(PO4)
2) potassium phosphate → srwdvvlxp skrvskdwh (Caesar +3)

(Enter 1/2, h=hint, r=reveal, q=quit)
"@ | Write-Host
            }
        }

        $ans = Read-Choice
        if ($null -eq $ans) {
            return $false
        }

        switch -Regex ($ans) {
            '^(q|Q)$' { Write-Host "`nGoodbye."; return $false }
            '^(r|R)$' {
                Show-Reveal -PlainText $PlainText -Formula $Formula -KCount 3 -GroupCount 1 -AtomK 3 -AtomP 1 -AtomO 4 -NetCharge 0
                Pause-Game
                continue
            }
            '^(h|H)$' {
                Apply-Hint -Hints $Hints -HintIndex ([ref]$hintIndex) -Score $Score
                continue
            }
        }

        # Evaluate correctness
        $correct = $false
        if ($StepNumber -eq 1 -and $ans -eq "1") { $correct = $true }
        if ($StepNumber -eq 2 -and $ans -eq "1") { $correct = $true }
        if ($StepNumber -eq 3 -and $ans -eq "1") { $correct = $true }

        if ($correct) {
            $Score.Value += 10
            return $true
        } else {
            $Score.Value -= 2
            $Unsafe.Value += 1
            "" | Write-Host
            "Unsafe positive / residual: selection mismatch. Safe correction path is available via 'r'." | Write-Host
            Pause-Game
        }
    }
}

function Compute-Check {
    param(
        [string]$PlainText,
        [string]$Formula,
        [ref]$Score,
        [ref]$Unsafe
    )

    Show-Banner
    Show-Score -Score $Score.Value -Unsafe $Unsafe.Value

@"
COMPUTATION CHECK (deterministic)

Normalized: "$PlainText" -> $Formula
Expected totals: K=3, P=1, O=4
Expected net charge: 0

Type 'r' to reveal at any time.
"@ | Write-Host

    $ans = Read-Choice "Enter formula token (or 'r'): "
    if ($null -eq $ans) { return }
    if ($ans -match '^(r|R)$') {
        Show-Reveal -PlainText $PlainText -Formula $Formula -KCount 3 -GroupCount 1 -AtomK 3 -AtomP 1 -AtomO 4 -NetCharge 0
        Pause-Game
        return
    }

    # Normalize to letters+digits only, uppercase
    $norm = ($ans -replace '[^A-Za-z0-9]', '').ToUpperInvariant()
    if ($norm -ne $Formula) {
        $Score.Value -= 2
        $Unsafe.Value += 1
        "" | Write-Host
        "INVALID: formula token mismatch." | Write-Host
        Show-Reveal -PlainText $PlainText -Formula $Formula -KCount 3 -GroupCount 1 -AtomK 3 -AtomP 1 -AtomO 4 -NetCharge 0
        Pause-Game
        return
    }

    $Score.Value += 10
    "" | Write-Host
    "VALID: formula token matches." | Write-Host
    "" | Write-Host

    $totals = Read-Choice "Enter totals as K,P,O (example 3,1,4) or 'r': "
    if ($null -eq $totals) { return }
    if ($totals -match '^(r|R)$') {
        Show-Reveal -PlainText $PlainText -Formula $Formula -KCount 3 -GroupCount 1 -AtomK 3 -AtomP 1 -AtomO 4 -NetCharge 0
        Pause-Game
        return
    }

    $t = $totals.Trim()
    if ($t -eq "3,1,4") {
        $Score.Value += 10
        "" | Write-Host
        "VALID: totals match." | Write-Host
    } else {
        $Score.Value -= 2
        $Unsafe.Value += 1
        "" | Write-Host
        "INVALID: totals do not match expected (3,1,4)." | Write-Host
    }

    Pause-Game
}

function Demo-Mode {
    param([string]$PlainText, [string]$Formula)

    Show-Banner
    "" | Write-Host
    "(Demo mode: no interactive terminal detected.)" | Write-Host
    "" | Write-Host
    "Auto-solving steps: 1, 1, 1" | Write-Host
    Show-Reveal -PlainText $PlainText -Formula $Formula -KCount 3 -GroupCount 1 -AtomK 3 -AtomP 1 -AtomO 4 -NetCharge 0
    "Demo complete." | Write-Host
}

# ----------------- Main -----------------
$plainText = "potassium phosphate"
$formula   = "K3PO4"

$hints1 = $H1 = @(
    "This game is about reasoning a chemical name into a formula.",
    "Potassium’s symbol is K; phosphate is PO4; combine them.",
    "For this game, treat “potassium phosphate” as: K3PO4."
)

$hints2 = $H2 = @(
    "Read subscripts: K3 means three potassium.",
    "PO4 is a grouped unit (phosphate). Treat it as one group here.",
    "Correct decomposition: 3×K + 1×(PO4)."
)

$hints3 = $H3 = @(
    "State the mapping (name → formula → parts) in one line.",
    "Include both the formula and the component counts.",
    "Exact: potassium phosphate → K3PO4 → 3K + PO4."
)

$score = 0
$unsafe = 0

if (-not (Test-Interactive)) {
    Demo-Mode -PlainText $plainText -Formula $formula
    exit 0
}

$ok = Step-Loop -StepNumber 1 -PlainText $plainText -Formula $formula -Score ([ref]$score) -Unsafe ([ref]$unsafe) -Hints $hints1
if (-not $ok) { exit 0 }

$ok = Step-Loop -StepNumber 2 -PlainText $plainText -Formula $formula -Score ([ref]$score) -Unsafe ([ref]$unsafe) -Hints $hints2
if (-not $ok) { exit 0 }

$ok = Step-Loop -StepNumber 3 -PlainText $plainText -Formula $formula -Score ([ref]$score) -Unsafe ([ref]$unsafe) -Hints $hints3
if (-not $ok) { exit 0 }

Show-Banner
Show-Score -Score $score -Unsafe $unsafe
"✅ Solved (Reasoning)." | Write-Host
Show-Reveal -PlainText $plainText -Formula $formula -KCount 3 -GroupCount 1 -AtomK 3 -AtomP 1 -AtomO 4 -NetCharge 0
Pause-Game

Compute-Check -PlainText $plainText -Formula $formula -Score ([ref]$score) -Unsafe ([ref]$unsafe)

Show-Banner
Show-Score -Score $score -Unsafe $unsafe
"Done." | Write-Host
"" | Write-Host
