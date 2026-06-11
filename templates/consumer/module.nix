# Casks and packages for this machine. Both are list options, so they merge with
# the nixotine base rather than replacing it. This is the file to edit for
# package changes.
{
  pkgs,
  username,
  ...
}:
{
  # GUI apps (Homebrew casks). Examples below — uncomment what is wanted.
  homebrew.casks = [
    # "firefox"
    # "vscodium"
  ];

  # CLI tools (Home Manager packages). Examples below — uncomment what is wanted.
  home-manager.users.${username}.home.packages = with pkgs; [
    # ripgrep
    # fzf
    # jq
    # tree
  ];

  # Package from an extra flake input (see flake.nix): once the input is wired
  # through `_module.args`, add it to the argument set above (e.g. add `devenv`
  # next to `pkgs`) and reference it here, for example:
  #
  #   home-manager.users.${username}.home.packages = [
  #     devenv.packages.${pkgs.system}.devenv
  #   ];
}
