#!/bin/bash

refreshPermissions() {
    local pid="${1}"

    while kill -0 "${pid}" 2>/dev/null; do
        sleep 10
    done
}

pgadmin() {
    echo '~~~~~~~~~ Pgadmin will be installed ~~~~~~~~~~'
    refreshPermissions "$$" & curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
    refreshPermissions "$$" & sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'
    refreshPermissions "$$" & sudo apt install pgadmin4-desktop
    # Install for web mode only:
    # sudo apt install pgadmin4-web
    # Configure the webserver, if you installed pgadmin4-web:
    # sudo /usr/pgadmin4/bin/setup-web.sh
}

anydesk() {
    echo '~~~~~~~~~~ Anydesk will be installed ~~~~~~~~~~~~~'
    refreshPermissions "$$" & wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo apt-key add -
    refreshPermissions "$$" & echo "deb http://deb.anydesk.com/ all main" > /etc/apt/sources.list.d/anydesk-stable.list
    refreshPermissions "$$" & sudo apt update
    refreshPermissions "$$" & sudo apt install anydesk
}

asbru() {
    echo '~~~~~~~~~~~ Asbru (SSH connection tool) will be installed ~~~~~~~~~~~~~~'
    refreshPermissions "$$" & sudo apt-add-repository multiverse
    refreshPermissions "$$" & sudo apt install -y curl
    refreshPermissions "$$" & curl -1sLf 'https://dl.cloudsmith.io/public/asbru-cm/release/cfg/setup/bash.deb.sh' | sudo -E bash
    refreshPermissions "$$" & sudo apt install asbru-cm
}

# User prompt
read -p $'1.Pgadmin\n2.anydesk\n3.asbru\n4.All\nSelect application you want to install from above list: ' input
if [[ "$input" = "Pgadmin" || "$input" = "1" ]]; then
    pgadmin
elif [[ "$input" = "anydesk" || "$input" = "2" ]]; then
    anydesk
elif [[ "$input" = "asbru" || "$input" = "3" ]]; then
    asbru
elif [[ "$input" = "All" || "$input" = "4" ]]; then
    echo '~~~~~~~~~~~ All tools will be installed ~~~~~~~~~~~~~~'
    pgadmin
    anydesk
    asbru
else
    echo 'Invalid input provided!, Please try again'
fi
