{
  description = "An opinionated and reusable nix-darwin + Home Manager configuration for macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Pi coding agent (pins its own nixpkgs deliberately — pi's package needs
    # newer packages like typescript-go that aren't in nixpkgs-25.05, so do
    # NOT add an inputs.nixpkgs.follows here)
    pi-nix.url = "github:lukasl-dev/pi.nix";

    # ── Fork-local inputs ──────────────────────────────────────────────────
    # Upstream keeps this region empty. In a fork, add extra flakes here (e.g.
    # claude-code-nix, devenv). Every input is threaded to a fork's modules via the
    # `inputs` arg (see CONTRIBUTING.md), so adding the line below is the ONLY
    # edit a fork makes to this file — no call-site or wiring changes.
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      home-manager,
      pi-nix,
      ...
    }:
    let
      # This repo's settings: the generic defaults from settings.nix. The repo's
      # own machine and the CI/demo target build from these; a consumer overrides
      # them by passing arguments to mkDarwin (see the README, "Use as a flake
      # library").
      settings = import ./settings.nix;

      # The single rule for how overrides layer over a base: replace at the top
      # level, but merge the nested sets one level deep so a caller can set just
      # `git.userName` (or `ollama.model`, `linuxBuilder.cores`, …) without
      # restating the whole block. The merge is shallow, so a list-valued nested
      # key like `git.hosts` is replaced wholesale, not concatenated. Used for a
      # consumer's mkDarwin arguments.
      nestedSets = [
        "git"
        "ollama"
        "linuxBuilder"
        "zsh"
        "homebrew"
      ];
      layerSettings =
        base: over:
        base
        // over
        // builtins.listToAttrs (
          map (n: {
            name = n;
            value = (base.${n} or { }) // (over.${n} or { });
          }) nestedSets
        );

      # This repo's modules, in order. mkDarwin appends a consumer's
      # extraModules after these; list options (homebrew.casks,
      # home.packages, …) merge across modules, so a downstream consumer
      # extends the configuration from their own module without editing this repo.
      baseModules = [
        ./modules/system.nix
        ./modules/linux-builder.nix
        ./modules/user.nix
        "${home-manager}/nix-darwin"
        ./modules/homebrew.nix
        ./modules/llm.nix
      ];

      # Reusable builder (the library entry point). Downstream consumers pin
      # this flake as an input and call it with their own settings (see the
      # README, "Use as a flake library"). They inherit this flake's inputs
      # (pi-nix, home-manager) through the closure and never touch upstream
      # files. `hostname` is only used as the attribute name below, so mkDarwin
      # ignores it (absorbed by `...`).
      mkDarwin =
        {
          username,
          system,
          git ? { },
          ollama ? { },
          linuxBuilder ? { },
          zsh ? { },
          homebrew ? { },
          extraModules ? [ ],
          ...
        }:
        let
          homeDirectory = "/Users/${username}";

          # Layer the caller's overrides over the settings defaults with the
          # same rule as the fork path, so passing just `git.userName` (or
          # `linuxBuilder.cores`, `ollama.model`, …) keeps the rest of the block.
          # Omitting an arg (`? { }`) leaves that default untouched.
          merged = layerSettings settings {
            inherit
              git
              ollama
              linuxBuilder
              zsh
              homebrew
              ;
          };

          # Resolve the home-relative OLLAMA_MODELS default when left unset.
          resolvedOllama = merged.ollama // {
            modelsDir =
              if merged.ollama.modelsDir != null then
                merged.ollama.modelsDir
              else
                "${homeDirectory}/.ollama/models";
          };
        in
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit
              pi-nix
              username
              system
              homeDirectory
              ;
            inherit (merged)
              git
              linuxBuilder
              zsh
              homebrew
              ;
            ollama = resolvedOllama;

            # All flake inputs, so a fork's extraModules can pull packages from
            # any input it adds — referenced as `inputs.<name>`, with no change
            # to this call. See CONTRIBUTING.md.
            inherit inputs;
          };
          modules = baseModules ++ extraModules;
        };
    in
    {
      # Library entry point for downstream consumers
      lib.mkDarwin = mkDarwin;

      # This repo's own machine, and the CI/demo target. Built through the
      # same mkDarwin from the generic settings.nix.
      darwinConfigurations.${settings.hostname} = mkDarwin settings;

      # Formatter for both the dev machine (aarch64-darwin) and the CI runner
      # (x86_64-linux, ubuntu-latest), so `nix fmt -- --check` works in both.
      formatter = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
      );

      # `nix develop` (or direnv via the tracked .envrc) puts `just` on PATH
      # for the repo's own tasks — no global install needed. Apple Silicon only,
      # matching the configuration's target platform.
      devShells.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShellNoCC {
        packages = [ nixpkgs.legacyPackages.aarch64-darwin.just ];
      };
    };
}
