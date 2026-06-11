{ config, git, ... }:

let
  # Path to a hand-maintained, untracked gitconfig under ~/.config/git/.
  local = name: "${config.home.homeDirectory}/.config/git/${name}";

  # Route every remote-URL form (ssh://, scp-style, https) for a host to a
  # local per-host gitconfig. Drop a [user] block in that file to use a
  # different identity for the host; git ignores any include whose file is
  # absent, so the default identity applies otherwise.
  hostIncludes =
    { host, file }:
    {
      "hasconfig:remote.*.url:ssh://git@${host}/**".path = local file;
      "hasconfig:remote.*.url:git@${host}:**".path = local file;
      "hasconfig:remote.*.url:https://${host}/**".path = local file;
    };

  # Hosts to wire up, from settings (`git.hosts`). Nothing here is forge-specific;
  # the default host list (and any additions) lives in settings.nix.
  hosts = git.hosts or [ ];
in
{
  programs.git = {
    enable = true;

    # Default identity comes from settings (generic placeholder upstream; real
    # values come from a fork's settings.local.nix or mkDarwin's `git` arg).
    userName = git.userName;
    userEmail = git.userEmail;

    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;

      # Per-host identity overrides, generated from `git.hosts`.
      includeIf = builtins.foldl' (acc: h: acc // hostIncludes h) { } hosts;

      # Unconditional local includes (also untracked, also ignored when
      # absent): local.gitconfig holds any machine-local git settings (extra
      # includeIf routing, aliases, overrides); signing.gitconfig holds the
      # commit-signing key path.
      include.path = [
        (local "local.gitconfig")
        (local "signing.gitconfig")
      ];
    };
  };
}
