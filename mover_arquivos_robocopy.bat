@echo off
setlocal enabledelayedexpansion

:Start
echo =======================================
echo     Mover Arquivos com ROBocopy
echo =======================================
echo.

:: 1) Solicita ao usuário o caminho da pasta de origem
set /p SOURCE="Digite o caminho da pasta de origem: "
if not exist "%SOURCE%" (
    echo ERRO: A pasta de origem "%SOURCE%" nao existe.
    pause
    exit /b 1
)

:: 2) Solicita ao usuário o caminho da pasta de destino
set /p DEST="Digite o caminho da pasta de destino: "
if not exist "%DEST%" (
    echo A pasta de destino nao existe. Criando "%DEST%"...
    md "%DEST%"
)

:: 3) Solicita ao usuário a data-limite (dd/mm/aaaa)
set /p DATELIMIT="Digite a data limite (dd/mm/aaaa) para mover arquivos anteriores a esta data: "
::    Extrai DD, MM e AAAA da string dd/mm/aaaa
for /f "tokens=1-3 delims=/-." %%A in ("%DATELIMIT%") do (
    set "DD=%%A"
    set "MM=%%B"
    set "YYYY=%%C"
)
::    Monta filtro no formato YYYYMMDD para o Robocopy
set "FILTER=%YYYY%%MM%%DD%"

echo.
echo Movendo do:  %SOURCE%
echo Para:       %DEST%
echo Data-limite: %DATELIMIT% (serao movidos apenas arquivos anteriores a esta data)
echo.
echo Iniciando a operacao... Aguarde.
echo.

:: 4) Executa o robocopy com todos os parâmetros:
::    /E      = copia subpastas, inclusive vazias
::    /MOVE   = move arquivos e pastas (deleta na origem)
::    /ETA    = mostra estimativa de tempo restante
::    /FP     = exibe caminhos completos dos arquivos
::    /R:1    = tenta 1 vez em caso de falha
::    /W:3    = espera 3 segundos entre tentativas
::    /MINAGE = exclui arquivos mais novos que a data, portanto só inclui os mais antigos
robocopy "%SOURCE%" "%DEST%" /E /MOVE /ETA /FP /R:1 /W:3 /MINAGE:%FILTER%

echo.
echo Operacao concluida!
echo.

:: 5) Pergunta se o usuário quer executar novamente
set /p REPEAT="Deseja realizar outra operacao? [S/N]: "
if /I "%REPEAT%"=="S" (
    echo.
    goto Start
)

echo Encerrando...
pause
