{ ... }:

{
  programs.ssh = {
    enable = true;

    # Every host-specific setting — hostnames, usernames, identity files —
    # lives in hand-maintained drop-ins under ~/.ssh/config.d/ and is kept
    # out of this public repo. One file per context (e.g. config.d/git,
    # config.d/work). Home Manager emits an Include for them (resolved by
    # OpenSSH relative to ~/.ssh).
    includes = [ "config.d/*" ];

    # Global defaults only. UseKeychain is macOS-only (Apple's OpenSSH): it
    # stores and loads the key passphrase in the login Keychain.
    extraConfig = ''
      Host *
        SendEnv LANG LC_ALL
        AddKeysToAgent yes
        UseKeychain yes
    '';
  };
}
