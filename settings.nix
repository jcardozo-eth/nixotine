# Default settings for the public upstream: generic placeholders, overridden by a
# consumer's mkDarwin arguments (see README "Use as a flake library"). flake.nix
# derives the home directory, the darwin-rebuild target, and the Home Manager
# user from these.
{
  # Login name of the primary user (also the Home Manager user)
  username = "user";

  # Host label / darwin-rebuild target: `darwin-rebuild switch --flake .#<hostname>`
  hostname = "mac";

  # Build platform. This configuration targets Apple Silicon ("aarch64-darwin"); some
  # modules (Homebrew prefix, the aarch64-linux builder) assume it.
  system = "aarch64-darwin";

  # Default git identity. Generic placeholder here — pass `git = { … }` to
  # mkDarwin to set a real name/email. Per-host identities (and signing) live in
  # local, untracked files.
  git = {
    userName = "Your Name";
    userEmail = "you@example.com";

    # Per-host identity routing. For each entry git.nix generates includeIf
    # rules (ssh / scp / https URL forms) pointing at a local, untracked
    # ~/.config/git/<file>; drop a [user] block there to use a different
    # identity for that host. Add or replace hosts freely (an organization's
    # git host, a self-hosted forge, …) — nothing here is github/gitlab-specific.
    hosts = [
      {
        host = "github.com";
        file = "github.gitconfig";
      }
      {
        host = "gitlab.com";
        file = "gitlab.gitconfig";
      }
    ];
  };

  # Linux builder VM (nix-darwin) for transparent aarch64-linux cross-builds.
  # Resource caps are sized for this machine; tune them for yours. Set
  # enable = false to drop the builder entirely (aarch64-linux is then also
  # removed from nix's extra-platforms).
  linuxBuilder = {
    enable = true;
    cores = 8;
    memoryMiB = 8 * 1024; # 8 GB RAM
    diskMiB = 40 * 1024; # 40 GB sparse disk (grows on demand)
    maxJobs = 8;
  };

  # Homebrew (GUI casks). When enabled, nix-darwin manages casks and runs
  # `brew bundle` on activation — which requires Homebrew to be installed, even
  # with an empty cask list. Set enable = false to drop the module entirely;
  # then Homebrew is not needed at all.
  homebrew = {
    enable = true;
  };

  # zsh appearance
  zsh = {
    # oh-my-zsh theme name
    theme = "robbyrussell";
    # oh-my-zsh plugins to enable. Generic defaults only — add tool-specific
    # ones (kubectl, docker, …) here or via a fork/consumer override.
    omzPlugins = [
      "git"
      "z"
    ];
  };

  # Ollama launchd service
  ollama = {
    # OLLAMA_HOST — bind address:port the agent listens on
    host = "127.0.0.1:11434";

    # Model pulled on activation when missing
    model = "qwen3-coder:14b";

    # OLLAMA_MODELS store; null → "<home>/.ollama/models"
    modelsDir = null;

    # launchd stdout/stderr log paths
    stdoutLog = "/tmp/ollama.log";
    stderrLog = "/tmp/ollama.err.log";
  };
}
