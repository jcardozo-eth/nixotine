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
- Leave the `# ── Fork-local inputs ──` region of `flake.nix` empty. It is
  reserved for forks and consumers, so keeping it untouched upstream is what lets
  their added inputs land without conflicting on `git pull`. A genuine new
  upstream dependency goes in the main `inputs` block above that region.

## Before opening a PR

Run the same checks CI does:

```sh
nix flake check
nix fmt -- --check .
nix eval .#darwinConfigurations --apply 'c: (builtins.head (builtins.attrValues c)).system.drvPath'
```

## CI and automation

Three pieces of [GitHub](https://docs.github.com/actions) automation keep the
repo healthy, all on Linux runners (there is no macOS build job):

- **`check.yml`** — the PR gate. Runs on every push to `main` and every pull
  request:
  - `nix flake check`
  - a format check (`nix fmt -- --check .`)
  - an eval of the single configuration, resolved by value rather than by
    hostname, so a fork that overrides the host via `settings.local.nix` stays
    green
- **`flake-update.yml`** — bumps `flake.lock`. Runs weekly, or on demand via
  *Run workflow*:
  - calls [update-flake-lock](https://github.com/DeterminateSystems/update-flake-lock)
    to open **one combined PR** bumping every input
  - a single PR is the right fit at this handful of direct inputs; per-input PRs
    are feasible (scoping a run to named `inputs:` touches disjoint lock regions,
    so they merge without conflict) but unnecessary here
  - review via the PR body's per-input changelog and compare links, not the
    opaque `flake.lock` rev diff
  - merged manually once checks pass
- **`dependabot.yml`** — keeps the GitHub Actions current. Runs weekly:
  - opens PRs bumping the Actions used in the workflows above (they are pinned to
    commit SHAs)
