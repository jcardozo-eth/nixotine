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
    };
}
