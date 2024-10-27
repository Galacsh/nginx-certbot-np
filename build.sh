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
#
# With Docker Desktop + "Use containerd for pulling and storing images" option enabled,
# we can use default builder to create multiplatform image.
docker build \
  --platform linux/arm64,linux/arm/v6,linux/amd64 \
  -t "$REPOSITORY:$VERSION" \
  -t "$REPOSITORY:latest" .

docker push "$REPOSITORY:$VERSION"
docker push "$REPOSITORY:latest"
