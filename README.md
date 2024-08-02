# Run nginx and Certbot with a non-privileged user

[This repository](https://github.com/Galacsh/nginx-certbot-np) creates a Docker image for a nginx server with Certbot.
All the processes are run as a non-privileged user (`nginx`).

The image is based on the official nginx non-privileged image, `nginxinc/nginx-unprivileged`.
During the build process, the Certbot is installed and the necessary scripts are added to the image.

## Image

[galacsh/nginx-certbot-np](https://hub.docker.com/r/galacsh/nginx-certbot-np)

```shell
docker pull galacsh/nginx-certbot-np
```

### Supported architectures

Even nginx supports many architectures, Certbot only supports the following architectures.
So, this image is only available for the following architectures.

- linux/arm/v6
- linux/amd64

## Structure

- `conf.d/http-default.conf`: Default config file to handle http requests.
    - HTTP to HTTPS redirection
    - Location for ACME challenge
- `scripts/`: Shell scripts to the nginx server and SSL certificates.
    - `obtain-cert.sh`: Obtain the SSL certificates if they do not exist.
    - `renew-cert.sh`: Tries to renew the SSL certificates every `RETRY_INTERVAL` seconds.
    - `reload-nginx.sh`: Reloads the nginx server after the SSL certificates have been renewed.
- `entrypoint.sh`: Entrypoint script for the Docker container.
- `Dockerfile`: The Dockerfile for the image.
- `.env`: Environment variables for the Docker Compose configuration.

### `scripts/`

#### `obtain-cert.sh`

The script tries to obtain the SSL certificates if they do not exist.

1. Check if the SSL certificates exist.
2. If the certificates do not exist, try to obtain them.
3. Obtaining the certificates is done by running the Certbot in webroot mode. (`--webroot -w /acme-challenge`)

Note that `/acme-challenge` is the directory inside container where the Certbot will write the challenge files.
Your nginx configuration doesn't need to handle this.
`conf.d/http-default.conf` handles this and it's already copied to the image.

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
you can use the same CMD as the base image (nginx).

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

This is an example of running the container with the `docker compose up` command.

Let's say we are configuring 2 domains, `example.com` and `example.net`.
Create config template files for those two domains.

```text
# templates/example-1.com.conf.template

server {
    server_name ${EXAMPLE_COM};
    listen      443 ssl;
    listen      [::]:443 ssl;

    # Certificate
    ssl_certificate /etc/letsencrypt/live/${EX1_HOSt}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${EX1_HOSt}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        root   /usr/share/nginx/html/${EXAMPLE_COM};
        index  index.html;
        try_files $uri $uri/ /index.html;
    }
}
```

```text
# templates/example.net.conf.template

server {
    server_name ${EXAMPLE_NET};
    listen      443 ssl;
    listen      [::]:443 ssl;

    # Certificate
    ssl_certificate /etc/letsencrypt/live/${EXAMPLE_NET}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${EXAMPLE_NET}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        root   /usr/share/nginx/html/${EXAMPLE_NET};
        index  index.html;
        try_files $uri $uri/ /index.html;
    }
}
```

Create `.env`.

```shell
MODE=prod

DOMAINS=example.com example.net
EMAIL=your-email@sample.com
```

Create `compose.yaml`.

```yaml
services:
  app:
    image: galacsh/nginx-certbot-np:latest
    container_name: nginx
    restart: always
    volumes:
      - etc-letsencrypt:/etc/letsencrypt
      - lib-letsencrypt:/var/lib/letsencrypt
      - ./templates:/etc/nginx/templates
      - ./html:/usr/share/nginx/html
    ports:
      - 80:80
    env_file:
      - .env

volumes:
  etc-letsencrypt:
  lib-letsencrypt:
```

Now, you can run and see logs.

```shell
docker compose up -d
docker compose logs -f
```

### Stop

```shell
docker compose down
```

---

## Build & Push the Image

```shell
git commit -m "commit message should contain something like v1.0.1"
./build.sh
```

