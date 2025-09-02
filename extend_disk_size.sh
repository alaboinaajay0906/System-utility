#!/bin/bash

set -e

total_size=$(lsblk -b -d -o NAME,SIZE | grep sda | awk '{printf "%.0fGB\n", $2/1024/1024/1024}')
echo -e "\e[1;34m Total Disk zise $total_size\e[0m"

echo -e "\e[1;34mChecking filesystem type...\e[0m"
FS_TYPE=$(df -T / | awk 'NR==2 {print $2}')
LV_PATH=$(df -h / | awk 'NR==2 {print $1}')

echo -e "\e[1;34mDetected root filesystem type: $FS_TYPE\e[0m"
echo -e "\e[1;34mLogical Volume: $LV_PATH\e[0m"

# Confirm operation
read -p "This will extend $LV_PATH using all available free space. Proceed? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo -e "\e[1;33mAborted by user.\e[0m"
  exit 1
fi

# Check if lvm2 is installed
if ! dpkg -s lvm2 &> /dev/null; then
    echo -e "\e[1;33mlvm2 not found. Installing...\e[0m"
    sudo apt update
    sudo apt install -y lvm2
fi

echo -e "\e[1;34mExtending Logical Volume...\e[0m"
sudo lvextend -l +100%FREE "$LV_PATH"

if [[ "$FS_TYPE" == "ext4" ]]; then
  sudo resize2fs "$LV_PATH"
elif [[ "$FS_TYPE" == "xfs" ]]; then
  sudo xfs_growfs /
else
  echo -e "\e[1;31mUnsupported filesystem type: $FS_TYPE\e[0m"
  exit 1
fi

echo -e "\e[1;32m Disk successfully extended!\e[0m"
df -h /
