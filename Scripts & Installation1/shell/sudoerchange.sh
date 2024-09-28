#!/bin/bash
# With Root user
# ssh root@84.252.95.249 -p 22 'sudo bash -s' < install-wireguard-c7.sh
# With non-root user
# (echo "3i1_S!H+3Y7+3]y$"; cat sudoerchange.sh) | ssh infra@80.209.227.207 -p 1179 -i ../../ansible/playbook/ssh/files/infra "sudo -Sp '' bash  -s" 
# Or
# (echo "dUG!6Mn5zt5i__C_"; cat sudoerchange.sh) | ssh -tt hunter@hunter@84.252.95.249 "sudo bash -s"
# File to modify
sudoers_file="/etc/sudoers"

# Patterns to check and add
pattern_remove="hunter ALL=(ALL) ALL"
pattern_add_1="hunter ALL=(ALL) NOPASSWD: /usr/bin/systemctl start httpd, /usr/bin/systemctl stop httpd, /usr/bin/systemctl restart httpd"
pattern_add_2="hunter ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mysqld, /usr/bin/systemctl stop mysqld, /usr/bin/systemctl restart mysqld"
pattern_check_add="infra ALL=(ALL) NOPASSWD: ALL"

# Create a backup of the sudoers file
sudo cp $sudoers_file ${sudoers_file}.bak

# Remove the first pattern
sudo sed -i "/^${pattern_remove}$/d" $sudoers_file

# Add the first pattern if it doesn't exist
grep -qxF "$pattern_add_1" $sudoers_file || echo "$pattern_add_1" | sudo tee -a $sudoers_file

# Add the second pattern if it doesn't exist
grep -qxF "$pattern_add_2" $sudoers_file || echo "$pattern_add_2" | sudo tee -a $sudoers_file

# Check and add the third pattern if it doesn't exist
grep -qxF "$pattern_check_add" $sudoers_file || echo "$pattern_check_add" | sudo tee -a $sudoers_file

echo "Modifications applied to the sudoers file."
