# Common tasks for nixotine. Run `just` to list recipes.

# Strict shell: abort a recipe on the first failing step.
set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# List available recipes
default:
    @just --list

# Resolve the single darwin configuration's hostname
_host:
    @nix eval --raw .#darwinConfigurations --apply 'c: builtins.head (builtins.attrNames c)'

# Build the configuration without switching
build:
    #!/usr/bin/env bash
    set -euo pipefail
    [[ "$OSTYPE" == darwin* ]] || { echo "error: build requires macOS (darwin)." >&2; exit 1; }
    command -v darwin-rebuild >/dev/null 2>&1 || { echo "error: darwin-rebuild not on PATH." >&2; exit 1; }
    darwin-rebuild build --flake ".#$(just _host)"

# Evaluate the system derivation path
eval:
    nix eval ".#darwinConfigurations.$(just _host).system.drvPath"

# Flake checks: eval + formatting
check:
    nix flake check
    nix fmt -- --check .

# Format all Nix files in place
fmt:
    nix fmt

# Update all flake inputs
update:
    #!/usr/bin/env bash
    set -euo pipefail
    read -r -p "Update all flake inputs (rewrites flake.lock)? [y/N] " reply
    [[ "$reply" == [yY] ]] || { echo "aborted."; exit 1; }
    nix flake update

# Pull upstream changes
sync:
    #!/usr/bin/env bash
    set -euo pipefail
    git remote get-url upstream >/dev/null 2>&1 || { echo "error: no 'upstream' remote. Add it with: git remote add upstream <url>" >&2; exit 1; }
    git pull upstream main
