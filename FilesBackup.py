import subprocess
import os
import datetime
import sys
import shutil
import logging

# Configure logging settings to log into txt file.
logging.basicConfig(filename='/path/to/log.txt', filemode='a', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
#replace the '/path/to/log.txt' with your actual path of where you want to store the log

# Checking the system storage to proceed for build backup process
storage = subprocess.run("df -h | grep '/dev/mapper/ubuntu--vg-ubuntu--lv' | awk '{print $5}'", shell=True, stdout=subprocess.PIPE, text=True, check=True)
storage_used = storage.stdout.strip().rstrip('%')
storage_int = int(storage_used)
#  set your prefered storage % when the script should start to back up the files.
if storage_int < 85:
    logging.info(f"\n+++++++++++++ New Log Started ++++++++++++")
    logging.info(f"Storage used: {storage.stdout.strip()}, System storage is at the acceptable limit.\nQuitting the process! Thank you!")
    logging.shutdown()
    sys.exit()
else:
    logging.info(f"\n+++++++++++++ New Log Started ++++++++++++")
    logging.info(f"Storage used: {storage.stdout.strip()} ---> system is close to storage exhaustion!\nRecommended to start Builds backup process has started...")

    # Checking whether network drive mapped/mounted on the system storage or not
    if os.path.exists("/path/to/mounted_folder"):
        logging.info("Network drive mapping available... Will proceed for builds backup process..")
    else:
        mount = 'sudo mount.cifs //<ip_addres_network_drive>/path/of/remote_folder /mnt/<mounted_folder>/ -o user=XXX,file_mode=0777,dir_mode=0777,credentials=/etc/samba/credentials'
        result = subprocess.run(f'{mount}'.format('testsim@123'), shell=True)
        if result.returncode == 0:
            logging.info("Network drive mapping available... Will proceed for builds backup process..")
        else:
            logging.error(f"Mount failed. Error message {result.stderr}")
            logging.shutdown()
            sys.exit()

    # Backup process from machine to network drive
    file_copy_dir = ['/path1/to/source_files/*  /path/to/destination_folder(mounted)/',
                     '/path2/to/source_files/*  /path/to/destination_folder(mounted)/']                                                                                     
    total_files = len(file_copy_dir)
    logging.info("******* Build copying process has started! ********")
    for index, copy in enumerate(file_copy_dir, start=1):
        logging.info(f"Copying the files of directory {index}/{total_files}...")
        output_result = subprocess.run(f'sudo cp -r {copy}'.format('testsim@123'), shell=True)
        if output_result.returncode == 0:
            logging.info(f"File {copy} Copied successfully.")
        else:
            logging.error(f"File transfer failed! Error Output:{output_result.stderr}")
            logging.shutdown()
            sys.exit()

    # Deletion process after backing up the builds from jenkins system             
    file_clean_dir = ['/path1/to/files_to_deleted/',
                      '/path2/to/files_to_deleted/']
    logging.info("****** Builds cleaning process has started! *******")
    for dir in file_clean_dir:
        if os.path.exists(dir): 
            # checking whether the file path inside is a directory or not and sorting each folder with date
            folders = [f for f in os.listdir(dir) if os.path.isdir(os.path.join(dir, f))]
            sorted_folders = sorted(folders, key=lambda f: os.path.getctime(os.path.join(dir, f)), reverse=True)
            folders_to_retain = sorted_folders[:5]
            for folder in folders:
                folder_path = os.path.join(dir, folder)
                if folder not in folders_to_retain:
                    delete_result = subprocess.run(f'sudo rm -r "{folder_path}"'.format('testsim@123'), shell=True)
                    if delete_result.returncode == 0:
                        logging.info(f"Folder removed successfully: {folder_path}.")
                    else:
                        logging.error(f"Failed to remove the folder: {folder_path}. Error code: {delete_result.stderr}")
                        logging.shutdown()
                        sys.exit()
        else:
            logging.error(f"Path:{dir} does not exists!")
            logging.shutdown()
            sys.exit()
    if dir == file_clean_dir[-1]:
        final_storage = subprocess.run("df -h | grep '/dev/mapper/ubuntu--vg-ubuntu--lv' | awk '{print $5}'", shell=True, stdout=subprocess.PIPE, text=True, check=True)
        # mnt_storage = subprocess.run("df -h | grep '//192.168.60.8/Builds/JenkinsBuildBackup' | awk '{print $5}'", shell=True, stdout=subprocess.PIPE, text=True, check=True)
        final_storage_used = final_storage.stdout.strip().rstrip('%')
        # mnt_storage_used = mnt_storage.stdout.strip().rstrip('%')
        logging.info("++++++++++++ Builds Backup process is successfully completed! Thank you! +++++++++++++")
        logging.info(f"Current Jenkins machine storage available:{final_storage_used}%")
        # logging.info(f"Network Drive storage available:{mnt_storage_used}%")
        logging.shutdown()
        sys.exit()
