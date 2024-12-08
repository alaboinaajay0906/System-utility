#!/bin/bash

#Check the operating system before proceeding for deployement.
os_version=$(grep "DISTRIB_RELEASE" /etc/lsb-release | cut -d'=' -f2)
   #Change the version 20.04 as per rmeye platform supported OS version in future
   if [[ "$os_version" =~ ^20.04 ]]; then
       echo -e "\e[1;32mOS Version is eligible for deployement!\e[0m"
       cpu_info=$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)
       num_cores=$(lscpu | grep "^CPU(s):" | awk -F: '{print $2}' | xargs)
       ram_info=$(free -h | grep "Mem:" | awk '{print $2}')
       storage_info=$(df -h --total | grep "total" | awk '{print $2}')
       os_info=$(grep "DISTRIB_DESCRIPTION" /etc/lsb-release | cut -d'=' -f2 | tr -d '"')
    else
        echo -e "\e[1;31m OS Version is not compatable for deployement: $os_version \n \e[0m"
        exit 1
    fi
echo "1. OS Information: $os_info"
echo "2. CPU: $cpu_info"
echo "3. Number of Cores: $num_cores"
echo "4. RAM: $ram_info"
echo "5. Storage: $storage_info"

refreshPermissions () {
    local pid="${1}"

    while kill -0 "${pid}" 2> /dev/null; do
        sudo -v
        sleep 10
    done
}

# To check internet acess of the machine
ping -c 1 8.8.8.8 >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo -e "\e[1;32m ========== Internet Access avialable, will proceed for installation! ========\n \e[0m"
else
    echo -e "\e[1;31m ========== No internet Access, Please check the network settings! ============\n\e[0m"
    exit 1
fi

#Nginx
if command -v nginx &> /dev/null; then
  echo -e "\e[1;32m ==========Nginx already installed========== \n\e[0m"
else
  echo -e "\e[1;32m ==========Nginx installation started... ==========\e[0m"
  refreshPermissions "$$" & sudo apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
  refreshPermissions "$$" & curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg > /dev/null
  refreshPermissions "$$" & echo "deb [arch=amd64 signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
  refreshPermissions "$$" & echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 1000" | sudo tee /etc/apt/preferences.d/99nginx
  refreshPermissions "$$" & sudo apt update
  refreshPermissions "$$" & sudo apt install -y nginx
  if command -v nginx &> /dev/null; then
    echo -e "\e[1;32m ==========Nginx installed successfully==========\n \e[0m"
    #copying the configuration files
    echo -e "\e[1;32m ******** Copying the nginx configuration files! ********\n \e[0m"
    refreshPermissions "$$" & sudo cp default.conf /etc/nginx/conf.d/ || { echo -e "\e[1;32mError:Copying default.conf failed.\n \e[0m"; exit 1; }
    refreshPermissions "$$" & sudo cp default /etc/nginx/sites-enabled/
    refreshPermissions "$$" & sudo cp nginx.conf /etc/nginx/ || { echo -e "\e[1;32mError:Copying nginx.conf failed.\n \e[0m"; exit 1; }
  else
    echo -e "\e[1;31m ========== Nginx installation failed! ==========\n \e[0m"
    exit 1
  fi
fi

# Dotnet

DotnetcheckAndInstallDotnet() {
    local version=$1

    if dotnet --list-runtimes | grep -q "${version}"; then
        echo -e "\e[1;32m .NET version ${version} is already installed.\e[0m"
    else
        echo -e "\e[1;33m .NET version ${version} is not installed. Installing...\e[0m"
        refreshPermissions "$$" & sudo apt-get install -y dotnet-sdk-${version}
    fi
}

main() {
    # Function to check and install .NET SDKs
    if dotnet --list-runtimes | grep -q "5.0" || dotnet --list-runtimes | grep -q "6.0" || dotnet --list-runtimes | grep -q "8.0"; then
        echo -e "\e[1;32m ========== At least one of the required .NET versions (5.0, 6.0, or 8.0) is installed! ==========\n \e[0m"
    else
        echo -e "\e[1;31m ========== Dotnet versions are not installed, Proceeding for installation... ==========\n \e[0m"

        # Check and install the Microsoft packages if they are not already there
        if ! dpkg -l | grep -q "packages-microsoft-prod"; then
            refreshPermissions "$$" & sudo wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            refreshPermissions "$$" & sudo apt-get update
            refreshPermissions "$$" & sudo dpkg -i packages-microsoft-prod.deb
        else
            echo -e "\e[1;32m ========== Microsoft packages are already installed. ==========\n \e[0m"
        fi
    fi

    # Check and install .NET SDK versions
    echo -e "\e[1;32m ========== Checking .NET versions... ==========\n\e[0m"
    checkAndInstallDotnet "5.0"
    checkAndInstallDotnet "6.0"
    checkAndInstallDotnet "8.0"

    # Final check to see if all versions are installed
    if dotnet --list-runtimes | grep -q "5.0" && dotnet --list-runtimes | grep -q "6.0" && dotnet --list-runtimes | grep -q "8.0"; then
        echo -e "\e[1;32m ========== All required .NET versions (5.0, 6.0, 8.0) are installed successfully! ==========\n \e[0m"
    else
        echo -e "\e[1;31m ========== One or more required .NET versions are still missing! We will keep trying....  ==========\n \e[0m"
        if ping -c 1 8.8.8.8 &> /dev/null; then
            echo -e "\e[1;32m Internet connection is active.\e[0m"
            main 
        else
            echo -e "\e[1;31m No internet connection. Exiting...\e[0m"
            exit 1
        fi
    fi
}
# Call the main function to start the script
main

