{ homebrew, ... }:

let
  cfg = homebrew; # settings.homebrew
in
{
  homebrew = {
    # Enabled by default; set settings.homebrew.enable = false to skip Homebrew
    # entirely (then brew need not be installed).
    enable = cfg.enable;

    # Casks are removed on activation when not listed here, so the list is
    # authoritative. Casks are personal app choices — add them in a fork's
    # module.local.nix or a consumer's extraModules (homebrew.casks is a list
    # option, so they merge).
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
    };

    casks = [ ];
  };
}
