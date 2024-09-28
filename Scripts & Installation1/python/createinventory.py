#!/usr/bin/env python3
import os
import subprocess

def create_ansible_inventory(input_file, output_file):
    with open(input_file, 'r') as file:
        lines = file.readlines()
    
    with open(output_file, 'w') as file:
        file.write("[all:vars]\n")
        file.write("ansible_ssh_common_args='-o StrictHostKeyChecking=no'\n")
        file.write("\n")
        file.write("[allvps]\n")
        for line in lines:
            parts = line.strip().split()
            if len(parts) != 3:
                print(f"Invalid line format: {line}")
                continue
            
            ip = parts[0]
            port = parts[1]
            sudo_pass = parts[2]
            
            file.write(f"{ip} ansible_port={port} ansible_ssh_pass='{sudo_pass}' ansible_become_pass='{sudo_pass}'\n")

def encrypt_file(file_path):
    encrypt = input("Do you want to encrypt the inventory file with Ansible Vault? (yes/y/no/n): ").strip().lower()
    if encrypt == 'yes' or encrypt == 'y':
        vault_password = input("Enter vault password: ").strip()
        confirmation_password = input("Confirm vault password: ").strip()
        
        if vault_password != confirmation_password:
            print("Passwords do not match. Exiting without encryption.")
            return
        
        # Create a temporary password file
        with open("vault_pass.txt", "w") as pass_file:
            pass_file.write(vault_password)
        
        try:
            subprocess.run(['ansible-vault', 'encrypt', file_path, '--vault-password-file', 'vault_pass.txt'], check=True)
            print(f"Inventory file '{file_path}' encrypted successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Failed to encrypt the file: {e}")
        finally:
            # Remove the temporary password file
            os.remove("vault_pass.txt")
    else:
        print("Exiting without encryption.")

if __name__ == "__main__":
    input_file = "vps_info.txt"
    output_file = "hosts.ini"
    create_ansible_inventory(input_file, output_file)
    print(f"Ansible inventory file '{output_file}' created successfully.")
    encrypt_file(output_file)
    with open("vps_info.txt", 'w') as file:
        file.write("")