#Postgres
if psql -V | grep "13";then
  echo -e "\e[1;32m ==========Postgresql already installed========== \e[0m"
else
  echo -e "\e[1;32m ==========Postgresql installation started... ========== \e[0m"
  refreshPermissions "$$" & sudo apt update
  refreshPermissions "$$" & sudo apt upgrade -y
  refreshPermissions "$$" & sudo apt install gnupg postgresql-common apt-transport-https lsb-release wget
  refreshPermissions "$$" & sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
  refreshPermissions "$$" & sudo echo "deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main" | sudo tee /etc/apt/sources.list.d/timescaledb.list
  refreshPermissions "$$" & wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -
  refreshPermissions "$$" & sudo apt update
  refreshPermissions "$$" & sudo apt-get install timescaledb-2-postgresql-13='2.5.0*' timescaledb-2-loader-postgresql-13='2.5.0*'
  if command -v psql &> /dev/null; then
    echo -e "\e[1;32m ========== Postgresql installed successfully, setting up configuration==========\n \e[0m"
    echo -e "\e[1;32m ******** Setting up configuration! ********\n \e[0m"
    refreshPermissions "$$" & sudo sed -i "s/#shared_preload_libraries.*/shared_preload_libraries = \'timescaledb\'/g" /etc/postgresql/13/main/postgresql.conf
    refreshPermissions "$$" & sudo sed -i "s/#listen_addresses.*/listen_addresses = \'*\'/g" /etc/postgresql/13/main/postgresql.conf
    refreshPermissions "$$" & sudo sed -i '/^local.*peer/s/peer/trust/g' /etc/postgresql/13/main/pg_hba.conf
    refreshPermissions "$$" & sudo sed -i '/^host[[:space:]]*all[[:space:]]*all[[:space:]]*127\.0\.0\.1\/32/s/127\.0\.0\.1\/32/0.0.0.0\/0/' /etc/postgresql/13/main/pg_hba.conf
    refreshPermissions "$$" & sudo service postgresql restart
    # checking for psql client connection
    if sudo -u postgres psql -c "SELECT 1;" &> /dev/null; then
       echo -e "\e[1;32m ========== psql client connection to postgres server success!, can proceed for psql commands ==========\n \e[0m"
       refreshPermissions "$$" & sudo -S -u postgres psql -c "alter user postgres with encrypted password 'hotandcold'"
    else
       echo -e "\e[1;31m ========== psql client connection failed! check the configuration (e.g.postgresql.conf/pg_hba.conf) ==========\n \e[0m"
       exit 1
    fi
    # creating user,database rmdb and timescaledb extension
    echo "+++++++++++ Creating a User rmtest ++++++++++"
    refreshPermissions "$$" & sudo -S -u postgres psql -c "create user rmtest with encrypted password 'hotandcold'"
    refreshPermissions "$$" & sudo -S -u postgres psql -c "CREATE ROLE rmtest WITH LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD 'hotandcold'"
    echo "+++++++++++ Creating a test database rmdb ++++++++++"
    refreshPermissions "$$" & sudo -S -u postgres psql -c "CREATE DATABASE rmdb WITH OWNER rmtest"
    echo "+++++++++++ adding extention timescaledb ++++++++++"
    refreshPermissions "$$" & sudo -S -u postgres psql -d rmdb -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
    # install and configure pgagent
    refreshPermissions "$$" & sudo apt-get update
    refreshPermissions "$$" & sudo apt-get install -y pgagent
    refreshPermissions "$$" & sudo -S -u postgres psql -c " CREATE EXTENSION IF NOT EXISTS pgagent"
    refreshPermissions "$$" & sudo -S -u postgres psql -c " CREATE LANGUAGE plpgsql"
    refreshPermissions "$$" & sudo sed -i '/^local.*trust/s/trust/md5/g' /etc/postgresql/13/main/pg_hba.conf
    refreshPermissions "$$" & touch ~/.pgpass
    refreshPermissions "$$" & chmod 600 ~/.pgpass
    refreshPermissions "$$" & echo "127.0.0.1:5432:*:postgres:hotandcold" >> ~/.pgpass
    refreshPermissions "$$" & PGPASSFILE=~/.pgpass
    # to start the pgagent service and settingup log files
    refreshPermissions "$$" & pgagent hostaddr=127.0.0.1 port=5432 dbname=postgres user=postgres
    refreshPermissions "$$" & sudo chown postgres:postgres /var/lib/
    refreshPermissions "$$" & sudo mkdir /var/log/pgagent
    refreshPermissions "$$" & sudo chown -R postgres:postgres /var/log/pgagent
    refreshPermissions "$$" & sudo chmod g+w /var/log/pgagent
    refreshPermissions "$$" & sudo service postgresql restart
    echo "@reboot pgagent hostaddr=127.0.0.1 port=5432 dbname=postgres user=postgres
