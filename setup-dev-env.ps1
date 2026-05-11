#requires -version 5.1

$ErrorActionPreference = "Stop"
$DebugEnabled = $true

function Write-DebugLog {
    param([string]$Message)
    if ($DebugEnabled) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[DEBUG $timestamp] $Message" -ForegroundColor DarkGray
    }
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

if (-not (Test-Admin)) {
    Write-DebugLog "Administrator check failed. Exiting."
    Write-Warning "Este script precisa ser executado como Administrador."
    Write-Host "Clique com o botao direito no PowerShell e selecione 'Executar como administrador'."
    exit 1
}

Write-Host "Iniciando a configuracao do Git e Flutter..." -ForegroundColor Cyan
Write-DebugLog "Script start."

# --- Git ---
$gitInstalled = Test-Command "git"
Write-DebugLog "Git detected: $gitInstalled"
if ($gitInstalled) {
    $gitVersion = git --version
    Write-DebugLog "git --version output: $gitVersion; exitCode=$LASTEXITCODE; success=$?"
    Write-Host "Git ja instalado: $gitVersion" -ForegroundColor Green
} else {
    if (-not (Test-Command "winget")) {
        Write-DebugLog "winget not found. Exiting."
        Write-Warning "winget nao esta disponivel. Instale o Git manualmente ou instale o App Installer."
        exit 1
    }

    Write-Host "Instalando o Git via winget..." -ForegroundColor Yellow
    winget install --id Git.Git -e --source winget
    Write-DebugLog "winget install finished; exitCode=$LASTEXITCODE; success=$?"

    if (-not (Test-Command "git")) {
        Write-DebugLog "Git still not found after install. Exiting."
        Write-Warning "A instalacao do Git nao foi concluida como esperado."
        exit 1
    }
}

# Configure Git if needed
$gitUserName = git config --global user.name
$gitUserEmail = git config --global user.email
Write-DebugLog "git user.name: '$gitUserName'"
Write-DebugLog "git user.email: '$gitUserEmail'"

if ([string]::IsNullOrWhiteSpace($gitUserName)) {
    $gitUserName = Read-Host "Digite seu nome de usuario do Git"
    Write-DebugLog "Read git user.name input: '$gitUserName'"
    if (-not [string]::IsNullOrWhiteSpace($gitUserName)) {
        git config --global user.name "$gitUserName"
        Write-DebugLog "Set git user.name; exitCode=$LASTEXITCODE; success=$?"
    }
}

if ([string]::IsNullOrWhiteSpace($gitUserEmail)) {
    $gitUserEmail = Read-Host "Digite seu email do Git"
    Write-DebugLog "Read git user.email input: '$gitUserEmail'"
    if (-not [string]::IsNullOrWhiteSpace($gitUserEmail)) {
        git config --global user.email "$gitUserEmail"
        Write-DebugLog "Set git user.email; exitCode=$LASTEXITCODE; success=$?"
    }
}

Write-Host "Configuracao do Git concluida." -ForegroundColor Green

# --- Flutter ---
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$flutterInPath = ($machinePath -like "*flutter\bin*") -or ($userPath -like "*flutter\bin*")
Write-DebugLog "flutter command found: $([bool]$flutterCmd)"
Write-DebugLog "flutter bin in machine PATH: $($machinePath -like "*flutter\\bin*")"
Write-DebugLog "flutter bin in user PATH: $($userPath -like "*flutter\\bin*")"

if ($flutterCmd -or $flutterInPath) {
    Write-Host "Flutter ja instalado." -ForegroundColor Green
} else {
    $developPath = Join-Path $env:USERPROFILE "develop"
    if (-not (Test-Path $developPath)) {
        New-Item -ItemType Directory -Path $developPath | Out-Null
        Write-DebugLog "Created develop directory: $developPath"
        Write-Host "Pasta criada: $developPath" -ForegroundColor Green
    }

    $flutterDir = Join-Path $developPath "flutter"
    if (Test-Path $flutterDir) {
        Write-DebugLog "Flutter directory exists: $flutterDir"
        Write-Host "A pasta do Flutter ja existe: $flutterDir" -ForegroundColor Yellow
    } else {
        Write-Host "Clonando o Flutter... isso pode levar alguns minutos." -ForegroundColor Yellow
        Push-Location $developPath
        git clone https://github.com/flutter/flutter.git
        Write-DebugLog "git clone finished; exitCode=$LASTEXITCODE; success=$?"
        Pop-Location
    }

    $flutterBinPath = Join-Path $flutterDir "bin"
    if ($machinePath -notlike "*$flutterBinPath*") {
        $newPath = "$machinePath;$flutterBinPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-DebugLog "Updated machine PATH with: $flutterBinPath"
        Write-Host "Flutter adicionado ao PATH do sistema." -ForegroundColor Green
    } else {
        Write-DebugLog "Machine PATH already contains: $flutterBinPath"
        Write-Host "Flutter ja esta no PATH do sistema." -ForegroundColor Green
    }
}

# --- Summary ---
$gitVersionFinal = ""
if (Test-Command "git") {
    $gitVersionFinal = git --version
    Write-DebugLog "Final git --version: $gitVersionFinal; exitCode=$LASTEXITCODE; success=$?"
}

$flutterBinPathFinal = ""
if (-not $flutterBinPathFinal) {
    $flutterBinPathFinal = "${env:USERPROFILE}\develop\flutter\bin"
}

Write-Host "" 
Write-Host "========== SETUP CONCLUIDO ==========" -ForegroundColor Cyan
Write-Host "Git: $gitVersionFinal"
Write-Host "Caminho do Flutter: $flutterBinPathFinal"
Write-Host "Reinicie o terminal para que as alteracoes no PATH tenham efeito."
Write-Host "Depois execute: flutter doctor"
Write-Host "====================================" -ForegroundColor Cyan
