# nix-darwin configuration

A personal [nix-darwin] + [Home Manager] configuration built on
[nixotine](https://github.com/jcardozo-eth/nixotine), pinned as a flake input.

## Layout

- **`flake.nix`** — flake inputs (nixotine, plus any extra package sources) and a
  one-line `mkDarwin` call. Edited rarely.
- **`settings.nix`** — machine settings: `username`, `system`, the `git` identity,
  and any other override of a nixotine default.
- **`module.nix`** — this machine's Homebrew casks and packages. The file to edit
  for package changes.
- **`justfile`** — `just` recipes for the common workflow (`build`, `apply`,
  `eval`, `check`, `update`); `nix develop` or direnv puts `just` on PATH.

## Setup

1. Edit `settings.nix`: set `username` (the macOS login name) and the `git`
   identity. The `mac` in `darwinConfigurations.mac` is just the label for
   `darwin-rebuild --flake .#mac`, not a real hostname; rename it freely (along
   with the `.#mac` below) or leave it as-is. For multiple git identities (a
   different name/email per host) and SSH key setup, see nixotine's
   [identity and SSH guide].
2. Edit `module.nix`: add casks and packages.
3. Verify (this builds in the Nix store and does not touch the machine):

   ```sh
   nix flake check
   nix eval .#darwinConfigurations.mac.system.drvPath
   darwin-rebuild build --flake .#mac
   ```
4. Activate:

   ```sh
   sudo darwin-rebuild switch --flake .#mac
   ```

## Tasks

`just` (on PATH via `nix develop`, or automatically with [direnv] through the
bundled `.envrc`) wraps the common workflow:

| Recipe | Action |
|--------|--------|
| `just build` | build the configuration without switching |
| `just apply` | activate the entire machine (prompts first) |
| `just eval` | print the system derivation path |
| `just check` | `nix flake check` + format check |
| `just fmt` | format all Nix files |
| `just update` | bump nixotine to its latest commit |

## Adding a package from another flake

Packages from `nixpkgs` go straight into `module.nix`. A package from a
*different* flake (for example `devenv`) needs its input declared in `flake.nix`,
because flake inputs are fetched before evaluation and cannot live in
`module.nix`:

1. Declare the input in `flake.nix`:

   ```nix
   inputs.devenv.url = "github:cachix/devenv";
   ```
2. Hand it to the modules in the `extraModules` list:

   ```nix
   { _module.args.devenv = inputs.devenv; }
   ```
3. Reference it from `module.nix` (add `devenv` to the argument set):

   ```nix
   { pkgs, username, devenv, ... }:
   {
     home-manager.users.${username}.home.packages = [
       devenv.packages.${pkgs.system}.devenv
     ];
   }
   ```

## Updating

```sh
nix flake update nixotine   # bump nixotine to its latest commit (or: just update)
```

[nix-darwin]: https://github.com/LnL7/nix-darwin
[Home Manager]: https://github.com/nix-community/home-manager
[direnv]: https://direnv.net
[identity and SSH guide]: https://github.com/jcardozo-eth/nixotine#local-identity-and-ssh-files
