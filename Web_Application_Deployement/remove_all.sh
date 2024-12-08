#!/bin/bash

refreshPermissions () {
    local pid="${1}"

    while kill -0 "${pid}" 2> /dev/null; do
        sudo -v
        sleep 10
    done
}

postgres() {
    refreshPermissions "$$" & sudo systemctl stop postgresql
    refreshPermissions "$$" & sudo apt-get purge postgresql-13 postgresql-client-13 postgresql-client-common postgresql-common
    refreshPermissions "$$" & sudo apt-get purge timescaledb-postgresql-13
    refreshPermissions "$$" & sudo apt-get purge pgagent
    refreshPermissions "$$" & sudo rm -r ~/.pgpass
    refreshPermissions "$$" & sudo rm -r /etc/timescaledb 
    refreshPermissions "$$" & sudo rm -r /var/log/pgagent
    refreshPermissions "$$" & sudo apt-get update
    refreshPermissions "$$" & sudo apt-get autoremove
    sleep 5s
    if command -v psql &> /dev/null; then
        echo -e "\e[1;31m ========== Failed to remove Postgres ========== \e[0m"
    else 
        echo -e "\e[1;32m ========== Postgres Removed! ========== \e[0m" 
        refreshPermissions "$$" & crontab -l | grep -v "@reboot pgagent hostaddr=127.0.0.1 port=5432 dbname=postgres user=postgres" | grep -v "@reboot ~/gw-rmon/bins/watchdog-rmon > /dev/null 2>&1 &" | crontab -
    fi
}

dotnet() {
    refreshPermissions "$$" & dotnet --list-sdks | awk '/^[0-9]/ {print $1}' | sed 's/^/dotnet-sdk-/' | xargs sudo apt-get remove --purge -y
    refreshPermissions "$$" & dotnet --list-runtimes | awk '/^[0-9]/ {print $1}' | sed 's/^/aspnetcore-runtime-/' | xargs sudo apt-get remove --purge -y
    sleep 5s
    if command -v dotnet &> /dev/null; then
        echo -e "\e[1;31m ========== Failed to remove Dotnet ========== \e[0m"
    else 
        echo -e "\e[1;32m ========== Dotnet Removed! ========== \e[0m" 
    fi
}

nginx() {
    refreshPermissions "$$" & sudo systemctl stop nginx
    refreshPermissions "$$" & sudo apt-get purge nginx
    sleep 5s
    if command -v nginx &> /dev/null; then
        echo -e "\e[1;31m ========== Failed to remove Nginx ========== \e[0m"
    else 
        echo -e "\e[1;32m ========== Nginx Removed! ========== \e[0m"
    fi
}

node() {
    refreshPermissions "$$" & sudo apt-get purge nodejs npm
    sleep 5s
    if command -v node &> /dev/null; then
        echo -e "\e[1;31m ========== Failed to remove Node.js ========== \e[0m"
    else 
        echo -e "\e[1;32m ========== Node.js Removed! ========== \e[0m"
    fi
}

# User prompt
read -p $'1. postgres\n2. Dotnet\n3. Nginx\n4. Nodejs\nSelect dependency you want to remove from the above list: ' input
if [[ "$input" == "1" ]]; then 
    postgres
elif [[ "$input" == "2" ]]; then
    dotnet
elif [[ "$input" == "3" ]]; then
    nginx
elif [[ "$input" == "4" ]]; then
    node
else
    echo 'Invalid input given, try again'
fi
