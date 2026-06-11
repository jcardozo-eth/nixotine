{
  description = "A personal nix-darwin configuration built on nixotine";

  inputs = {
    nixotine.url = "github:jcardozo-eth/nixotine";

    # Extra package sources (optional). Any flake that is NOT nixpkgs and NOT a
    # nixotine input must be declared here: flake inputs are fetched before
    # evaluation, so they cannot live in settings.nix or module.nix. To use one,
    # uncomment the example below (replacing devenv with the flake wanted), then
    # wire it through extraModules (below) and reference it from module.nix.
    #
    # Example:
    #   devenv.url = "github:cachix/devenv";
  };

  outputs =
    inputs@{ nixotine, ... }:
    let
      # This template targets Apple Silicon; reuse nixotine's already-locked
      # nixpkgs so the dev outputs below add no extra flake input.
      system = "aarch64-darwin";
      pkgs = nixotine.inputs.nixpkgs.legacyPackages.${system};
    in
    {
      # Settings live in settings.nix; casks and packages live in module.nix.
      darwinConfigurations.mac = nixotine.lib.mkDarwin (
        import ./settings.nix
        // {
          extraModules = [
            ./module.nix

            # To use a package from an extra flake input (declared above), hand
            # it to the modules here, then reference it from module.nix:
            # { _module.args.devenv = inputs.devenv; }
          ];
        }
      );

      # Reuse nixotine's formatter so `nix fmt` (and `just fmt` / `just check`)
      # work without declaring nixpkgs as a direct input.
      formatter.${system} = nixotine.formatter.${system};

      # `nix develop` (or direnv via .envrc) puts `just` on PATH for the recipes
      # in ./justfile — no global install needed.
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [ pkgs.just ];
      };
    };
}
