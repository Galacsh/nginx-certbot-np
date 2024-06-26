#!/bin/bash

############################################################

Help()
{
   # Display Help
   echo "Start nginx-certbot"
   echo
   echo "Syntax: ./start.sh [dev]"
   echo
   echo "If 'dev' is not specified, this will run nginx-certbot in production mode."
   echo
}

############################################################

# if $1 is not empty and not equal to 'dev' exit with error
if [ -n "$1" ] && [ "$1" != "dev" ]; then
    echo "Invalid argument: $1" >&2
    Help
    exit 1
fi

# Set current directory
DIR=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
cd "$DIR" || exit 1

# if dev is specified, run nginx-certbot in development mode
if [ "$1" == "dev" ]; then
    echo "Starting nginx-certbot in development mode..."
    docker compose up -d
else
    echo "Starting nginx-certbot in production mode..."
    docker compose -f compose.yaml -f compose.prod.yaml up -d
fi
