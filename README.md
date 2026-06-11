# nixotine

> **Status: alpha.** Actively developed; expect occasional breaking changes.

An **opinionated and reusable** [nix-darwin](https://github.com/LnL7/nix-darwin) +
[Home Manager](https://github.com/nix-community/home-manager) configuration for Apple Silicon Mac. It bakes in a particular set of tooling and
conventions; everything machine- and user-specific is configurable, so it
can be adopted wholesale, cherry-picked from, or used as inspiration. The
public repo ships generic defaults and exports a `mkDarwin` builder, so it can be
[used as a flake library](#use-as-a-flake-library) or
[forked](#forking-nixotine).

> [!IMPORTANT]
> Provided as is, without warranty, at the adopter's own risk. See
> [LICENSE](LICENSE). This repository carries no identities, keys, or
> machine-specific values itself, but a personal setup built on it can, so be
> deliberate about what a fork or commit exposes publicly.

## Contents

- [Why](#why)
- [Features](#features)
  - [nix-darwin + Home Manager](#nix-darwin--home-manager)
  - [zsh + oh-my-zsh](#zsh--oh-my-zsh)
  - [Git identity, signing, and SSH keys](#git-identity-signing-and-ssh-keys)
  - [Declarative Homebrew casks](#declarative-homebrew-casks)
  - [direnv](#direnv)
  - [Local LLM stack](#local-llm-stack)
  - [Linux builder](#linux-builder)
- [Setup](#setup)
  - [Prerequisites](#prerequisites)
  - [Use as a flake library](#use-as-a-flake-library)
  - [Forking nixotine](#forking-nixotine)
  - [Applying the configuration](#applying-the-configuration)
  - [Local identity and SSH files](#local-identity-and-ssh-files)
- [Architecture](#architecture)
  - [Module layout](#module-layout)
  - [Platform (Apple Silicon)](#platform-apple-silicon)
  - [PATH policy](#path-policy)
- [Contributing](#contributing)

## Why

Managing a development environment with Nix and Home Manager has a few
advantages:

- **Declarative.** Packages, shell, git, and the local LLM stack are described
  as data in one place and applied with a single rebuild, instead of accreting
  through changes nobody remembers making. The configuration doubles as
  documentation of how the environment is set up.
- **Reproducible and pinned.** `flake.lock` pins every input to an exact
  revision, so a rebuild gives the same result later or on another machine.
  Reproducing this setup is a checkout and a rebuild, not a weekend of
  reinstalling from memory.
- **Reversible.** Each rebuild is a new generation, so a bad change is rolled
  back by switching to the previous one rather than undoing edits by hand. That
  makes changes cheap to try.
- **Version-controlled.** The whole setup — shell (`zsh`), git, SSH, packages,
  the local LLM stack — lives in one git-tracked repository instead of scattered
  dotfiles. Every change has a history, diffs are reviewable, and the same
  configuration follows from one machine to the next.

This repository extends those principles to make the base reusable:

- **Reusable without merge conflicts.** The public base ships generic defaults
  and a `mkDarwin` builder, so a private flake (or a fork) layers its own settings
  and packages on top and still pulls upstream updates cleanly.
- **Batteries included, fully configurable.** Opinionated defaults — zsh, a local LLM stack, a Linux builder — all tuned in one `settings.nix`.
- **Clean separation.** Identity and machine-specific values live outside the
  repo, so the shared configuration stays generic and shareable.

## Features

Out of the box, configurable under `settings.nix`.

### nix-darwin + Home Manager

[nix-darwin](https://github.com/LnL7/nix-darwin) and
[Home Manager](https://github.com/nix-community/home-manager) define the system
and home environment in Nix, rebuilt with one command. Changes apply and roll
back atomically, and the same setup reproduces on another machine.

### zsh + oh-my-zsh

[zsh](https://www.zsh.org) with [oh-my-zsh](https://ohmyz.sh) brings syntax
highlighting and completions, plus a deliberate [Nix-first PATH](#path-policy) so
Nix-installed tools always take precedence over Homebrew.

### Git identity, signing, and SSH keys

Identity and signing are wired up per host, with the actual keys and identities
kept in local files outside the repo. See
[Local identity and SSH files](#local-identity-and-ssh-files) to set them up.

#### Per-host git identity

The right name and email are selected automatically for each host, so personal
and work repos commit with the correct identity, with no manual `git config`
switching.

#### SSH commit signing

Commits are
[signed with an SSH key](https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgformat)
kept in a local file, so they show as verified on GitHub/GitLab without GPG.

#### Per-host SSH keys

Each host authenticates with its own key and user via `~/.ssh/config.d/`, and the
host blocks stay out of the repo.

### Declarative Homebrew casks

GUI apps live in one declarative [Homebrew](https://brew.sh) cask list, installed
or removed on rebuild. The module is toggleable with `homebrew.enable` and
extended from a separate module.

### direnv

[direnv](https://direnv.net) loads per-project tools and variables on `cd`,
backed by the project's devShell.

### Local LLM stack

The [Pi coding agent](https://github.com/lukasl-dev/pi.nix) and Node 24 are
installed via Home Manager, backed by a local [Ollama](https://ollama.com)
server. Ollama runs as a launchd **user agent** (`modules/llm.nix`) whose bind
address, model, models directory, and log paths all come from the `ollama`
block in `settings.nix` (override them with `mkDarwin`'s `ollama` argument). The
configured model is pulled on activation when missing; activation never fails if
Ollama is unreachable, so it can be pulled later with `ollama pull <model>`.
`~/.pi/agent/` is managed outside Nix.

### Linux builder

A background NixOS VM lets `nix build --system aarch64-linux` run transparently
from macOS via Apple's Virtualization framework. Its resources are sized in
`settings.nix` (`linuxBuilder`; 40 GB sparse disk / 8 GB RAM by default). Set
`linuxBuilder.enable = false` to drop the builder, which also removes
`aarch64-linux` from `nix.settings.extra-platforms`.

## Setup

### Prerequisites

- **Nix** with flakes enabled ([official installer](https://nixos.org/download/),
  enable flakes manually; or the
  [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer),
  flakes on by default).
- **Homebrew** — required unless `homebrew.enable = false` is set. The
  configuration manages casks (via `brew bundle` on activation) but does *not*
  install Homebrew itself, so brew must be preinstalled while the module is
  enabled, even with an empty cask list. Disabling it (`settings.nix` →
  `homebrew.enable = false`) removes the requirement entirely. The zsh PATH
  integration is independent and always degrades gracefully if brew is absent.

There are two ways to build on this configuration:

- **[Use it as a flake library](#use-as-a-flake-library)** (recommended) — pin
  nixotine as an input from a separate flake. Settings, packages, and any extra
  flake inputs live in that flake's *own* repo, fully tracked and entirely
  separate from nixotine, so updates never conflict and nixotine is never edited.
  Best for almost everyone, and the bundled `nix flake new` template scaffolds it.
- **[Fork nixotine](#forking-nixotine)** — change nixotine *itself* (its modules
  or defaults), to contribute upstream or run a personal variant. A fork holds no
  machine configuration: a consumer flake points its `nixotine.url` at the fork
  (or a local checkout) and keeps the machine configuration there.

### Use as a flake library

The recommended way to build on this configuration: pin it as an input from a
private flake and call `mkDarwin` with the desired settings. Upstream files are never
edited, so there are no merge conflicts; updates land by bumping the input.

The quickest start is the bundled template, which scaffolds a ready-to-edit
consumer flake — `flake.nix`, `settings.nix`, `module.nix`, and a short
`README.md`:

```sh
nix flake new ~/cfg/nixotine-darwin -t github:jcardozo-eth/nixotine
cd ~/cfg/nixotine-darwin
# then edit settings.nix (username, system, git) and module.nix (casks, packages)
```

The named form `…/nixotine#consumer` is equivalent. The rest of this section
explains what those scaffolded files contain; the same shape can also be written
by hand.

```nix
# example/flake.nix
{
  inputs.nixotine.url = "github:jcardozo-eth/nixotine";
  outputs = { nixotine, ... }: {
    darwinConfigurations.mac = nixotine.lib.mkDarwin {
      username = "youruser"; # required
      system = "aarch64-darwin"; # required
      # Optional below — override any settings.nix default (partial is fine):
      git = {
        userName = "yourgituser";
        userEmail = "name@domain.com";
      };
      ollama = { model = "qwen3-coder:14b"; };
      extraModules = [ ./module.nix ]; # extra casks/packages
    };
  };
}
```

`mkDarwin` returns a full nix-darwin system and forwards its inputs
(home-manager, pi-nix). `extraModules` are appended after the base modules, and
because nix-darwin / Home Manager list options **merge**, casks and packages can
be extended from a separate module without touching this repo:

```nix
# example/module.nix
{ pkgs, ... }:
{
  # list options merge with the base, so these extend it rather than replace it
  homebrew.casks = [ "your-app" ];
  home-manager.users.youruser.home.packages = [ pkgs.your-tool ];
}
```

`settings.nix` here only supplies the generic defaults for the demo/CI build and
the fallback values in `mkDarwin`'s signature. It isn't edited.

**Packages from another flake.** Pulling a package from a *different* flake
(anything with a flake output, e.g. `devenv`) needs no change to nixotine: the
input lives in the consumer's own flake. Declare it there alongside `nixotine`,
then thread it into the module with `_module.args`:

```nix
# example/flake.nix
{
  inputs.nixotine.url = "github:jcardozo-eth/nixotine";
  inputs.some-flake.url = "github:owner/some-flake";
  outputs = { nixotine, some-flake, ... }: {
    darwinConfigurations.mac = nixotine.lib.mkDarwin {
      username = "youruser";
      system = "aarch64-darwin";
      extraModules = [
        ./module.nix
        { _module.args.some-flake = some-flake; } # pass the extra input to modules
      ];
    };
  };
}
```

`module.nix` then receives it as a module argument:

```nix
{ some-flake, pkgs, ... }:
{
  home-manager.users.youruser.home.packages = [
    some-flake.packages.${pkgs.system}.default
  ];
}
```

### Forking nixotine

Fork nixotine to change the configuration *itself* (a module, a default, or a new
generic feature), whether to contribute the change upstream or to run a personal
variant. A fork is nixotine's own source; it holds no machine configuration.

Running a machine on a forked nixotine keeps two repositories:

1. **The fork** — the changed nixotine. Add `upstream` as a remote to pull in
   later improvements:

   ```sh
   git remote add upstream https://github.com/jcardozo-eth/nixotine
   ```

2. **A consumer flake** — the machine configuration, scaffolded from the
   [template](#use-as-a-flake-library). Point its `nixotine.url` at the fork
   instead of upstream:

   ```nix
   nixotine.url = "github:youruser/nixotine";
   # or, while hacking on nixotine and the machine together, a local checkout:
   # nixotine.url = "path:/home/youruser/cfg/nixotine";
   ```

Settings, casks, and packages live in the consumer flake exactly as for any
consumer; only the nixotine source differs. A change to nixotine reaches the
machine on the next `nix flake update nixotine`.

**Tasks**

`just` (on PATH via `nix develop` or direnv) wraps the common workflow when
working inside the fork. The target host comes from the effective
configuration's `settings.nix` hostname.

| Recipe | Action |
|--------|--------|
| `just build` | build the configuration without switching |
| `just apply` | activate the configuration |
| `just eval` | print the system derivation path |
| `just check` | `nix flake check` + format check |
| `just fmt` | format all Nix files |
| `just update` | update flake inputs |
| `just sync` | `git pull upstream main` |

**Adding a flake input to the fork**

An input that a fork's *own module* uses (because the feature belongs in nixotine
itself) is declared in the fork's `flake.nix` `inputs`. Every input is threaded
into the modules as the `inputs` argument, so a module references it as
`inputs.<name>`, with no call-site or wiring change:

```nix
inputs = {
  # … existing inputs …
  some-flake.url = "github:owner/some-flake";
};
```

```nix
{ inputs, pkgs, ... }:
{
  home-manager.users.youruser.home.packages = [
    inputs.some-flake.packages.${pkgs.system}.default
  ];
}
```

A package for a single machine does not belong in the fork: declare that input in
the consumer flake instead (see the consumer template's `README.md`).

### Applying the configuration

Build and switch the configuration: from a fork with `just apply`, or from a
consumer flake with `darwin-rebuild`:

```sh
sudo darwin-rebuild switch --flake .#<your-host>   # or, in a fork: just apply
```

This repo's own `darwinConfigurations.mac` is built from the **generic
placeholder settings**, so it exists only to verify that the configuration
evaluates and builds. Evaluating or building is harmless: it computes the system
in the Nix store without touching the machine. Do **not** `switch` it on a local
machine, though. `switch` *activates* the entire configuration on the machine —
system settings, packages, Homebrew casks, login shell, launchd agents, and the
placeholder username and git identity. Run `switch` only from a fork or consumer
flake, where the settings hold real values.

```sh
nix flake check
nix eval .#darwinConfigurations.mac.system.drvPath
darwin-rebuild build --flake .#mac   # build only — never switch the demo
```

### Local identity and SSH files

Identity-bearing files (git, ssh) are created locally and kept out of the repo.
The tracked modules wire up only the *mechanism* — `git` and `ssh` silently skip
includes whose files are absent — so each is **optional**. Copy-paste templates
follow; replace the placeholders.

**Per-host git identity.** Add a host to `git.hosts` (in the consumer flake's
`settings.nix`), and `git.nix` routes it to `~/.config/git/<file>` via
`includeIf`, so the right name and email are selected automatically per host.
Drop a `[user]` block in the matching file:

```ini
# ~/.config/git/github.gitconfig
[user]
  name  = yourgituser
  email = name@personal.example
```

For hosts not in `settings.git.hosts` (e.g. a self-hosted organization GitLab
instance), add unconditional routing via `~/.config/git/local.gitconfig`:

```ini
# ~/.config/git/local.gitconfig
[includeIf "hasconfig:remote.*.url:git@git.example.org:**"]
  path = ~/.config/git/work.gitconfig
```

**Commit signing.** `git.nix` includes `~/.config/git/signing.gitconfig`
unconditionally; it keeps
the signing-key path out of the repo:

```ini
# ~/.config/git/signing.gitconfig
[gpg]
  format = ssh
[user]
  signingKey = ~/.ssh/id_ed25519.pub
[commit]
  gpgsign = true
```

**SSH hosts.** `ssh.nix` carries only global defaults plus `Include config.d/*`,
so every per-host block — hostname, user, and identity key — lives in
`~/.ssh/config.d/`:

```
# ~/.ssh/config.d/git
Host github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```

## Architecture

The pieces fit together like this:

- **`settings.nix`** holds the upstream's generic default values (user, host,
  `git`, `ollama`, `linuxBuilder`, `zsh`, `homebrew`); a consumer overrides them
  through `mkDarwin` arguments rather than editing this file.
- **`flake.nix`** imports those settings, derives the home directory and
  `darwin-rebuild` target, and builds the system through `mkDarwin` — the base
  modules plus any `extraModules`, with list options (casks, packages) merging
  across modules.
- **Overrides** layer over the defaults through one shared, one-level-deep merge,
  applied to a consumer's `mkDarwin` arguments.

### Module layout

`flake.nix`'s base modules are loaded in order:

- **`modules/system.nix`** — nix-darwin system settings: Nix configuration,
  binary caches, and automatic GC/optimise.
- **`modules/linux-builder.nix`** — the `linux-builder` VM and the matching
  `aarch64-linux` entry in `nix.settings.extra-platforms`.
- **`modules/user.nix`** — the user account and Home Manager wiring (a thin
  wrapper that imports the `home/` modules).
- **`modules/home/`** — per-user Home Manager modules: `zsh.nix`, `git.nix`,
  `ssh.nix`, `direnv.nix`.
- **`modules/homebrew.nix`** — the Homebrew (casks) integration.
- **`modules/llm.nix`** — the Pi agent, the Ollama launchd service, and Node 24.

A consumer's `extraModules` are appended after these, and list options merge
across all of them.

### Platform (Apple Silicon)

The configuration targets
[`aarch64-darwin`](https://en.wikipedia.org/wiki/AArch64) (Apple Silicon), and a
few places assume it: the Homebrew prefix is `/opt/homebrew`, and the Linux
builder cross-builds `aarch64-linux`.

### PATH policy

PATH precedence is, deliberately, **Nix first → system directories → Homebrew
last**.
The declarative Nix layer is the source of truth; Homebrew is kept as a
casks-only escape hatch. `.zshenv` *appends* the baseline macOS directories so
Nix paths always win, and the Homebrew block in zsh init appends after them.

## Contributing

Improvements to nixotine are welcome — see
[CONTRIBUTING.md](CONTRIBUTING.md), including its
[CI and automation](CONTRIBUTING.md#ci-and-automation) overview.
