{ lib, linuxBuilder, ... }:

{
  # Linux builder VM for transparent aarch64-linux builds. Runs a NixOS VM via
  # Apple's Virtualization.framework so `nix build --system aarch64-linux ...`
  # works directly from macOS. Resource caps come from settings.nix.
  nix.linux-builder = {
    enable = linuxBuilder.enable;
    maxJobs = linuxBuilder.maxJobs;
    config = {
      virtualisation = {
        darwin-builder = {
          diskSize = linuxBuilder.diskMiB;
          memorySize = linuxBuilder.memoryMiB;
        };
        cores = linuxBuilder.cores;
      };
    };
    # Build features advertised to the scheduler
    supportedFeatures = [
      "kvm"
      "big-parallel"
      "benchmark"
      "nixos-test"
    ];
  };

  # Allow building for aarch64-linux on this host — only meaningful while the
  # builder above is enabled, else nix would try (and fail) to build locally.
  nix.settings.extra-platforms = lib.optionals linuxBuilder.enable [ "aarch64-linux" ];
}
