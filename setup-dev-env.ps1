#requires -version 5.1

$ErrorActionPreference = "Stop"

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
    Write-Warning "Este script precisa ser executado como Administrador."
    Write-Host "Clique com o botao direito no PowerShell e selecione 'Executar como administrador'."
    exit 1
}

Write-Host "Iniciando a configuracao do Git e Flutter..." -ForegroundColor Cyan

# --- Git ---
$gitInstalled = Test-Command "git"
if ($gitInstalled) {
    $gitVersion = git --version
    Write-Host "Git ja instalado: $gitVersion" -ForegroundColor Green
} else {
    if (-not (Test-Command "winget")) {
        Write-Warning "winget nao esta disponivel. Instale o Git manualmente ou instale o App Installer."
        exit 1
    }

    Write-Host "Instalando o Git via winget..." -ForegroundColor Yellow
    winget install --id Git.Git -e --source winget

    if (-not (Test-Command "git")) {
        Write-Warning "A instalacao do Git nao foi concluida como esperado."
        exit 1
    }
}

# Configure Git if needed
$gitUserName = git config --global user.name
$gitUserEmail = git config --global user.email

if ([string]::IsNullOrWhiteSpace($gitUserName)) {
    $gitUserName = Read-Host "Digite seu nome de usuario do Git"
    if (-not [string]::IsNullOrWhiteSpace($gitUserName)) {
        git config --global user.name "$gitUserName"
    }
}

if ([string]::IsNullOrWhiteSpace($gitUserEmail)) {
    $gitUserEmail = Read-Host "Digite seu email do Git"
    if (-not [string]::IsNullOrWhiteSpace($gitUserEmail)) {
        git config --global user.email "$gitUserEmail"
    }
}

Write-Host "Configuracao do Git concluida." -ForegroundColor Green

# --- Flutter ---
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$flutterInPath = ($machinePath -like "*flutter\bin*") -or ($userPath -like "*flutter\bin*")

if ($flutterCmd -or $flutterInPath) {
    Write-Host "Flutter ja instalado." -ForegroundColor Green
} else {
    $developPath = Join-Path $env:USERPROFILE "develop"
    if (-not (Test-Path $developPath)) {
        New-Item -ItemType Directory -Path $developPath | Out-Null
        Write-Host "Pasta criada: $developPath" -ForegroundColor Green
    }

    $flutterDir = Join-Path $developPath "flutter"
    if (Test-Path $flutterDir) {
        Write-Host "A pasta do Flutter ja existe: $flutterDir" -ForegroundColor Yellow
    } else {
        Write-Host "Clonando o Flutter... isso pode levar alguns minutos." -ForegroundColor Yellow
        Push-Location $developPath
        git clone https://github.com/flutter/flutter.git
        Pop-Location
    }

    $flutterBinPath = Join-Path $flutterDir "bin"
    if ($machinePath -notlike "*$flutterBinPath*") {
        $newPath = "$machinePath;$flutterBinPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Host "Flutter adicionado ao PATH do sistema." -ForegroundColor Green
    } else {
        Write-Host "Flutter ja esta no PATH do sistema." -ForegroundColor Green
    }
}

# --- Summary ---
$gitVersionFinal = ""
if (Test-Command "git") {
    $gitVersionFinal = git --version
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
