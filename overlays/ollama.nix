# Override nixpkgs' `ollama` with the upstream prebuilt macOS release, so the
# newest ollama (and the current models that need it) is available rather than
# the older one nixpkgs ships. Bump `version` to update; drop this overlay once
# nixpkgs is current.
final: prev:

let
  version = "0.30.7";
in
{
  ollama = prev.stdenvNoCC.mkDerivation {
    pname = "ollama";
    inherit version;

    src = prev.fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-darwin.tgz";
      hash = "sha256-+js4LkuQxZXh9HPG3yzR7K0nDE0EIl9rBp5bhqEPPTM=";
    };

    nativeBuildInputs = [ prev.makeWrapper ];

    # The release tarball is flat: the `ollama` binary sits next to its runner
    # libraries (libggml*, libllama*) and Metal shaders (mlx_metal_*/), which it
    # resolves via @executable_path. Keep the whole tree together under lib/ and
    # expose a thin bin/ollama wrapper into it; never modify the signed binaries.
    unpackPhase = ''
      runHook preUnpack
      mkdir -p source
      tar --warning=no-unknown-keyword -xzf "$src" -C source
      runHook postUnpack
    '';
    sourceRoot = "source";

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/ollama" "$out/bin"
      cp -R . "$out/lib/ollama/"
      makeWrapper "$out/lib/ollama/ollama" "$out/bin/ollama"
      runHook postInstall
    '';

    meta = {
      description = "Run large language models locally (upstream prebuilt macOS release)";
      homepage = "https://ollama.com";
      license = prev.lib.licenses.mit;
      mainProgram = "ollama";
      platforms = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      sourceProvenance = [ prev.lib.sourceTypes.binaryNativeCode ];
    };
  };
}
