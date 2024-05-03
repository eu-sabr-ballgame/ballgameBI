:: Windows batch file
:: Git pull latest changes from Github repository
:: 03/04/2024

(C: && cd c:\baseball\ballgame\ballgameBI\ && git.exe stash && git.exe pull)
pause

:: to run this from a scheduled task with output
:: appended to a text file enter this in the task
:: action /C c:\ballgame\gitpull.bat >> c:\ballgame\gitpull.output.txt 2>&1
:: put the pause command in comments if scheduling this script.
