#!/usr/bin/env bash

targetDir=${2:-$HOME/.local/bin}
targetFilePath=$targetDir/wp-changelog-injector


# first make sure the target dir exists
mkdir -p "$targetDir"

echo installing into "$targetFilePath"

set -e
curl -sSL  https://raw.githubusercontent.com/neblabs/wp-changelog-injector/main/wp-changelog-injector.sh -o "$targetFilePath"

sudo chmod +x "$targetFilePath"

# warn if not in path
if ! [[ "$targetDir" == *"/.local/bin"*  ]]; then
    echo [warn] Installed to "$targetFilePath" but it "doesn't" seem to be in your PATH.
fi

# install dep
echo "installing dep (versions finder)..."

curl -L https://raw.githubusercontent.com/neblabs/versions-finder/main/install.sh | bash



