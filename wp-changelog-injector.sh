#!/usr/bin/env bash

readmeFile=readme.md
latest=false
type=wp

function fail() {
    echo "$1" 1>&2
    exit 1
}

function print-usage() {
    cat << USAGE
Default readme: $readmeFile
USAGE

    fail "usage: $0 [--readme path] [--type 'wp'] [--latest]" $"\n" "usage: $0 [--type 'md'] [--min-tag min]"
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --readme)
            readmeFile="$2"
            [[ -z "$readmeFile" ]] && print-usage
            shift 2
        ;;
        --type)
            type="$2"
            [[ -z "$type" ]] && print-usage
            shift 2
        ;;
        --min-tag)
            minTag="$2"
            [[ -z "$minTag" ]] && print-usage
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

if [[ "$type" == 'wp' ]]; then
    configFile=wp-cliff.toml
    # wp usage checks
    if ! [[ -f "$readmeFile" ]]; then
        fail "readme file: $readmeFile doesn't exist"
    fi
    if [[ -n "$minTag" ]]; then
        # not allowed here
        print-usage
    fi
elif [[ "$type" == 'md' ]]; then
    configFile=cliff.toml
else
    echo invalid type && print-usage
fi


# let's add a default toml file if not in dir

IFS='' read -r -d '' wpTomlConfig <<'EOF'
[git]
conventional_commits = true
filter_unconventional = false
commit_parsers = [
  { message = "^feat", group = "Features" },
  { message = "^fix", group = "Fixes and Improvements" },
  { message = "^perf", group = "Performance Improvements" },
  # Optional bulletproof catch-all: explicitly skip anything else
  { message = "^.*", skip = true }
]

[changelog]
header = "== Changelog ==\n"
body = """
{% if version %}
= {{ version | trim_start_matches(pat="v") }} =
{% else %}
= Unreleased =
{% endif %}

{% for group, commits in commits | group_by(attribute="group") %}
**{{ group | replace(from="1_", to="") | replace(from="2_", to="") | replace(from="3_", to="") }}**

{% for commit in commits -%}
    {%- set rn_footers = commit.footers | filter(attribute="token", value="release-note") -%}
    {%- if rn_footers | length > 0 -%}
+ {{ rn_footers[0].value | trim | upper_first }}
    {%- elif commit.body -%}
+ {{ commit.body | split(pat="\n") | first | trim | upper_first }}
    {%- else -%}
+ {{ commit.message | trim | upper_first }}
    {%- endif %}
{% endfor %}
{% endfor %}
"""
trim = false
EOF

IFS='' read -r -d '' mdTomlConfig <<'EOF'
[git]
conventional_commits = true
filter_unconventional = false
commit_parsers = [
  { message = "^feat", group = "Features" },
  { message = "^fix", group = "Fixes and Improvements" },
  { message = "^perf", group = "Performance Improvements" },
  { message = "^docs", group = "Performance Improvements" },
  { message = "^build", group = "Performance Improvements" },
  { message = "^refactor", group = "Performance Improvements" },
  { message = "^style", group = "Performance Improvements" },
  { message = "^test", group = "Performance Improvements" },
  # left: { message = "^ci", group = "Performance Improvements" },
  { message = "^.*", skip = true }
]

[changelog]
header = "# Changelog\n"
body = """
{% if version %}
## {{ version | trim_start_matches(pat="v") }}
{% else %}
## Unreleased
{% endif %}

{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | replace(from="1_", to="") | replace(from="2_", to="") | replace(from="3_", to="") }}

{% for commit in commits -%}
    {%- set rn_footers = commit.footers | filter(attribute="token", value="release-note") -%}
    {%- if rn_footers | length > 0 -%}
- {{ rn_footers[0].value | trim | upper_first }}
    {%- elif commit.body -%}
- {{ commit.body | split(pat="\n") | first | trim | upper_first }}
    {%- else -%}
- {{ commit.message | trim | upper_first }}
    {%- endif %}
{% endfor %}
{% endfor %}
"""
trim = false
EOF

if ! [[ -f "$configFile" ]]; then
    # will be written to bellow
    configFile=$(mktemp).toml
fi

if [[ "$type" == 'wp' ]]; then
    if "$latest" ; then
        whichTag=--latest
    else
        # here itll fetch the previous tag if no previous then the latest as a fallback eg on a new repo with only one tag
        whichTag=--previous-or-latest
    fi

    tagRange="$(versions-finder stable "$whichTag")"..HEAD

    if ! [[ -s "$configFile" ]]; then
        echo "$wpTomlConfig" > "$configFile"
    fi
else
    if [[ -n "$minTag" ]] ; then
        whichTag="$minTag"
    else
        # get the oldest by default
        # todo: move this to versions-finder (open a pr)
        whichTag=$(git tag --sort=v:refname | head -n 1)
    fi

    tagRange="$whichTag"..HEAD

    if ! [[ -s "$configFile" ]]; then
        # then create i
        echo "$mdTomlConfig" > "$configFile"
    fi
fi

set -e

wpChangelog="$(git-cliff --config "$configFile" "$tagRange")"

if [[ "$type" == 'md' ]]; then
    echo "$wpChangelog"

    exit
fi
# now literally just put it in the changelog and call it a day
# unfortunately thought we have to read the whole file first for substitution
ogReadme="$(cat "$readmeFile")"
newReadme="${ogReadme/== Changelog ==/$wpChangelog}"

printf '%s' "$newReadme" > "$readmeFile"

echo "Updated readme $readmeFile with updated changelog!"
