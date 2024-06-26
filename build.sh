#!/bin/bash

############################################################

Help()
{
   # Display Help
   echo "Build nginx-certbot"
   echo
   echo "Syntax: ./build.sh [dev]"
   echo
   echo "If 'dev' is not specified, this will build image in production mode."
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

# if dev is specified, build nginx-certbot in development mode
if [ "$1" == "dev" ]; then
    echo "Building nginx-certbot in development mode..."
    docker compose build
else
    echo "Starting nginx-certbot in production mode..."
    docker compose -f compose.yaml -f compose.prod.yaml build
fi
