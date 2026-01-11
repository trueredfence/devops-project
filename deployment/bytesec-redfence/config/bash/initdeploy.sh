#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
echo "Starting Laravel production deployment inside Docker..."
# Run in background (fire and forget)
chmod +x ./deploy.sh
# nohup ./deploy.sh >/dev/null 2>&1 &

# Exit immediately without waiting
exit 0