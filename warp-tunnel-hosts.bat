@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

SET "HOSTS_FILE=%~dp0hosts.txt"
SET "TMPFILE=%TEMP%\warp_existing_hosts.tmp"

IF NOT EXIST "%HOSTS_FILE%" (
    echo  [ОШИБКА] Файл не найден: %HOSTS_FILE%
    pause
    exit /b 1
)

:menu
cls
echo.
echo  Cloudflare WARP -- Tunnel Host Manager
echo  ----------------------------------------
echo   Файл: %HOSTS_FILE%
echo.
echo   [1]  Добавить все хосты (пропустить уже добавленные)
echo   [2]  Удалить все хосты (пропустить отсутствующие)
echo   [3]  Показать хосты в WARP (tunnel host list)
echo   [4]  Показать содержимое файла
echo   [5]  Выход
echo.
set /p "CHOICE=  Выбор: "

if "%CHOICE%"=="1" call :do_add
if "%CHOICE%"=="2" call :do_remove
if "%CHOICE%"=="3" goto do_list
if "%CHOICE%"=="4" goto show_file
if "%CHOICE%"=="5" goto end
goto menu

:do_add
cls
echo.
echo  Получаем текущий список хостов WARP...
warp-cli tunnel host list > "%TMPFILE%" 2>nul

SET /A OK=0
SET /A SKIP_EXISTS=0
SET /A SKIP_COMMENT=0
SET /A FAIL=0

for /F "usebackq tokens=1 delims= " %%L in ("%HOSTS_FILE%") do (
    SET "LINE=%%L"
    if "!LINE:~0,1!"=="#" (
        SET /A SKIP_COMMENT+=1
    ) else (
        findstr /I /C:"  !LINE! " "%TMPFILE%" >nul 2>&1
        if !errorlevel! == 0 (
            echo   = !LINE!  [уже есть, пропускаем]
            SET /A SKIP_EXISTS+=1
        ) else (
            echo   + !LINE!
            warp-cli tunnel host add "!LINE!"
            if !errorlevel! == 0 (
                SET /A OK+=1
            ) else (
                SET /A FAIL+=1
            )
        )
    )
)

del "%TMPFILE%" >nul 2>&1
echo.
echo  Добавлено: !OK!   Уже было: !SKIP_EXISTS!   Ошибок: !FAIL!   Комментариев: !SKIP_COMMENT!
echo.
pause
goto menu

:do_remove
cls
echo.
echo  Получаем текущий список хостов WARP...
warp-cli tunnel host list > "%TMPFILE%" 2>nul

SET /A OK=0
SET /A SKIP_EXISTS=0
SET /A SKIP_COMMENT=0
SET /A FAIL=0

for /F "usebackq tokens=1 delims= " %%L in ("%HOSTS_FILE%") do (
    SET "LINE=%%L"
    if "!LINE:~0,1!"=="#" (
        SET /A SKIP_COMMENT+=1
    ) else (
        findstr /I /C:"  !LINE! " "%TMPFILE%" >nul 2>&1
        if !errorlevel! == 0 (
            echo   - !LINE!
            warp-cli tunnel host remove "!LINE!"
            if !errorlevel! == 0 (
                SET /A OK+=1
            ) else (
                SET /A FAIL+=1
            )
        ) else (
            echo   = !LINE!  [не найден, пропускаем]
            SET /A SKIP_EXISTS+=1
        )
    )
)

del "%TMPFILE%" >nul 2>&1
echo.
echo  Удалено: !OK!   Не было: !SKIP_EXISTS!   Ошибок: !FAIL!   Комментариев: !SKIP_COMMENT!
echo.
pause
goto menu

:do_list
cls
echo.
warp-cli tunnel host list
echo.
pause
goto menu

:show_file
cls
echo.
type "%HOSTS_FILE%"
echo.
pause
goto menu

:end
endlocal
exit /b 0
