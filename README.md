# Setup do Flutter + Git (Windows)

Este projeto fornece um unico script PowerShell para instalar e configurar o Git e o Flutter no Windows.

## O que o script faz

- Verifica se o Git esta instalado
- Instala o Git com winget se estiver ausente
- Solicita nome e email do Git quando nao configurados
- Verifica se o Flutter esta instalado
- Clona o Flutter em %USERPROFILE%\develop\flutter se estiver ausente
- Adiciona o Flutter ao PATH do sistema
- Exibe um resumo final

## Requisitos

- Windows 10 (1709+) ou Windows 11
- PowerShell 5.1+
- Executar o PowerShell como Administrador
- winget (App Installer) para instalar o Git

## Como executar

1. Abra o PowerShell como Administrador
2. Nesta pasta, permita scripts se necessario:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. Execute o script:
   ```powershell
   .\setup-dev-env.ps1
   ```
4. Reinicie o terminal e execute:
   ```powershell
   flutter doctor
   ```

## Observacoes

- Alterar o PATH do sistema requer privilegios de Administrador.
- Se o Flutter ja estiver instalado em outro local, o script nao sobrescreve.
