#!/usr/bin/env bash

readmeFile=readme.md
changelogFile=changelog.md
latest=false

function fail() {
    echo "$1" 1>&2
    exit 1
}

function print-usage() {
    cat << USAGE
Default readme: $readmeFile
Default changelog: $changelogFile
USAGE

    fail "usage: $0 [--readme path] [--changelog path] [--latest]"
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --readme)
            readmeFile="$2"
            [[ -z "$readmeFile" ]] && print-usage
            shift 2
        ;;
        --changelog)
            changelogFile="$2"
            [[ -z "$changelogFile" ]] && print-usage
            
            shift 2
        ;;
        --latest)
            latest=true
            shift
        ;;
        *)
            print-usage
        ;;
    esac
done

if ! [[ -f "$readmeFile" ]]; then
    fail "readme file: $readmeFile doesn't exist"
fi

# gets the changelog since the previous stable tag. if none (for first version releases) gets the latest.


if "$latest" ; then
    whichTag=--latest
else
    # here itll fetch the previous tag if no previous then the latest as a fallback eg on a new repo with only one tag
    whichTag=--previous-or-latest
fi
tagRange="$(versions-finder stable "$whichTag")"..HEAD

wpChangelog="$(git-cliff --config wp-cliff.toml "$tagRange")"

# now literally just put it in the changelog and call it a day
# unfortunately thought we have to read the whole file first for substitution
ogReadme="$(cat "$readmeFile")"
newReadme="${ogReadme/== Changelog ==/$wpChangelog}"

printf '%s' "$newReadme" > "$readmeFile"

echo "Updated readme $readmeFile with updated changelog!"

# now just update the default changelog

stdChangelog="$(git-cliff "$tagRange")"

# make sure it exists
ogChangelog="$(cat "$changelogFile" 2>&1)"

[[ "$?" -gt 0 ]] && touch "$changelogFile"

printf '%s\n%s' "$stdChangelog" "$ogChangelog" > "$changelogFile"



