#!/bin/bash

# Input files
input_file="input.txt"       # File containing IP addresses and their statuses
target_file="target_file.txt"  # File where we will update the IP information
query="failed=0"
# Temp file to hold intermediate results
temp_file=$(mktemp)

# Loop through each line in the input file
while IFS= read -r line; do
  # Extract the IP
  ip=$(echo "$line" | awk '{print $1}')
  
  # Check if the line contains "failed=0"
  if echo "$line" | grep -q $query; then
    # If failed=0 is found, do nothing and prepare to add IP info to the temp file
    echo "$ip ansible_port=1179 ansible_ssh_pass='[#ZDh73-)DOM6Fs4' ansible_become_pass='[#ZDh73-)DOM6Fs4'" >> "$temp_file"
  else
    # If failed=0 is not found, comment out the corresponding IP in the target file
    sed -i "/^$ip/s/^/;/" "$target_file"
  fi
done < "$input_file"

# Append the temp file contents to the target file
cat "$temp_file" >> "$target_file"

# Clean up the temp file
rm "$temp_file"

echo "Script completed successfully."
