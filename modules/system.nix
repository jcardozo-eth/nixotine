{
  pkgs,
  username,
  system,
  ...
}:

{
  # System-level tools, available to every user (including root during
  # activation); the primary user's git is configured via Home Manager.
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  # Enable flakes and the unified `nix` command.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Pre-declare binary caches statically so unprivileged users don't need
  # trust to use them. Add new caches here as projects need them.
  nix.settings.substituters = [
    "https://cache.nixos.org/"
    "https://pi.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
  ];

  # Garbage-collect the store on a schedule; deduplicate it (hard-link identical
  # files) on each build.
  nix.gc.automatic = true;
  nix.optimise.automatic = true;

  # nix-darwin state version — pins defaults to a release; bump only after
  # reading the nix-darwin changelog, not casually.
  system.stateVersion = 5;

  system.primaryUser = username;

  nixpkgs.config.allowUnfree = true;

  # Set the build platform explicitly (otherwise inferred from the build host).
  nixpkgs.hostPlatform = system;
}
