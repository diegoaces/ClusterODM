#!/bin/bash
# Author: Diego Acuña (Greenbot Labs)
# Description: This script updates the ClusterODM configuration files and restarts the Docker container.
# It prompts the user for paths to the configuration files, copies them into the project directory,
# updates the 'asr' property in config-default.json, and restarts the ClusterODM
# container to apply the new configuration.


# Usage: ./cluster.sh
# Note: Ensure you have jq installed for JSON manipulation.

read -p "Enter the path to config-default.json [default: ./config-default.json]: " CONFIG_PATH
CONFIG_PATH=${CONFIG_PATH:-./config-default.json}
read -p "Enter the path to the asr file: " ASR_PATH

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install jq to continue."
    exit 1
fi

# Copy the config file into the project directory (overwrite existing)
cp "$CONFIG_PATH" ./config-default.json
cp "$ASR_PATH" ./configuration.json

# Update the 'asr' property in config-default.json to point to configuration.json
jq --arg asr_path "configuration.json" '.asr = $asr_path' config-default.json > config-default.tmp && mv config-default.tmp config-default.json

echo "Recreating ClusterODM container with docker compose..."
docker compose up -d --force-recreate

# Get the container name for the ClusterODM service (assume service is named 'clusterodm' in docker-compose.yml)
CONTAINER_NAME=$(docker compose ps -q | head -n 1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "Could not find a running ClusterODM container."
    exit 1
fi

echo "Copying config files into the running container..."
docker cp ./config-default.json "$CONTAINER_NAME":/var/www/config-default.json
docker cp ./configuration.json "$CONTAINER_NAME":/var/www/configuration.json

echo "Restarting ClusterODM container to apply new configuration..."
docker restart "$CONTAINER_NAME"

echo "ClusterODM updated, config files copied, and container restarted."
