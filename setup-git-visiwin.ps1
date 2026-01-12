# VisiWin 7 Git Integration Setup Script (PowerShell)
# Run this script after cloning the repository to configure Git for VisiWin project comparison

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VisiWin 7 Git Integration Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get the repository root directory
$repoDir = $PSScriptRoot
Write-Host "Repository directory: $repoDir"
Write-Host ""

# Check if VisiWin ProjectCompare exists
$visiwinPath = "C:\Program Files (x86)\INOSOFT GmbH\VisiWin 7\Development\bin\VisiWin7.ProjectCompare.exe"
if (-not (Test-Path $visiwinPath)) {
    Write-Host "ERROR: VisiWin ProjectCompare not found at:" -ForegroundColor Red
    Write-Host $visiwinPath -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install VisiWin 7 or update the path in this script." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Found VisiWin ProjectCompare: OK" -ForegroundColor Green
Write-Host ""

# Check for Visual Studio versions
$vs2019Path = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\vsdiffmerge.exe"
$vs2022Path = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\vsdiffmerge.exe"

$vsPath = $null
$vsVersion = $null
$vs2019Found = Test-Path $vs2019Path
$vs2022Found = Test-Path $vs2022Path

if ($vs2019Found -and $vs2022Found) {
    # Both versions found - ask user which to use
    Write-Host "Found Visual Studio 2019: OK" -ForegroundColor Green
    Write-Host "Found Visual Studio 2022: OK" -ForegroundColor Green
    Write-Host ""
    Write-Host "Both Visual Studio 2019 and 2022 are installed." -ForegroundColor Cyan
    Write-Host "Which version would you like to use for diff/merge?" -ForegroundColor Cyan
    Write-Host "  [1] Visual Studio 2019" -ForegroundColor White
    Write-Host "  [2] Visual Studio 2022" -ForegroundColor White
    Write-Host ""

    do {
        $choice = Read-Host "Enter your choice (1 or 2)"
        if ($choice -eq "1") {
            $vsPath = $vs2019Path
            $vsVersion = "2019"
            Write-Host "Selected Visual Studio 2019" -ForegroundColor Green
            break
        } elseif ($choice -eq "2") {
            $vsPath = $vs2022Path
            $vsVersion = "2022"
            Write-Host "Selected Visual Studio 2022" -ForegroundColor Green
            break
        } else {
            Write-Host "Invalid choice. Please enter 1 or 2." -ForegroundColor Red
        }
    } while ($true)
} elseif ($vs2019Found) {
    $vsPath = $vs2019Path
    $vsVersion = "2019"
    Write-Host "Found Visual Studio 2019: OK" -ForegroundColor Green
} elseif ($vs2022Found) {
    $vsPath = $vs2022Path
    $vsVersion = "2022"
    Write-Host "Found Visual Studio 2022: OK" -ForegroundColor Green
} else {
    Write-Host "WARNING: Visual Studio diff/merge tool not found." -ForegroundColor Yellow
    Write-Host "The setup will continue, but diff/merge for non-.vw7 files may not work." -ForegroundColor Yellow
}

Write-Host ""

# Check for driver scripts and create if missing
Write-Host "Checking driver scripts..." -ForegroundColor Cyan

$diffDriverPath = Join-Path $repoDir "DiffDriver.cmd"
$mergeDriverPath = Join-Path $repoDir "MergeDriver.cmd"

# Determine Visual Studio path based on version
if ($vsVersion -eq "2022") {
    $vsProgramFiles = "Program Files"
    $vsVersionNumber = "2022"
} elseif ($vsVersion -eq "2019") {
    $vsProgramFiles = "Program Files (x86)"
    $vsVersionNumber = "2019"
} else {
    # Default to 2019 if no VS found
    $vsProgramFiles = "Program Files (x86)"
    $vsVersionNumber = "2019"
}

# Create DiffDriver.cmd if it doesn't exist
if (-not (Test-Path $diffDriverPath)) {
    Write-Host "DiffDriver.cmd not found. Creating..." -ForegroundColor Yellow

    $diffDriverContent = @"
@echo off
REM VisiWin 7 Git Diff Driver
REM Routes .vw7 files to VisiWin ProjectCompare and other files to Visual Studio

set REMOTE=%1
set LOCAL=%2
set BASE=%3

set file_ext=%~x1
if "%file_ext%"==".vw7" (
    "C:\Program Files (x86)\INOSOFT GmbH\VisiWin 7\Development\bin\VisiWin7.ProjectCompare.exe" -c %REMOTE% %LOCAL%
) else (
    "C:\$vsProgramFiles\Microsoft Visual Studio\$vsVersionNumber\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\vsdiffmerge.exe" %LOCAL% %REMOTE% /t
)
"@

    Set-Content -Path $diffDriverPath -Value $diffDriverContent -Encoding ASCII
    Write-Host "DiffDriver.cmd created: OK" -ForegroundColor Green
} else {
    Write-Host "DiffDriver.cmd found: OK" -ForegroundColor Green
}

# Create MergeDriver.cmd if it doesn't exist
if (-not (Test-Path $mergeDriverPath)) {
    Write-Host "MergeDriver.cmd not found. Creating..." -ForegroundColor Yellow

    $mergeDriverContent = @"
@echo off
REM VisiWin 7 Git Merge Driver
REM Routes .vw7 files to VisiWin ProjectCompare and other files to Visual Studio

set REMOTE=%1
set LOCAL=%2
set BASE=%3
set MERGED=%4

set file_ext=%~x1
if "%file_ext%"==".vw7" (
    "C:\Program Files (x86)\INOSOFT GmbH\VisiWin 7\Development\bin\VisiWin7.ProjectCompare.exe" -m %REMOTE% %LOCAL% %MERGED%
) else (
    "C:\$vsProgramFiles\Microsoft Visual Studio\$vsVersionNumber\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\vsdiffmerge.exe" %REMOTE% %LOCAL% %BASE% %MERGED% /m
)
"@

    Set-Content -Path $mergeDriverPath -Value $mergeDriverContent -Encoding ASCII
    Write-Host "MergeDriver.cmd created: OK" -ForegroundColor Green
} else {
    Write-Host "MergeDriver.cmd found: OK" -ForegroundColor Green
}

# Update driver scripts to match selected Visual Studio version
Write-Host "Checking driver scripts for Visual Studio version..." -ForegroundColor Cyan

$diffContent = Get-Content $diffDriverPath -Raw
$mergeContent = Get-Content $mergeDriverPath -Raw

# Detect current version in driver scripts
$currentScriptVersion = $null
if ($diffContent -match "2022") {
    $currentScriptVersion = "2022"
} elseif ($diffContent -match "2019") {
    $currentScriptVersion = "2019"
}

# Update if version mismatch
if ($vsVersion -and $currentScriptVersion -ne $vsVersion) {
    Write-Host "Driver scripts are configured for VS $currentScriptVersion" -ForegroundColor Yellow
    Write-Host "Updating driver scripts to Visual Studio $vsVersion..." -ForegroundColor Yellow

    if ($vsVersion -eq "2022") {
        # Update from 2019 to 2022
        $diffContent = $diffContent -replace "2019", "2022"
        $diffContent = $diffContent -replace "Program Files \(x86\)\\Microsoft Visual Studio", "Program Files\\Microsoft Visual Studio"

        $mergeContent = $mergeContent -replace "2019", "2022"
        $mergeContent = $mergeContent -replace "Program Files \(x86\)\\Microsoft Visual Studio", "Program Files\\Microsoft Visual Studio"
    } elseif ($vsVersion -eq "2019") {
        # Update from 2022 to 2019
        $diffContent = $diffContent -replace "2022", "2019"
        $diffContent = $diffContent -replace "Program Files\\Microsoft Visual Studio", "Program Files (x86)\\Microsoft Visual Studio"

        $mergeContent = $mergeContent -replace "2022", "2019"
        $mergeContent = $mergeContent -replace "Program Files\\Microsoft Visual Studio", "Program Files (x86)\\Microsoft Visual Studio"
    }

    Set-Content -Path $diffDriverPath -Value $diffContent -NoNewline
    Set-Content -Path $mergeDriverPath -Value $mergeContent -NoNewline

    Write-Host "Driver scripts updated to VS $vsVersion : OK" -ForegroundColor Green
} elseif ($vsVersion) {
    Write-Host "Driver scripts already configured for VS $vsVersion : OK" -ForegroundColor Green
} else {
    Write-Host "No Visual Studio version detected, driver scripts not updated" -ForegroundColor Yellow
}

Write-Host ""

# Check .gitignore file
Write-Host "Checking .gitignore configuration..." -ForegroundColor Cyan
Write-Host ""

$gitignorePath = Join-Path $repoDir ".gitignore"
$requiredPatterns = @(
    "*.vwa",
    "*.vwh",
    "*.vaa",
    "*.vwl",
    "*.vwy",
    "*.rt7",
    "*.rtvw7",
    "*.rtn",
    "*.src",
    "*.ldb",
    "*.sdf",
    "*.UserLog.txt",
    "*.Device.config",
    "*.vwsettings",
    "*.pdb",
    ".claude/"
)

if (-not (Test-Path $gitignorePath)) {
    Write-Host "WARNING: .gitignore file not found!" -ForegroundColor Red
    Write-Host "Creating .gitignore with required VisiWin patterns..." -ForegroundColor Yellow

    $gitignoreContent = @"
# VisiWin 7 Project .gitignore

# VisiWin-specific files
*.vwa
*.vwh
*.vaa
*.vwl
*.vwy
*.rt7
*.rtvw7
*.rtn
*.src
*.ldb
*.sdf
*.UserLog.txt
*.Device.config
*.vwsettings

# Build outputs
bin/
obj/
*.dll
*.exe
*.pdb

# VisiWin temporary files
*.tmp
*.bak
*.log

# Visual Studio
.vs/
*.suo
*.user
*.userosscache
*.sln.docstates

# User-specific files
*.rsuser
*.userprefs

# Build results
[Dd]ebug/
[Dd]ebugPublic/
[Rr]elease/
[Rr]eleases/
x64/
x86/
[Aa][Rr][Mm]/
[Aa][Rr][Mm]64/
bld/
[Bb]in/
[Oo]bj/

# NuGet Packages
*.nupkg
**/packages/*
!**/packages/build/

# Windows image file caches
Thumbs.db
ehthumbs.db

# Folder config file
Desktop.ini

# Recycle Bin used on file shares
`$RECYCLE.BIN/

# VS Code
.vscode/

# Rider
.idea/

# Claude Code
.claude/
"@

    Set-Content -Path $gitignorePath -Value $gitignoreContent -Encoding UTF8
    Write-Host ".gitignore created successfully: OK" -ForegroundColor Green
} else {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    $missingPatterns = @()

    foreach ($pattern in $requiredPatterns) {
        # Check if pattern exists in gitignore (as whole line or part of line)
        if ($gitignoreContent -notmatch [regex]::Escape($pattern)) {
            $missingPatterns += $pattern
        }
    }

    if ($missingPatterns.Count -eq 0) {
        Write-Host ".gitignore contains all required patterns: OK" -ForegroundColor Green
    } else {
        Write-Host "WARNING: .gitignore is missing the following patterns:" -ForegroundColor Yellow
        foreach ($pattern in $missingPatterns) {
            Write-Host "  - $pattern" -ForegroundColor Yellow
        }
        Write-Host ""

        $response = Read-Host "Do you want to add the missing patterns to .gitignore? (Y/N)"
        if ($response -eq "Y" -or $response -eq "y") {
            # Add a VisiWin section if it doesn't exist
            if ($gitignoreContent -notmatch "VisiWin-specific files") {
                $gitignoreContent += "`n`n# VisiWin-specific files`n"
            }

            foreach ($pattern in $missingPatterns) {
                $gitignoreContent += "$pattern`n"
            }

            Set-Content -Path $gitignorePath -Value $gitignoreContent.TrimEnd() -Encoding UTF8 -NoNewline
            Write-Host "Missing patterns added to .gitignore: OK" -ForegroundColor Green
        } else {
            Write-Host "Skipping .gitignore update. Please add the patterns manually." -ForegroundColor Yellow
        }
    }
}

