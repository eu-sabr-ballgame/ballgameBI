:: Windows batch file
:: Git pull latest changes from Github repository
::
:: when       who         what
:: ---------- ----------- --------------------------------------------------------
:: 03/04/2024
:: 27/04/2024 Tony Pérez  git stash: discard changes (and store a record of them)
:: 05/05/2024 Tony Pérez  git reset: discard changes and throw away them
echo ==================================================================
echo Ballgame Metrics Statistics App
echo https://ballgamemetrics.com/
echo Github Refresh
echo %DATE% %TIME%
echo ==================================================================
echo.
(C: && cd c:\baseball\ballgameBI\ && git reset --hard && git.exe pull)
pause
