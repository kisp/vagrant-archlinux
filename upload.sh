#!/bin/bash

set -euxo pipefail

VERSION=1.0.7

# Create a new version

curl --fail-with-body \
     --request POST \
     --header "Content-Type: application/json" \
     --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
     https://app.vagrantup.com/api/v1/box/kisp/archlinux/versions \
     --data "{ \"version\": { \"version\": \"$VERSION\" } }"

# Create a new provider

curl --fail-with-body \
     --request POST \
     --header "Content-Type: application/json" \
     --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
     https://app.vagrantup.com/api/v1/box/kisp/archlinux/version/$VERSION/providers \
     --data '{ "provider": { "name": "virtualbox" } }'

# Prepare the provider for upload/get an upload URL

response=$(curl --fail-with-body -s \
                --request GET \
                --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
                https://app.vagrantup.com/api/v1/box/kisp/archlinux/version/$VERSION/provider/virtualbox/upload)

# Extract the upload URL from the response (requires the jq command)

upload_path=$(echo "$response" | jq -r .upload_path)

# Perform the upload

curl --fail-with-body \
     --request PUT \
     "${upload_path}" \
     --upload-file archlinux-x64-*.box \
    | cat

echo DONE
echo Remember to manually set the architecture to amd64
echo Then manually release the new version :\)