Write-Host ""

# Configure Git
Write-Host "Configuring Git settings..." -ForegroundColor Cyan
Write-Host ""

# Convert paths to forward slashes for Git config (works on Windows and avoids escaping issues)
$repoDirForGit = $repoDir -replace "\\", "/"
$visiwinPathForGit = $visiwinPath -replace "\\", "/"

# Clean any existing configuration to ensure idempotency
Write-Host "Cleaning previous Git configuration (if any)..." -ForegroundColor Yellow
git config --local --remove-section difftool.vw7diff 2>$null
git config --local --remove-section mergetool.vw7merge 2>$null
git config --local --remove-section difftool.DiffDriver 2>$null
git config --local --remove-section mergetool.MergeDriver 2>$null

# Configure basic difftool for .vw7 files
git config --local difftool.vw7diff.cmd "`"$visiwinPathForGit`" -c `"`$REMOTE`" `"`$LOCAL`""

# Configure basic mergetool for .vw7 files
git config --local mergetool.vw7merge.cmd "`"$visiwinPathForGit`" -m `"`$REMOTE`" `"`$LOCAL`" `"`$MERGED`""
git config --local mergetool.vw7merge.trustExitCode false

# Configure Visual Studio Integration - External Diff Driver
git config --local difftool.DiffDriver.name "External Diff Driver"
git config --local difftool.DiffDriver.cmd "\`"$repoDir\DiffDriver.cmd\`" `$REMOTE `$LOCAL `$BASE"
git config --local difftool.DiffDriver.keepBackup false

# Configure Visual Studio Integration - External Merge Driver
git config --local mergetool.MergeDriver.name "External Merge Driver"
git config --local mergetool.MergeDriver.cmd "\`"$repoDir\MergeDriver.cmd\`" `$REMOTE `$LOCAL `$BASE `$MERGED"
git config --local mergetool.MergeDriver.trustExitCode false
git config --local mergetool.MergeDriver.keepBackup false

# Set default tools
git config --local diff.tool DiffDriver
git config --local merge.tool MergeDriver

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Configuration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Git has been configured to use:" -ForegroundColor Cyan
Write-Host "  - VisiWin ProjectCompare for .vw7 files" -ForegroundColor White
Write-Host "  - Visual Studio tools for other files" -ForegroundColor White
Write-Host ""
Write-Host "You can now use:" -ForegroundColor Cyan
Write-Host "  git difftool [options] -- file.vw7" -ForegroundColor White
Write-Host "  git mergetool file.vw7" -ForegroundColor White
Write-Host ""
Write-Host "See GIT_SETUP_README.md for more information." -ForegroundColor Yellow
Write-Host ""

Read-Host "Press Enter to exit"
