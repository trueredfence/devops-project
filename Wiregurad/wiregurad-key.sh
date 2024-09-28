#!/bin/bash

# Check if a number of pairs was provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <number_of_pairs>"
    exit 1
fi

# Number of key pairs to generate
NUM_PAIRS=$1

# Check if the provided number is a positive integer
if ! [[ "$NUM_PAIRS" =~ ^[0-9]+$ ]] || [ "$NUM_PAIRS" -le 0 ]; then
    echo "Error: The number of pairs must be a positive integer."
    exit 1
fi

# Directory to store the keys
KEY_DIR="wireguard_keys"

# Create the directory if it doesn't exist
mkdir -p "$KEY_DIR"

# Generate key pairs
for i in $(seq 1 "$NUM_PAIRS"); do
    echo "Generating keys for pair $i..."

    # Generate server and client keys
    wg genkey | tee "$KEY_DIR/$i.key" | wg pubkey > "$KEY_DIR/$i.pub"
    
    echo "Keys for pair $i created:"
    echo "  $KEY_DIR/$i.key"
    echo "  $KEY_DIR/$i.pub"
done

echo "Key generation complete."
