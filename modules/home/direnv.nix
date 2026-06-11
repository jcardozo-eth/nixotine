{ ... }:

{
  # direnv + nix-direnv with zsh integration (silent activation)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    silent = true;
  };
}
