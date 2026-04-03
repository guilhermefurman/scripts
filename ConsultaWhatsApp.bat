@echo off
chcp 65001 > nul
title Verificador de Números WhatsApp - Evolution API

REM ==========================================
REM CONFIGURAÇÕES - EDITE AQUI
REM ==========================================
set SERVER_URL=
set INSTANCE=
set API_KEY=

REM ==========================================
REM VERIFICAÇÃO DE CURL
REM ==========================================
curl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ERRO] cURL não está instalado ou não está no PATH do sistema
    echo Por favor, instale o cURL ou adicione ao PATH
    echo.
    pause
    exit /b 1
)

:MENU
cls
echo.
echo ==========================================
echo   VERIFICADOR DE NÚMEROS WHATSAPP
echo ==========================================
echo.
echo Servidor: %SERVER_URL%
echo Instância: %INSTANCE%
echo.

REM ==========================================
REM SOLICITAR NÚMERO
REM ==========================================
set /p NUMERO="Digite o número (formato: 5531998887777): "

if "%NUMERO%"=="" (
    echo.
    echo [ERRO] Número não pode estar vazio!
    echo.
    pause
    goto MENU
)

REM ==========================================
REM VALIDAÇÃO BÁSICA DO NÚMERO
REM ==========================================
echo %NUMERO%| findstr /r "^[0-9][0-9]*$" >nul
if %errorlevel% neq 0 (
    echo.
    echo [ERRO] O número deve conter apenas dígitos!
    echo.
    pause
    goto MENU
)

REM ==========================================
REM FAZER A CONSULTA
REM ==========================================
echo.
echo Verificando número %NUMERO%...
echo.

REM Criar arquivo JSON temporário
set TEMP_JSON=%TEMP%\whatsapp_check.json
echo {"numbers": ["%NUMERO%"]} > "%TEMP_JSON%"

REM Fazer a requisição
curl --request POST ^
  --url "%SERVER_URL%/chat/whatsappNumbers/%INSTANCE%" ^
  --header "Content-Type: application/json" ^
  --header "apikey: %API_KEY%" ^
  --data "@%TEMP_JSON%" ^
  --silent ^
  --show-error ^
  --write-out "\n\nStatus HTTP: %%{http_code}\n" ^
  --output "%TEMP%\whatsapp_response.json"

REM Verificar se a requisição foi bem-sucedida
if %errorlevel% neq 0 (
    echo.
    echo [ERRO] Falha na requisição HTTP
    echo Verifique se o servidor está acessível e as configurações estão corretas
    echo.
    goto CLEANUP
)

REM ==========================================
REM PROCESSAR RESPOSTA
REM ==========================================
echo.
echo ==========================================
echo RESULTADO DA CONSULTA:
echo ==========================================

REM Exibir resposta formatada
type "%TEMP%\whatsapp_response.json"

echo.
echo ==========================================

REM Verificar se o número existe (análise simples)
findstr /c:"\"exists\": true" "%TEMP%\whatsapp_response.json" >nul
if %errorlevel% equ 0 (
    echo STATUS: ? NÚMERO EXISTE NO WHATSAPP
) else (
    findstr /c:"\"exists\": false" "%TEMP%\whatsapp_response.json" >nul
    if %errorlevel% equ 0 (
        echo STATUS: ? NÚMERO NÃO EXISTE NO WHATSAPP
    ) else (
        echo STATUS: ? RESPOSTA INESPERADA
    )
)

:CLEANUP
REM Limpar arquivos temporários
if exist "%TEMP_JSON%" del "%TEMP_JSON%"
if exist "%TEMP%\whatsapp_response.json" del "%TEMP%\whatsapp_response.json"

echo.
echo ==========================================
echo.
set /p CONTINUAR="Deseja verificar outro número? (s/n): "
if /i "%CONTINUAR%"=="s" goto MENU
if /i "%CONTINUAR%"=="sim" goto MENU

echo.
echo Obrigado por usar o verificador!
pause
exit /b 0