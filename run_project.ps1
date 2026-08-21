# ============================================================
# UNIVERSAL PYTHON PROJECT RUNNER
# ============================================================
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\run_project.ps1
#
# Or simply:
#   .\run_project.ps1
# ============================================================

$ErrorActionPreference = "Stop"

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "              UNIVERSAL PYTHON PROJECT RUNNER" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. PROJECT DIRECTORY
# ------------------------------------------------------------

$ProjectDir = Get-Location
$VenvDir = Join-Path $ProjectDir ".venv"
$Requirements = Join-Path $ProjectDir "requirements.txt"

Write-Host "[PROJECT] $ProjectDir" -ForegroundColor White
Write-Host ""

# ------------------------------------------------------------
# 2. CHECK PYTHON
# ------------------------------------------------------------

Write-Host "[1/7] Checking Python..." -ForegroundColor Yellow

$PythonCommand = $null

try {
    $PythonVersion = python --version 2>&1

    if ($LASTEXITCODE -eq 0) {
        $PythonCommand = "python"
        Write-Host "[OK] $PythonVersion" -ForegroundColor Green
    }
}
catch {
    $PythonCommand = $null
}

if (-not $PythonCommand) {
    try {
        $PyVersion = py --version 2>&1

        if ($LASTEXITCODE -eq 0) {
            $PythonCommand = "py"
            Write-Host "[OK] $PyVersion" -ForegroundColor Green
        }
    }
    catch {
        $PythonCommand = $null
    }
}

if (-not $PythonCommand) {
    Write-Host ""
    Write-Host "[ERROR] Python is not installed or not available in PATH." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Python 3.11+ and enable 'Add Python to PATH'." -ForegroundColor Yellow
    exit 1
}

# ------------------------------------------------------------
# 3. CHECK PYTHON VERSION
# ------------------------------------------------------------

Write-Host ""
Write-Host "[2/7] Checking Python version..." -ForegroundColor Yellow

$VersionOutput = if ($PythonCommand -eq "python") {
    python --version
} else {
    py --version
}

Write-Host "[PYTHON] $VersionOutput" -ForegroundColor Green

# ------------------------------------------------------------
# 4. CREATE VIRTUAL ENVIRONMENT
# ------------------------------------------------------------

Write-Host ""
Write-Host "[3/7] Checking virtual environment..." -ForegroundColor Yellow

if (-not (Test-Path $VenvDir)) {

    Write-Host "[INFO] No virtual environment found." -ForegroundColor Yellow
    Write-Host "[INFO] Creating .venv..." -ForegroundColor Yellow

    if ($PythonCommand -eq "python") {
        python -m venv .venv
    }
    else {
        py -m venv .venv
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to create virtual environment." -ForegroundColor Red
        exit 1
    }

    Write-Host "[OK] Virtual environment created." -ForegroundColor Green
}
else {
    Write-Host "[OK] Existing .venv found." -ForegroundColor Green
}

# ------------------------------------------------------------
# 5. USE VENV PYTHON
# ------------------------------------------------------------

$VenvPython = Join-Path $VenvDir "Scripts\python.exe"

if (-not (Test-Path $VenvPython)) {
    Write-Host "[ERROR] Virtual environment Python not found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/7] Preparing Python environment..." -ForegroundColor Yellow

& $VenvPython --version

Write-Host "[INFO] Updating pip..." -ForegroundColor Gray

& $VenvPython -m pip install --upgrade pip

if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] pip update failed. Continuing..." -ForegroundColor Yellow
}
else {
    Write-Host "[OK] pip ready." -ForegroundColor Green
}

# ------------------------------------------------------------
# 6. INSTALL REQUIREMENTS
# ------------------------------------------------------------

Write-Host ""
Write-Host "[5/7] Checking project dependencies..." -ForegroundColor Yellow

$RequirementFiles = @(
    "requirements.txt",
    "requirements-dev.txt",
    "requirements-prod.txt"
)

$FoundRequirements = $false

foreach ($ReqName in $RequirementFiles) {

    $ReqPath = Join-Path $ProjectDir $ReqName

    if (Test-Path $ReqPath) {

        $FoundRequirements = $true

        Write-Host "[FOUND] $ReqName" -ForegroundColor Green
        Write-Host "[INFO] Installing dependencies..." -ForegroundColor Gray

        & $VenvPython -m pip install -r $ReqPath

        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "[ERROR] Dependency installation failed." -ForegroundColor Red
            Write-Host "Check $ReqName for invalid packages." -ForegroundColor Yellow
            exit 1
        }

        Write-Host "[OK] Dependencies installed." -ForegroundColor Green
    }
}

