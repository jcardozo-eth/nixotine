{
  pkgs,
  pi-nix,
  username,
  ollama,
  ...
}:

{
  # Ollama as an autostarted launchd user agent, listening on ollama.host
  launchd.user.agents.ollama = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.ollama}/bin/ollama"
        "serve"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = ollama.stdoutLog;
      StandardErrorPath = ollama.stderrLog;
      EnvironmentVariables = {
        OLLAMA_HOST = ollama.host;
        OLLAMA_MODELS = ollama.modelsDir;
      };
    };
  };

  home-manager.users.${username} =
    { lib, ... }:
    {
      home.packages = [
        pi-nix.packages.${pkgs.system}.default # the Pi agent
        pkgs.ollama # CLI on PATH (the launchd agent above runs the server)
        pkgs.nodejs_24 # Node runtime Pi drives
      ];

      # Pull the configured model once ollama is reachable; never fail
      # activation — warn and move on if ollama is down or the pull fails.
      home.activation.pullOllamaModel = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        export PATH="${pkgs.ollama}/bin:$PATH"
        export OLLAMA_HOST="${ollama.host}"

        # Wait up to ~10s (5 attempts, 2s apart) for the launchd agent.
        ollama_ready() {
          for _i in {1..5}; do
            ollama list >/dev/null 2>&1 && return 0
            sleep 2
          done
          return 1
        }

        if ! ollama_ready; then
          echo "warning: ollama unreachable; run 'ollama pull ${ollama.model}' later"
        elif ! ollama list | awk '{ print $1 }' | grep -qxF "${ollama.model}"; then
          run ollama pull ${ollama.model} || echo "warning: 'ollama pull ${ollama.model}' failed; retry later"
        fi
      '';
    };
}
