{
  description = "An opinionated and reusable nix-darwin + Home Manager configuration for macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Pi coding agent. Follows the flake's nixpkgs: 26.05 carries everything
    # pi builds against (e.g. typescript-go). Trade-off: pi builds from source
    # instead of fetching prebuilt from pi.cachix.org, but only on a deliberate
    # update.
    pi-nix.url = "github:lukasl-dev/pi.nix";
    pi-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Pre-commit hooks (dev-only): installs a git hook that formats staged Nix
    # files, so CI never fails on formatting. Wired into the devShell below.
    # Deliberately NOT pinned to our nixpkgs: git-hooks' tool set references
    # packages absent from nixpkgs-25.05 (e.g. cspell), so it uses its own
    # validated nixpkgs. Its nixfmt is the same formatter `nix fmt` (nixfmt-tree)
    # wraps, so the hook and the flake formatter produce identical output.
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      home-manager,
      pi-nix,
      git-hooks,
      ...
    }:
    let
      # Dev machine platform: the devShell and pre-commit hooks are macOS-only.
      devSystem = "aarch64-darwin";
      devPkgs = nixpkgs.legacyPackages.${devSystem};

      # Pre-commit hook: format staged Nix files with nixfmt — the same tool
      # `nix fmt` (nixfmt-tree) wraps, so output is identical. The hook only ever
      # sees staged files, so it never touches the gitignored .direnv/ vendored
      # sources. (We use the nixfmt-rfc-style hook rather than git-hooks' treefmt
      # hook: the latter pulls a full treefmt whose dotnet-based formatters fail
      # to build on this nixpkgs pin.) The devShell's shellHook installs it;
      # bypass with `git commit --no-verify`.
      preCommitCheck = git-hooks.lib.${devSystem}.run {
        src = ./.;
        hooks.nixfmt-rfc-style.enable = true;
      };

      # This repo's settings: the generic defaults from settings.nix. The repo's
      # own machine and the CI/demo target build from these; a consumer overrides
      # them by passing arguments to mkDarwin (see the README, "Use as a flake
      # library": https://github.com/jcardozo-eth/nixotine#use-as-a-flake-library).
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

      # Scaffold for downstream consumers. `nix flake init -t
      # github:jcardozo-eth/nixotine#consumer` (or bare, via the default alias)
      # copies a ready-to-edit consumer flake (flake.nix + settings.nix +
      # module.nix + README) that pins this flake and calls mkDarwin.
      templates =
        let
          consumer = {
            path = ./templates/consumer;
            description = "Consumer flake that pins nixotine and calls mkDarwin";
          };
        in
        {
          inherit consumer;
          default = consumer;
        };

      # This repo's own machine, and the CI/demo target. Built through the
      # same mkDarwin from the generic settings.nix.
      darwinConfigurations.${settings.hostname} = mkDarwin settings;

      # Formatter for both the dev machine (aarch64-darwin) and the CI runner
      # (x86_64-linux, ubuntu-latest). nixfmt-tree wraps nixfmt in treefmt, which
      # walks the git tree and honours .gitignore — so `nix fmt` skips vendored
      # sources under .direnv/ that plain nixfmt would try (and fail) to format.
      # Check mode is `nix fmt -- --ci` (exits non-zero on any change).
      formatter = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        system: nixpkgs.legacyPackages.${system}.nixfmt-tree
      );

      # `nix develop` (or direnv via the tracked .envrc) puts `just` on PATH
      # for the repo's own tasks — no global install needed. Apple Silicon only,
      # matching the configuration's target platform. Entering the shell also
      # installs the pre-commit hook (shellHook) so staged Nix stays formatted.
      devShells.${devSystem}.default = devPkgs.mkShellNoCC {
        packages = [ devPkgs.just ] ++ preCommitCheck.enabledPackages;
        shellHook = preCommitCheck.shellHook;
      };
    };
}
