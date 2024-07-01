#!/bin/bash

set -e

############################################################

# Set current directory
DIR=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
cd "$DIR" || exit 1

REPOSITORY=galacsh/nginx-certbot-np

# Parse version from git commit message.
# For example, if the commit message is "v1.2.3", the version is "1.2.3"
VERSION=$(git log -1 --pretty=%B | sed -n 's/^.*v\([0-9.]*\).*$/\1/p')

if [ -z "$VERSION" ]; then
  echo "Version not found in git commit message."
  exit 1
fi

# Build image and tag with version and latest
# Supports: linux/arm/v6, linux/amd64

# Create builder if not exists
if ! docker buildx inspect nginx-certbot-np-builder &>/dev/null; then
  docker buildx create --name nginx-certbot-np-builder
fi

docker buildx build --push --builder nginx-certbot-np-builder --platform linux/arm/v6,linux/amd64 -t "$REPOSITORY:$VERSION" -t "$REPOSITORY:latest" .
