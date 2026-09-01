#!/usr/bin/env bash

readmeFile=readme.md
changelogFile=changelog.md
latest=false
wpTomlFile=wp-cliff.toml

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
    {#- Extract release-note trailer -#}
    {%- set release_note = "" -%}
    {%- for footer in commit.footers -%}
        {%- if footer.token | lower == "release-note" -%}
            {%- set_global release_note = footer.value -%}
        {%- endif -%}
    {%- endfor -%}

    {#- Render note or fallback -#}
    {%- if release_note != "" -%}
+ {{ release_note | trim | upper_first }}
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

if ! [[ -f "$wpTomlFile" ]]; then
    # then create i
    echo "$wpTomlConfig" > "$wpTomlFile"
fi

if "$latest" ; then
    whichTag=--latest
else
    # here itll fetch the previous tag if no previous then the latest as a fallback eg on a new repo with only one tag
    whichTag=--previous-or-latest
fi
tagRange="$(versions-finder stable "$whichTag")"..HEAD

wpChangelog="$(git-cliff --config "$wpTomlFile" "$tagRange")"

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



