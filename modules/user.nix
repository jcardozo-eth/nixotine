{
  pkgs,
  username,
  homeDirectory,
  git,
  zsh,
  ...
}:

{
  # Primary user account; the login shell is the Nix-managed zsh.
  users.users.${username} = {
    name = username;
    home = homeDirectory;
    shell = pkgs.zsh;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    # Forward the settings blocks the home modules consume (`zsh` here is the
    # settings block, distinct from the pkgs.zsh package above).
    extraSpecialArgs = {
      inherit git zsh;
    };

    users.${username} = {
      home.stateVersion = "25.05";
      imports = [
        ./home/zsh.nix
        ./home/git.nix
        ./home/ssh.nix
        ./home/direnv.nix
      ];
    };
  };
}
