# Machine settings, passed to nixotine's mkDarwin. Set only what differs from the
# nixotine defaults; nested sets (git, ollama, linuxBuilder, zsh, homebrew) merge
# one level deep, so a single key can be overridden without restating the block.
{
  username = "youruser"; # required: the macOS login name
  system = "aarch64-darwin"; # required: Apple Silicon

  # Default git identity. For a different name/email per host (e.g. work vs
  # personal), add a `hosts` list here and set each host's identity in a local
  # file — see nixotine's "Local identity and SSH files" docs:
  # https://github.com/jcardozo-eth/nixotine#local-identity-and-ssh-files
  git = {
    userName = "yourgituser";
    userEmail = "name@domain.com";
  };

  # Optional nested overrides (uncomment to change nixotine defaults):
  # ollama.model = "qwen3-coder:30b";
  # linuxBuilder.cores = 8;
}
