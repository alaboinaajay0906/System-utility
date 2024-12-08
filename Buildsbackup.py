import subprocess
import os
import sys
import logging

# Configure logging settings to log into a text file.
logging.basicConfig(filename='/home/sindhu67/jenkinslog.txt', filemode='a', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Check the system storage
storage = subprocess.run("df -h | grep '/dev/mapper/ubuntu--vg-ubuntu--lv' | awk '{print $5}'", shell=True, stdout=subprocess.PIPE, text=True, check=True)
storage_used = storage.stdout.strip().rstrip('%')
storage_int = int(storage_used)
logging.info("Version info: v0.5.24, Release date:2024-11-22")

# Storage check before proceed
if storage_int < 80:
    logging.info(f"\n+++++++++++++ New Log Started ++++++++++++")
    logging.info(f"Storage used: {storage.stdout.strip()}, System storage is at the acceptable limit.\nQuitting the process! Thank you!")
    logging.shutdown()
    sys.exit()
else:
    logging.info(f"\n+++++++++++++ New Log Started ++++++++++++")
    logging.info(f"Storage used: {storage.stdout.strip()} ---> system is close to storage exhaustion!Recommended to start Builds backup process has started...")

    # Check if the network drive is mapped
    if os.path.exists("/mnt/backup_dir/RIL"):
        logging.info("Network drive mapping available... Will proceed for builds backup process..")
    else:
        mount = 'sudo mount.cifs //192.168.60.8/Builds/JenkinsBuildBackup /mnt/backup_dir/ -o user=schintallanka,file_mode=0777,dir_mode=0777,credentials=/etc/samba/credentials'
        result = subprocess.run(f'{mount}', shell=True)
        if result.returncode == 0:
            logging.info("Network drive mapping available... Will proceed for builds backup process..")
        else:
            logging.error(f"Mount failed. Error message {result.stderr}")
            logging.info("+++++++++Quitting the process+++++++++")
            logging.shutdown()
            sys.exit()

# Directories to skip for backup, this wil be used to configure in future
skip_dirs = {"<pipeline1>","<pipeline2>"}

# Backup paths
jenkins_jobs_dir = '/var/lib/jenkins/jobs/'
backup_base_dir = '/mnt/backup_dir/'

# Lists to hold paths and names of pipelines
copy_path = []
pipelines_deletion = []
new_pipelines = []

# Path making process
for pipe_line in os.listdir(jenkins_jobs_dir):
        # Now check if the modified pipeline name is in the skip_dirs list
    if pipe_line in skip_dirs:
        logging.info("Pipelines we are skipping to backup: %s", pipe_line)
        continue
    # if any pipeline name contains spaces Replace it with underscores
    if " " in pipe_line:
        modified_pipeline_name = pipe_line.replace(" ", "_")
        modified_path = os.path.join(jenkins_jobs_dir, modified_pipeline_name)
        pipe_line_path = os.path.join(jenkins_jobs_dir, pipe_line)
        logging.info("Spaces found in pipeline name, we are removing spaces")
        try:
           command = ["mv", pipe_line_path, modified_path]
           subprocess.run(command, check=True)
           modified_pipeline_name = pipe_line
        except subprocess.CalledProcessError:
           logging.info(f"Error: Failed to rename '{pipe_line}' to '{modified_pipeline_name}'")
           logging.info("+++++++++Quitting the process+++++++++")
           logging.shutdown()
           sys.exit()

    source_path = os.path.join(jenkins_jobs_dir, pipe_line, 'builds')
    destination_path = os.path.join(backup_base_dir, pipe_line.replace(' ', '_'))

    # If a new pipeline is detected, add it to new_pipelines list
    if not os.path.exists(destination_path):
        subprocess.run(f'sudo mkdir -p {destination_path}', shell=True)
        new_pipelines.append(pipe_line)

    # Append paths for backup and deletion
    copy_path.append(f'{source_path}/* {destination_path}')
    pipelines_deletion.append(f'{source_path}')

# Logging info for new piprline detection.
logging.info("List of new pipelines: %s", new_pipelines)

# BACKUP PROCESS
logging.info("******* Build copying process has started! ********")
total_files = len(copy_path)
for index, copy in enumerate(copy_path, start=1):
    logging.info(f"Copying the files of directory {index}/{total_files}...")
    output_result = subprocess.run(f'sudo cp -r {copy}', shell=True)
    if output_result.returncode == 0:
        logging.info(f"File {copy} copied successfully.")
    else:
        logging.error(f"File transfer failed! Error Output: {output_result.stderr}")
        logging.info("+++++++++Quitting the process+++++++++")
        logging.shutdown()
        sys.exit()
    
    # DELETION PROCESS
    logging.info("****** Builds cleaning process has started! *******")
    for dir in pipelines_deletion:
        if os.path.exists(dir): 
            # checking whether the file path inside is a directory or not and sorting each folder with date
            folders = [f for f in os.listdir(dir) if os.path.isdir(os.path.join(dir, f))]
            sorted_folders = sorted(folders, key=lambda f: os.path.getctime(os.path.join(dir, f)), reverse=True)
            folders_to_retain = sorted_folders[:3]
            for folder in folders:
                folder_path = os.path.join(dir, folder)
                if folder not in folders_to_retain:
                    delete_result = subprocess.run(f'sudo rm -r "{folder_path}"', shell=True)
                    if delete_result.returncode == 0:
                        logging.info(f"Folder removed successfully: {folder_path}.")
                    else:
                        logging.error(f"Failed to remove the folder: {folder_path}. Error code: {delete_result.stderr}")
                        logging.info("+++++++++Quitting the process+++++++++")
                        logging.shutdown()
                        sys.exit()
        else:
            logging.error(f"Path:{dir} does not exists!")
            logging.info("+++++++++Quitting the process+++++++++")
            logging.shutdown()
            sys.exit()
    if dir == pipelines_deletion[-1]:
       final_storage = subprocess.run("df -h | grep '/dev/mapper/ubuntu--vg-ubuntu--lv' | awk '{print $5}'", shell=True, stdout=subprocess.PIPE, text=True, check=True)
       mnt_storage = subprocess.run("df -h | grep '//192.168.60.8/Builds/JenkinsBuildBackup' | awk '{print $5}'", shell=True, stdout=subprocess.PIPE, text=True, check=True)
       final_storage_used = final_storage.stdout.strip().rstrip('%')
       mnt_storage_used = mnt_storage.stdout.strip().rstrip('%')
       logging.info("++++++++++++ Builds Backup process is successfully completed! Thank you! +++++++++++++")
       logging.info(f"Current Jenkins machine storage consumed:{final_storage_used}%")
       logging.info(f"Network Drive storage Consumed:{mnt_storage_used}%")
       logging.shutdown()