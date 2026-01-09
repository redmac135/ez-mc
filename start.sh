#!/bin/bash
set -e

# Load .env variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found! Using defaults."
    MC_UID=${MC_UID:-1000}
    MC_GID=${MC_GID:-1000}
fi

# Make sure /data exists
mkdir -p ./data

# Fix ownership on host
echo "Setting ownership of ./data to UID:${MC_UID} GID:${MC_GID}..."
sudo chown -R ${MC_UID}:${MC_GID} ./data

# Build and start container
echo "Building and starting Docker Compose..."
docker compose up --build -d

echo "Minecraft server should be starting now!"

