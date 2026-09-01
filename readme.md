# WP Changelog Injector

todo: docs need to be updated from the latest breaking changing commit

A lightweight Bash utility to automatically generate and inject `git-cliff` changelog entries into WordPress-formatted `readme.md` / `readme.txt` files and standard `changelog.md` files upon release using conventional commits.

## Requirements

Ensure the following tools are installed and available in your `$PATH`:

* **[git-cliff](https://github.com/orhun/git-cliff)** – Fast, customizable changelog generator.
* **[versions-finder](https://github.com/neblabs/versions-finder)** – CLI utility to resolve target Git version tags. Automatically installed using the installed bellow.

This tool also requires that you use conventional commits.

## How It Works

This script is designed to run **post-tag** (after tagging a new release).

1. **Tag Resolution:** Uses `wp-changelog-injector stable --previous-or-latest` to determine the previous tag range (`<prev-tag>..HEAD`). It will get all the changes from the previous tag or the current if there's only one tag (new repo).
2. **WordPress Format Injection:** Generates WordPress-compliant release notes via `git-cliff` using `wp-cliff.toml` and replaces the `== Changelog ==` section inside your target README file.
3. **Standard Changelog Prepend:** Runs `git-cliff` and prepends the new release log to the top of `changelog.md`.

---

## Installation

A. Run the installer (git-cliff needs to be installed separately, versions finder will be installed)

```bash
curl -L https://raw.githubusercontent.com/neblabs/wp-changelog-injector/main/install.sh | bash

# make sure ~/.local/bin/ is in your PATH.
```

B. ...Or install it manually

```bash
sudo curl -sSL https://raw.githubusercontent.com/neblabs/wp-changelog-injector/main/wp-changelog-injector.sh -o "$HOME"/.local/bin/wp-changelog-injector

sudo chmod +x "$HOME"/.local/bin/wp-changelog-injector

# and make sure ~/.local/bin/ is in your PATH.
```

---

## Configuration

This tool creates a wp-cliff.toml file with some nice defaults for readme file changelogs. This default file only takes the commits with prefixes: fix:, feat: and perf:. It will also check for a line using release-note:, and will use that in place of the commit header.



You can optionally create a `wp-cliff.toml` configuration file in your project root to control the WordPress readme file output format. Example:

```toml
[git]
commit_parsers = [
  { message = "^feat", group = "Features" },
  { message = "^fix", group = "Bug Fixes" },
  { message = "^doc", group = "Documentation" },
  { message = "^refactor", group = "Code Improvements" },
]

[changelog]
header = "== Changelog ==\n"
body = """
{% if version -%}
= {{ version | trim_start_matches(pat="v") }} =
{% else -%}
= Unreleased =
{% endif -%}

{% for group, commits in commits | group_by(attribute="group") -%}
**{{ group | replace(from="1_", to="") | replace(from="2_", to="") | replace(from="3_", to="") }}**
{% for commit in commits -%}
* {{ commit.message | upper_first }}
{% endfor -%}

{% endfor -%}
"""
trim = false

```

---

## Usage

Make sure your target README file already contains the line `== Changelog ==`.

```bash
# Run with default paths (readme.md and changelog.md)
wp-changelog-injector

# Specify custom file paths
wp-changelog-injector --readme plugin/readme.txt --changelog CHANGELOG.md

```

### Options

| Option | Default | Description |
| --- | --- | --- |
| `--readme <path>` | `readme.md` | Path to the target WordPress README file containing `== Changelog ==`. |
| `--changelog <path>` | `changelog.md` | Path to the standard markdown changelog file. |
| `--latest` | false | Fetch from the latest (current) version instead of the previous |

```
