# nginx with Certbot with non-privileged user

This repository creates a Docker image for a nginx server with Certbot.
All the processes are run as a non-privileged user (`nginx`).

The image is based on the official nginx non-privileged image, `nginxinc/nginx-unprivileged`.
During the build process, the Certbot is installed and the necessary scripts are added to the image.

## Image

[galacsh/nginx-certbot](https://hub.docker.com/r/galacsh/nginx-certbot)

```shell
docker pull galacsh/nginx-certbot
```

## Structure

- `html/`: Volume for the `/usr/share/nginx/html` directory.
- `conf.d/`: Files to be copied to the `/etc/nginx/conf.d` directory.
- `templates/`: Volume for the `/etc/nginx/templates` directory.
- `scripts/`: Shell scripts to the nginx server and SSL certificates.
    - `obtain-cert.sh`: Obtain the SSL certificates if they do not exist.
    - `renew-cert.sh`: Tries to renew the SSL certificates every `RETRY_INTERVAL` seconds.
    - `reload-nginx.sh`: Reloads the nginx server after the SSL certificates have been renewed.
- `entrypoint.sh`: Entrypoint script for the Docker container.
- `Dockerfile`: The Dockerfile for the image.
- `compose.yaml`: Docker Compose configuration.
- `compose.prod.yaml`: Docker Compose configuration for production. (Merge with `compose.yaml`)
- `.env`: Environment variables for the Docker Compose configuration.
- `.env.local`: Environment variables to override the `.env` file in production.

### `htmls/`

The `html/` directory is a volume for the `/usr/share/nginx/html` directory.
Since this is a volume, you can manage the static files for the nginx server without rebuilding & restarting the
container.

### `conf.d/`

The `conf.d/` directory contains the configuration files for the nginx server.
These files are copied to the `/etc/nginx/conf.d` directory during the build process.

Note that **during the startup**, configuration templates inside `templates/` directory will be processed and copied to
the `/etc/nginx/conf.d` directory. This means that the configuration files with the same name inside the `conf.d/`
directory will be overwritten.

### `templates/`

The `templates/` directory is a volume for the `/etc/nginx/templates` directory.

> [!NOTE]
> Configuration templates are processed during the startup by nginx image's
> `docker-entrypoint.sh -> 20-envsubst-on-templates.sh`.
> This means that you can use environment variables in the configuration files.

Since this is a volume, you can manage the configuration templates for the nginx server without rebuilding.
But you need to restart the container to apply the changes because the configuration templates are processed during the
startup.

### `scripts/`

#### `obtain-cert.sh`

The script tries to obtain the SSL certificates if they do not exist.

1. Check if the SSL certificates exist.
2. If the certificates do not exist, try to obtain them.

> [!NOTE]
> In development mode (`MODE=dev`), this doesn't try to obtain the SSL certificates.

#### `renew-cert.sh`

The script tries to renew the SSL certificates every `RETRY_INTERVAL` seconds.
Since the loop inside the script starts with a sleep, renewal will not happen immediately after the container starts.

> [!NOTE]
> In development mode (`MODE=dev`) this doesn't try to renew the SSL certificates.

#### `reload-nginx.sh`

This script is a `--deploy-hook` for Certbot.
It reloads the nginx server after the SSL certificates have been renewed.

### `entrypoint.sh`

The entrypoint script is the main script that is run when the Docker container starts.

1. The script runs `/docker-entrypoint.sh` from the nginx image to initialize and start the nginx server.
2. Try to obtain the SSL certificates.
3. Schedule the renewal of the SSL certificates in the background.
4. Make the nginx process the PID 1. (Restarts the nginx server)

### Dockerfile

The Dockerfile is based on the official nginx non-privileged image, `nginxinc/nginx-unprivileged`.
During the build process, the Certbot is installed and the necessary scripts are added to the image.

Since this image's entrypoint is just a wrapper of base image's `/docker-entrypoint.sh`,
you can use the same CMD as the base image.

Base image:

```dockerfile
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
```

This image:

```dockerfile
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
```

### Compose Files

- `compose.yaml` is designed for development purposes.
- `compose.prod.yaml` is designed for production purposes.

So, to use the production configuration, you have to merge the `compose.yaml` and `compose.prod.yaml` files.

```shell
docker compose -f compose.yaml -f compose.prod.yaml up
```

For just development purposes, below command is enough.

```shell
docker compose up
```

### Environment Variables

- Files
    - `.env`: Set of environment variables picked up by the `compose.yaml` file.
    - `.env.local`: Set of environment variables picked up by the `compose.prod.yaml` file.
- Variables
    - `MODE`: Set the mode of the container. (specify `MODE=prod` in `.env.local`)
    - `DOMAINS`
        - Set the domain names for the SSL certificates.
        - Use comma (`,`) to separate the domain names.
        - Use space (` `) to separate the sets of domain names.
        - Base domain name should be the first element.
        - e.g. `DOMAINS="example.com,www.example.com example.net,www.example.net"`
    - `EMAIL`: Set the email address for the SSL certificates.
    - `RETRY_INTERVAL` (Optional): Set the interval at which the SSL certificates are renewed. (in seconds)

Besides these, you can set the environment variables for the configuration templates.

For example:

```shell
MY_SERVER_NAME=example.com
```

Then, you can use the `MY_SERVER_NAME` variable in the configuration templates.

```nginx
server {
    listen 80;
    server_name ${MY_SERVER_NAME};

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}
```

### Volumes

**1. `/usr/share/nginx/html`**

A volume for the static files of the Nginx server.
You can manage the static files without rebuilding & restarting the container.

In compose file, it is defined as:

```yaml
services:
  nginx-certbot:
    # ...
    volumes:
      - ./html:/usr/share/nginx/html
```

**2. `/etc/letsencrypt/`, `/var/lib/letsencrypt`**

A volume for the SSL certificates.

In compose file, it is defined as:

```yaml
services:
  nginx-certbot:
    # ...
    volumes:
      - ...
      - etc-letsencrypt:/etc/letsencrypt
      - lib-letsencrypt:/var/lib/letsencrypt
    # ...

volumes:
  etc-letsencrypt:
    name: etc-letsencrypt
  lib-letsencrypt:
    name: lib-letsencrypt
```

**3. `/etc/nginx/templates`**

A volume for the configuration templates of the Nginx server.
You can manage the configuration templates without rebuilding the container.

In compose file, it is defined as:

```yaml
services:
  nginx-certbot:
    # ...
    volumes:
      - ./templates/[dev|prod]:/etc/nginx/templates
```

## Usage

### Build

```shell
# Development - 1 (command)
docker compose build
# Development - 2 (using script)
./build.sh dev

# Production - 1 (command)
docker compose -f compose.yaml -f compose.prod.yaml build
# Production - 2 (using script)
./build.sh
```

### Run

```shell
# Development - 1 (command)
docker compose up
# Development - 2 (using script)
./start.sh dev

# Production - 1 (command)
docker compose -f compose.yaml -f compose.prod.yaml up
# Production - 2 (using script)
./start.sh
```

### Stop

```shell
# Development - 1 (command)
docker compose down
# Development - 2 (using script)
./stop.sh dev

# Production - 1 (command)
docker compose -f compose.yaml -f compose.prod.yaml down
# Production - 2 (using script)
./stop.sh
```
