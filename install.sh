#!/usr/bin/env bash

targetDir=${2:-$HOME/.local/bin}
targetFilePath=$targetDir/wp-changelog-injector


# first make sure the target dir exists
mkdir -p "$targetDir"

set -e
curl -sSL  https://raw.githubusercontent.com/neblabs/wp-changelog-injector/main/wp-changelog-injector.sh -o "$targetFilePath"

sudo chmod +x "$targetFilePath"

# warn if not in path
if ! [[ "$targetDir" == *"/.local/bin"* ]]; then
    echo [warn] Installed to "$targetFilePath" but it "doesn't" seem to be in your PATH.
fi



