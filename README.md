# Pocketbase Docker

Pocketbase doesn't provide docker image, but the image is very easy to build, simply download the executable to docker image and run it within docker.

Pocketbase releases for 3 linux arch, amd64, arm64 and arm/v7, thus I also build docker image for these 3 platforms.

The [`Dockerfile`](./Dockerfile) determines the latest url from platform and the latest release url.

Docker Hub: https://hub.docker.com/repository/docker/huakunshen/pocketbase/general

```Dockerfile
FROM alpine as builder

WORKDIR /app
COPY . .
ARG TARGETPLATFORM
RUN apk add --no-cache bash curl jq wget unzip
RUN RESPONSE=$(curl -s https://api.github.com/repos/pocketbase/pocketbase/releases/latest); \
    TAG_NAME=$(echo $RESPONSE | jq -r '.tag_name'); \
    echo $TAG_NAME; \
    mkdir pocketbase; \
    if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        download_url=$(echo $RESPONSE | jq -r '.assets[] | .browser_download_url' | grep linux_amd64); \
        echo $download_url; \
        echo $download_url | wget --directory-prefix=./pocketbase/ -i -; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        download_url=$(echo $RESPONSE | jq -r '.assets[] | .browser_download_url' | grep linux_arm64); \
        echo $download_url; \
        echo $download_url | wget --directory-prefix=./pocketbase/ -i -; \
    elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
        download_url=$(echo $RESPONSE | jq -r '.assets[] | .browser_download_url' | grep linux_armv7); \
        echo $download_url; \
        echo $download_url | wget --directory-prefix=./pocketbase/ -i -; \
    else \
        echo "Unknown platform: $TARGETPLATFORM"; \
        exit 1; \
    fi; \
    cd pocketbase; \
    FILENAME=$(ls | grep .zip); \
    unzip $FILENAME;


FROM alpine
WORKDIR /pocketbase
COPY --from=builder /app/pocketbase/pocketbase /pocketbase
EXPOSE 8090
CMD [ "/pocketbase/pocketbase", "serve", "--http", "0.0.0.0:8090" ]
```

## GitHub CI

I am using a cron job with GitHub Action to run a check daily to check for new release. 
If there is a new release, the CI will build again with the new release tag automatically, so it's always up to date and I don't need to maintain this project.

[./.github/workflows/cron-update-docker.yml](./.github/workflows/cron-update-docker.yml) caches a file containing the previous tag version, and compare with the current tag.

If the tag is unchanged, then all steps will be skipped. `actions/cache@v3` is used for caching, although it's usually used for caching large dependencies like Rust's `target` and `node_modules`.


## Usage

```bash
docker run -p 8090:8090 huakunshen/pocketbase:v0.19.3
```

### docker-compose

```yaml
version: '3.9'

services:
  pocketbase:
    image: huakunshen/pocketbase:v0.19.3
    container_name: pocketbase
    restart: unless-stopped
    ports:
      - 8090:8090
    volumes:
      - pocketbase-data:/pocketbase/pb_data

volumes:
  pocketbase-data:
```