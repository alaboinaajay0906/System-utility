#intructions

1.Place the RM_online_install.zip file in home directory (recommended) and unzip it.

2.Make sure internet connection should be avialable

3.Transfer the new rmon bundle file into the "RM_online_install" drectory, if not some default(v189) file will be installed.

4.Run the shell script 'RMEYE_env_setup.sh' using bash e.g. bash RMEYE_env_setup.sh

5.After the installtion! Reboot the system 'sudo reboot -f'and check the installed services.

6.if any dependancy (e.g. postgres) not installed properly then run the script 'remove_all.sh' and run the 'RMEYE_env_setup.sh' again.

7.If you want to install anydesk, pgadmin and asbru then run additional_tools.sh



