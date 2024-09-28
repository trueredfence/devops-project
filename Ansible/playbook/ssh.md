# Variables

- role_path: "ssh"
  Current ansible role name this depend on the folder name if folder name of role is changed we have to chagne this role name to else not required
- new_key_name: "infra"
  When we create new user and want to add new ssh login for this user we need to give name of that key here don't required to .pub ssh key file location is on `ssh\files\*`
  Create new ssh key with `ssh-keygen -t ed25519 -f "./files/newkey" -N "" -C "changethis"`
- login_user_name: "root"
  Default user name for ansibel task is `root` which can be later bypass by add `--extra-vars "login_user_name=hunter"`

## Intial Tasks
- update_vps:false
  If true this will update vps except kernel. Use this in intial configuration.
- create_user: false
  This will create new user name hunter by default. This is normal user entry in sudoer file required password for sudo commands. This taks will generate auto password which will later save in password.csv file in current location. Password will also display in panel during installation.
- add_ssh_key: true
  This task to add new ssh key to authorize file in host vps
- harden_ssh: true
  This will copy current tempalte of sshd_config to vps change port and remove old ecryptions modules.
- change_password_current_user: false
  Change password of current ansible_user it will genreate random password and save in password.csv fie `Important default in intial time it will change root password`
- disable_root_ssh: true
  Disable root login root user can't ssh on this vps now. Also remove password base login for all users.
- disable_pass_login: true
  Disable login with password default it enable if set to true it will disable password based login to VPS.

## Commands

### Create hosts.ini files
[!important]
- Copy and paste ip port hunterpassword in vps_info.txt file
- run `./createinventory.py`
- type `yes` than vault password it will create hosts.ini file which will later use by ansible-playbook

### before cofigure or run with root

`sudo ansible-playbook pb.yml -i hosts.ini --extra-vars "my_hosts=infravps"`

### after configuration

`sudo ansible-playbook pb.yml -i hosts.ini --extra-vars "my_hosts=infravps login_user_name=hunter" --ask-vault-pass`


