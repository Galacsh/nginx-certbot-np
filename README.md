# nginx with Certbot with non-privileged user

[This repository](https://github.com/Galacsh/nginx-certbot) creates a Docker image for a nginx server with Certbot.
All the processes are run as a non-privileged user (`nginx`).

The image is based on the official nginx non-privileged image, `nginxinc/nginx-unprivileged`.
During the build process, the Certbot is installed and the necessary scripts are added to the image.

## Image

[galacsh/nginx-certbot-np](https://hub.docker.com/r/galacsh/nginx-certbot-np)

```shell
docker pull galacsh/nginx-certbot-np
```

## Structure

- `conf.d/`: Files to be copied to the `/etc/nginx/conf.d` directory.
- `scripts/`: Shell scripts to the nginx server and SSL certificates.
    - `obtain-cert.sh`: Obtain the SSL certificates if they do not exist.
    - `renew-cert.sh`: Tries to renew the SSL certificates every `RETRY_INTERVAL` seconds.
    - `reload-nginx.sh`: Reloads the nginx server after the SSL certificates have been renewed.
- `entrypoint.sh`: Entrypoint script for the Docker container.
- `Dockerfile`: The Dockerfile for the image.
- `.env`: Environment variables for the Docker Compose configuration.

### `conf.d/`

The `conf.d/` directory contains the configuration files for the nginx server.
These files are copied to the `/etc/nginx/conf.d` directory during the build process.

Note that **during the startup**, configuration templates inside `templates/` directory will be processed and copied to
the `/etc/nginx/conf.d` directory. This means that the configuration files with the same name inside the `conf.d/`
directory will be overwritten.

### `scripts/`

#### `obtain-cert.sh`

The script tries to obtain the SSL certificates if they do not exist.

1. Check if the SSL certificates exist.
2. If the certificates do not exist, try to obtain them.
3. Obtaining the certificates is done by running the Certbot in webroot mode. (`--webroot -w /acme-challenge`)

Note that `/acme-challenge` is the directory inside container where the Certbot will write the challenge files.
Your nginx configuration should have a location block to serve the challenge files.

```text
location /.well-known/acme-challenge {
    root /acme-challenge/;
}
```

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

### Environment Variables

- `MODE`: Set the mode of the container. (specify `MODE=prod` in `.env.local`)
- `DOMAINS`
    - Set the domain names for the SSL certificates.
    - Use comma (`,`) to separate the domain names.
    - Use space (` `) to separate the sets of domain names.
    - Base domain name should be the first element.
    - e.g. `DOMAINS="example.com,www.example.com example.net,www.example.net"`
- `EMAIL`: Set the email address for the SSL certificates.
- `RETRY_INTERVAL` (Optional): Set the interval at which the SSL certificates are renewed. (in seconds)

## Usage

### Run

This is an example of running the container with the `docker run` command.

```shell
docker run -it \
  -p 80:80 \
  -p 443:443 \
  -e MODE=prod \
  -e DOMAINS="example.com,www.example.com example.net,www.example.net" \
  -e EMAIL="your_email@address.com" \
  -e RETRY_INTERVAL=86400 \
  -v ./html:/usr/share/nginx/html \
  -v ./certbot/etc:/etc/letsencrypt \
  -v ./certbot/var:/var/lib/letsencrypt \
  -v ./templates:/etc/nginx/templates \
  --name nginx-certbot \
  galacsh/nginx-certbot-np
```

In `./templates`, create the configuration template for obtaining the SSL certificates.

```text
server {
    listen       80;
    server_name  _;

    
    location /.well-known/acme-challenge {
        root /acme-challenge/;
    }

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
```

### Stop

```shell
docker stop nginx-certbot
```