@reboot ~/gw-rmon/bins/watchdog-rmon > /dev/null 2>&1 &" | crontab -
    else
       echo -e "\e[1;31m ========== Postgresql installation failed! ==========\n \e[0m"
       exit 1
  fi
fi

#Node.js
if command -v node &> /dev/null; then
  echo -e "\e[1;32m ========== Node.js already installed========== \e[0m"
else
  echo -e "\e[1;32m ========== Node.js installation started... ========== \e[0m"
  refreshPermissions "$$" & sudo apt update
  # downloading debian files from web
  refreshPermissions "$$" & curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
  refreshPermissions "$$" & sudo bash nodesource_setup.sh
  refreshPermissions "$$" & sudo apt update
  refreshPermissions "$$" & sudo apt install nodejs
  if command -v node &> /dev/null; then
    echo -e "\e[1;32m ==========Node.js installed successfully==========\n \e[0m"
    refreshPermissions "$$" & node -v
  else
    echo -e "\e[1;31m ==========Node.js not installed ==========\n \e[0m"
    exit 1
  fi
fi

#RMON Gateway Software Installation
if [ -f ~/gw-rmon/bins/watchdog-rmon ]; then
  ver=$(~/gw-rmon/bins/vers-rmon)
  echo -e "\e[1;32m ==========RM Gateway Software Version $ver already installed========== \e[0m"
  if ps ax | pgrep watchdog-rmon ;then
    echo -e "\e[1;32m ==========Watchdog-rmon is running========== \e[0m"
  else
    echo -e "\e[1;31m ==========Watchdog-rmon is not running========== \e[0m"
  fi
else
  mkdir ~/rmontmp
  bundle="$( ls -t v*.tar.gz | head -n1)"
  tar xvf "$bundle" -C ~/rmontmp/
  refreshPermissions "$$" & sudo ~/rmontmp/./install-rmon.sh
fi

#Reports configuration
#refreshPermissions "$$" & sudo mkdir -p /home/$USER/eyedev/eye/reports
#refreshPermissions "$$" & sudo chown -R $USER:$USER /home/$USER/eyedev/eye/reports
#refreshPermissions "$$" & sudo chmod -R 777 /home/$USER/eyedev/eye/reports

#additional libraries
refreshPermissions "$$" & sudo apt-get update && \
sudo apt-get install -y \
ca-certificates \
fonts-liberation \
libappindicator3-1 \
libasound2 \
libatk-bridge2.0-0 \
libatk1.0-0 \
libc6 \
libcairo2 \
libcups2 \
libdbus-1-3 \
libexpat1 \
libfontconfig1 \
libgbm1 \
libgcc1 \
libglib2.0-0 \
libgtk-3-0 \
libnspr4 \
libnss3 \
libpango-1.0-0 \
libpangocairo-1.0-0 \
libstdc++6 \
libx11-6 \
libx11-xcb1 \
libxcb1 \
libxcomposite1 \
libxcursor1 \
libxdamage1 \
libxext6 \
libxfixes3 \
libxi6 \
libxrandr2 \
libxrender1 \
libxss1 \
libxtst6 \
lsb-release
#updating npm packages
# refreshPermissions "$$" & sudo npm i --save  --force /srv/eye-reports-ui/
#refreshPermissions "$$" & sudo sudo service kestrel-eyereport restart
echo -e "\e[1;34;1m ::::::::---:::::::-----> Web Application env setup completed successfully! <------::::::::---:::::::\n \e[0m"
echo -e "\e[1;32m ========== kindly requested to update the status into checklist excel, if this is customer deployement! ==========\n \e[0m"
