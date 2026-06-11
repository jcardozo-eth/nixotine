# nixpkgs overlays applied to the configuration (see modules/system.nix).
[
  (import ./overlays/ollama.nix)
]
