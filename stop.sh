#!/bin/bash

############################################################

Help()
{
   # Display Help
   echo "Stop NGINX"
   echo
   echo "Syntax: ./stop.sh [dev]"
   echo
   echo "If 'dev' is not specified, this will stop nginx-certbot which is in production mode."
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

# if dev is specified, stop nginx-certbot in development mode
if [ "$1" == "dev" ]; then
    echo "Stopping nginx-certbot in development mode..."
    docker compose down
else
    echo "Stopping nginx-certbot in production mode..."
    docker compose -f compose.yaml -f compose.prod.yaml down
fi
