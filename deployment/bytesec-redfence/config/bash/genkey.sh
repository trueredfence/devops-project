#!/bin/bash
# Generate ssh key for gitaction on remote vps and later use in GitAction
# Step 1: Generate SSH key pair
# Step 2: Copy the public key to the remote server
# Step 3: Add the private key to the GitAction workflow

# Generate SSH key pair
ssh-keygen -t ed25519 -C "github-actions" -f ./id_ed25519_github_actions
cat ./id_ed25519_github_actions.pub >> ~/.ssh/authorized_keys   
chmod 600 ~/.ssh/authorized_keys

