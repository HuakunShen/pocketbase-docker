#!/bin/bash
tag_name=$(curl -s https://api.github.com/repos/pocketbase/pocketbase/releases/latest | jq -r '.tag_name')
echo $tag_name
docker buildx build . --push --platform linux/amd64,linux/arm64,linux/arm/v7 -t huakunshen/pocketbase:$tag_name
