#!/bin/bash

# Ballgame Metrics Statistics App
# https://ballgamemetrics.com/
# MacOS Bash script to get the latest application version from Github
# This could be included in a cron job
# Caveat: any change on the application will be discarded.
# when        who                   what
# ----------  --------------------  ---------------------------------
# 11/05/2024  Tony Pérez            initial

current_datetime=$(date +"%Y-%m-%d %H:%M:%S")
echo " "
echo "==================================================================================="
echo "WBSC Europe Baseball and Softball Sabermetrics Statistics App"
echo "Github Refresh"
echo "Date/Time: $current_datetime"
echo "==================================================================================="
echo " "
cd ~/baseball/ballgameBI/
git reset --hard
git pull
