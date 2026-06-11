# nixotine

> **Status: alpha.** Actively developed; expect occasional breaking changes.

An **opinionated and reusable** [nix-darwin](https://github.com/LnL7/nix-darwin) +
[Home Manager](https://github.com/nix-community/home-manager) configuration for Apple Silicon Mac. It bakes in a particular set of tooling and
conventions; everything machine- and user-specific is configurable, so it
can be adopted wholesale, cherry-picked from, or used as inspiration. The
public repo ships generic defaults and exports a `mkDarwin` builder, so it can be
[used as a flake library](#use-as-a-flake-library).

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

Build on nixotine by pinning it as a flake input from a separate flake and
calling `mkDarwin`; the bundled `nix flake new` template scaffolds exactly that.
Settings, packages, and any extra flake inputs live in that flake's *own* repo,
fully tracked and separate from nixotine, so updates never conflict and nixotine
is never edited.

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
# flake.nix — thin; rarely edited
{
  inputs.nixotine.url = "github:jcardozo-eth/nixotine";
  outputs = { nixotine, ... }: {
    darwinConfigurations.mac = nixotine.lib.mkDarwin (
      import ./settings.nix // { extraModules = [ ./module.nix ]; }
    );
  };
}
```

`settings.nix` holds the machine parameters. Only `username` and `system` are
required; any other key overrides a nixotine default (partial is fine):

```nix
# settings.nix
{
  username = "youruser"; # required
  system = "aarch64-darwin"; # required
  git = {
    userName = "yourgituser";
    userEmail = "name@domain.com";
  };
  # ollama.model = "qwen3-coder:30b";
}
```

`mkDarwin` returns a full nix-darwin system and forwards its inputs (home-manager,
pi-nix). `extraModules` are appended after the base modules, and because
nix-darwin / Home Manager list options **merge**, casks and packages extend the
base from `module.nix` without touching this repo:

```nix
# module.nix
{ pkgs, ... }:
{
  # list options merge with the base, so these extend it rather than replace it
  homebrew.casks = [ "firefox" ];
  home-manager.users.youruser.home.packages = [ pkgs.ripgrep ];
}
```

Then activate it from the configuration's own directory with `just apply`. The
template's [README](templates/consumer/README.md) is a full walkthrough from
setup to activation.

**Packages from another flake.** Pulling a package from a *different* flake (for
example [devenv](https://github.com/cachix/devenv)) needs no change to nixotine:
the input lives in the consumer's own flake. Declare it there alongside
`nixotine`, then thread it into the module with `_module.args`:

```nix
# flake.nix
{
  inputs.nixotine.url = "github:jcardozo-eth/nixotine";
  inputs.devenv.url = "github:cachix/devenv";
  outputs = { nixotine, devenv, ... }: {
    darwinConfigurations.mac = nixotine.lib.mkDarwin (
      import ./settings.nix
      // {
        extraModules = [
          ./module.nix
          { _module.args.devenv = devenv; } # pass the extra input to modules
        ];
      }
    );
  };
}
```

`module.nix` then receives it as a module argument:

```nix
{ devenv, pkgs, ... }:
{
  home-manager.users.youruser.home.packages = [
    devenv.packages.${pkgs.system}.devenv
  ];
}
```

**Using your own fork.** To customize nixotine itself, fork it; then in your
configuration's `flake.nix` (the directory scaffolded from the template), point
`nixotine.url` at your fork instead of upstream — nothing else changes:

```nix
nixotine.url = "github:youruser/nixotine";
# or a local checkout, while hacking on nixotine and the machine together
# (path: needs an absolute path):
# nixotine.url = "path:/Users/youruser/code/nixotine";
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
