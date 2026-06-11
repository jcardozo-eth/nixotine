# Contributing

Improvements to nixotine itself are welcome: bug fixes, new generic modules,
documentation. To *use* or *customize* the configuration for a personal setup,
see the [README](README.md) instead (it covers consuming it as a flake library
and forking it).

## Scope

Keep contributions generic and free of personal data. Identity, hostnames,
and machine-specific values must not enter tracked files. A parameter that
legitimately varies per machine or user belongs in `settings.nix` with a
sensible generic default.

## Conventions

- [Conventional Commits](https://www.conventionalcommits.org) (`feat:`, `fix:`,
  `docs:`, `chore:`, `ci:`; scopes like `feat(home): …`).
- Small, logical commits — one coherent change each.
- Match the existing module layout (`modules/`, `modules/home/`) and run the
  formatter (`nix fmt`).

## Before opening a PR

Run the same checks CI does:

```sh
nix flake check
nix fmt -- --ci
nix eval .#darwinConfigurations --apply 'c: (builtins.head (builtins.attrValues c)).system.drvPath'
```

The `justfile` wraps these (with `just` on PATH via `nix develop` or direnv):

| Recipe | Action |
|--------|--------|
| `just build` | build the configuration without switching |
| `just eval` | print the system derivation path |
| `just check` | `nix flake check` + format check |
| `just fmt` | format all Nix files |
| `just update` | update flake inputs |
| `just sync` | `git pull upstream main` |

The repo's `darwinConfigurations.mac` uses generic placeholder settings, so
`nix eval` and `darwin-rebuild build` are harmless — they compute the system in
the Nix store without touching the machine. Never `switch` it, though: that would
activate the placeholder identity and settings. A real machine is activated from
a consumer flake.

## CI and automation

Three pieces of [GitHub](https://docs.github.com/actions) automation keep the
repo healthy, all on Linux runners (no macOS build job yet):

- **`check.yml`** — the PR gate. Runs on every push to `main` and every pull
  request:
  - `nix flake check`
  - a format check (`nix fmt -- --ci`)
  - an eval of the single configuration, resolved by value rather than by
    hostname
- **`flake-update.yml`** — bumps `flake.lock`. Runs weekly, or on demand via
  *Run workflow*:
  - calls [update-flake-lock](https://github.com/DeterminateSystems/update-flake-lock)
    to open **one combined PR** bumping every input
  - merged manually once checks pass
- **`dependabot.yml`** — keeps the GitHub Actions current. Runs weekly:
  - opens PRs bumping the Actions used in the workflows above (they are pinned to
    commit SHAs)
