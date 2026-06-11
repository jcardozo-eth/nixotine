{ pkgs, zsh, ... }:

{
  programs.zsh = {
    enable = true;

    # Baseline macOS PATH for environments that start nearly empty
    # (e.g. some IDE-spawned terminals) — appended so Nix paths keep precedence.
    envExtra = ''
      export PATH="''${PATH:+$PATH:}/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
      mkdir -p "$HOME/.cache/zsh"
      export ZSH_COMPDUMP="$HOME/.cache/zsh/zcompdump"
    '';

    # Homebrew (casks only) deliberately sits AFTER Nix in PATH:
    # the declarative layer is the source of truth.
    initContent = ''
      if [ -x /opt/homebrew/bin/brew ]; then
        export HOMEBREW_PREFIX="/opt/homebrew"
        export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
        export HOMEBREW_REPOSITORY="/opt/homebrew"
        export PATH="$PATH:/opt/homebrew/bin:/opt/homebrew/sbin"
        export MANPATH="/opt/homebrew/share/man''${MANPATH:+:$MANPATH}:"
        export INFOPATH="/opt/homebrew/share/info:''${INFOPATH:-}"
      fi
    '';

    # Theme and plugin list come from settings.nix (settings.zsh).
    oh-my-zsh = {
      enable = true;
      theme = zsh.theme;
      plugins = zsh.omzPlugins;
    };

    # Extra plugins sourced from nixpkgs (`.src`), so nixpkgs owns the version
    # pin instead of a hand-written fetchFromGitHub.
    plugins = [
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting.src;
      }
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions.src;
      }
    ];
  };
}
