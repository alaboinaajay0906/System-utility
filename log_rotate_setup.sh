#!/bin/bash

total_size=$(lsblk -b -d -o NAME,SIZE | grep sda | awk '{printf "%.0fGB\n", $2/1024/1024/1024}')
echo -e "\e[1;34m Total Disk zise $total_size\e[0m"

# List of services 
echo "List of services that filling the syslogs"
awk '{print $5}' /var/log/syslog | cut -d':' -f1 | sort | uniq -c | sort -nr | head

# Remove old rotated syslog files
echo "Cleaning up exsisting syslog files ..."
sudo rm -f /var/log/syslog*

# log config paths
JOURNALD_CONF="/etc/systemd/journald.conf"
RSYSLOG_CONF="/etc/logrotate.d/rsyslog"

# Get total disk size in GB
disk_gb=$(df -h / | awk 'NR==2 {print $2}' | sed 's/[A-Za-z]//g')

# Recommend log sizes based on disk size
if (( disk_gb <= 100 )); then
  recommended_sysmaxuse="1G"
  recommended_rsyslog="200M"

elif (( disk_gb <= 500 )); then
  recommended_sysmaxuse="2G"
  recommended_rsyslog="400M"

elif (( disk_gb <= 1000 )); then
  recommended_sysmaxuse="3G"
  recommended_rsyslog="800M"

else
  recommended_sysmaxuse="4G"
  recommended_rsyslog="1024M"
fi

echo "Detected total disk size: ${disk_gb}G"
echo "Applying system max size for jouranald: $recommended_sysmaxuse"
echo "Applying log size rotation: $recommended_rsyslog"

# Prompt user to accept or override
# read -rp "Enter log rotation size [default: $recommended_sysmaxuse]: " log_size
# log_size="${log_size:-$recommended}"

# Convert G to MB for rsyslog (e.g., 2G → 2048MB)
# if [[ $log_size =~ ^([0-9]+)G$ ]]; then
#   size_num="${BASH_REMATCH[1]}"
#   log_size_mb="$((size_num * 1024))M"
# else
#   log_size_mb="$log_size"
# fi

# echo "Applying log rotation size: $log_size_mb"

# --- systemd-journald config ---
if grep -q "SystemMaxUse=" "$JOURNALD_CONF"; then
  sudo sed -i "/SystemMaxUse=/c SystemMaxUse=$recommended_sysmaxuse" "$JOURNALD_CONF"
else
  echo "SystemMaxUse=$recommended_sysmaxuse" | sudo tee -a "$JOURNALD_CONF" > /dev/null
fi

# restart the jourald service
sudo systemctl restart systemd-journald
echo "Updated journald.conf with SystemMaxUse=$recommended_sysmaxuse"

# --- rsyslog logrotate config ---
if grep -q "size" "$RSYSLOG_CONF"; then
  sudo sed -i "s/size .*/size $recommended_rsyslog/" "$RSYSLOG_CONF"
else
  sudo sed -i "/{/a \    size $recommended_rsyslog" "$RSYSLOG_CONF"
fi

# restart the rsyslog rotation
sudo systemctl restart rsyslog

echo "Updated rsyslog logrotate with size $recommended_rsyslog"
echo "Log rotation setup complete."
