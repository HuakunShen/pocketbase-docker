# FROM alpine
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