if (-not $FoundRequirements) {

    Write-Host "[INFO] No requirements file found." -ForegroundColor Yellow

    # Try common Python packages based on project files
    $PossiblePackages = @()

    if (
        (Test-Path "streamlit") -or
        (Test-Path "app.py")
    ) {
        $PossiblePackages += "streamlit"
    }

    if (Test-Path "requirements.txt") {
        # already handled above
    }

    if ($PossiblePackages.Count -gt 0) {
        Write-Host "[INFO] Common framework detected." -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------
# 7. DETECT APPLICATION
# ------------------------------------------------------------

Write-Host ""
Write-Host "[6/7] Detecting application entry point..." -ForegroundColor Yellow

$StreamlitFiles = @(
    "app.py",
    "streamlit_app.py",
    "main.py",
    "dashboard.py",
    "webapp.py",
    "frontend.py"
)

$PythonFiles = @(
    "app.py",
    "main.py",
    "run.py",
    "server.py",
    "start.py",
    "main_app.py",
    "application.py"
)

$EntryFile = $null
$RunMode = $null

# ------------------------------------------------------------
# PRIORITY 1: STREAMLIT
# ------------------------------------------------------------

$StreamlitCommand = Join-Path $VenvDir "Scripts\streamlit.exe"

if (Test-Path $StreamlitCommand) {

    foreach ($File in $StreamlitFiles) {

        if (Test-Path (Join-Path $ProjectDir $File)) {

            $EntryFile = $File
            $RunMode = "streamlit"

            break
        }
    }
}

# ------------------------------------------------------------
# PRIORITY 2: PYTHON APP
# ------------------------------------------------------------

if (-not $EntryFile) {

    foreach ($File in $PythonFiles) {

        if (Test-Path (Join-Path $ProjectDir $File)) {

            $EntryFile = $File
            $RunMode = "python"

            break
        }
    }
}

# ------------------------------------------------------------
# PRIORITY 3: FIND ANY PYTHON FILE
# ------------------------------------------------------------

if (-not $EntryFile) {

    $Candidates = Get-ChildItem -Path $ProjectDir -Filter "*.py" -File |
        Where-Object {
            $_.Name -notmatch "test|train|setup|config|utils|model"
        } |
        Sort-Object Name

    if ($Candidates.Count -gt 0) {

        $EntryFile = $Candidates[0].Name
        $RunMode = "python"

        Write-Host "[AUTO] Using detected Python file: $EntryFile" -ForegroundColor Yellow
    }
}

if (-not $EntryFile) {

    Write-Host ""
    Write-Host "[ERROR] Could not find an application entry point." -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected files such as:" -ForegroundColor Yellow
    Write-Host "  app.py"
    Write-Host "  main.py"
    Write-Host "  run.py"
    Write-Host "  streamlit_app.py"
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "[FOUND] $EntryFile" -ForegroundColor Green
Write-Host "[MODE]  $RunMode" -ForegroundColor Green

# ------------------------------------------------------------
# 8. OPTIONAL MODEL TRAINING DETECTION
# ------------------------------------------------------------

Write-Host ""
Write-Host "[7/7] Checking project startup requirements..." -ForegroundColor Yellow

$ModelFiles = @(
    "train.py",
    "train_model.py",
    "training.py"
)

$HasModel = $false

foreach ($ModelFile in $ModelFiles) {

    if (Test-Path (Join-Path $ProjectDir $ModelFile)) {

        $HasModel = $true

        Write-Host "[INFO] Training script detected: $ModelFile" -ForegroundColor Yellow

        $ModelDirectories = @(
            "models",
            "model",
            "saved_models"
        )

        $ModelExists = $false

        foreach ($Dir in $ModelDirectories) {

            if (Test-Path (Join-Path $ProjectDir $Dir)) {

                $FilesInside = Get-ChildItem `
                    -Path (Join-Path $ProjectDir $Dir) `
                    -File `
                    -ErrorAction SilentlyContinue

                if ($FilesInside.Count -gt 0) {
                    $ModelExists = $true
                }
            }
        }

        if (-not $ModelExists) {

            Write-Host "[INFO] No saved model detected." -ForegroundColor Yellow
            Write-Host "[INFO] Running training script..." -ForegroundColor Yellow

            & $VenvPython $ModelFile

            if ($LASTEXITCODE -ne 0) {

                Write-Host ""
                Write-Host "[ERROR] Model training failed." -ForegroundColor Red
                exit 1
            }

            Write-Host "[OK] Training completed." -ForegroundColor Green
        }

        break
    }
}

# ------------------------------------------------------------
# 9. RUN APPLICATION
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                    STARTING PROJECT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($RunMode -eq "streamlit") {

    Write-Host "[START] Streamlit application" -ForegroundColor Green
    Write-Host "[FILE]  $EntryFile" -ForegroundColor White
    Write-Host ""

    & $StreamlitCommand run $EntryFile
}
else {

    Write-Host "[START] Python application" -ForegroundColor Green
    Write-Host "[FILE]  $EntryFile" -ForegroundColor White
    Write-Host ""

    & $VenvPython $EntryFile
}

# ------------------------------------------------------------
# EXIT
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                    APPLICATION STOPPED" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Application exited with code $LASTEXITCODE" -ForegroundColor Red
}
else {
    Write-Host "[OK] Application exited normally." -ForegroundColor Green
}

Read-Host "Press ENTER to close"