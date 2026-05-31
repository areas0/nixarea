{
  lib,
  pkgs,
  additionalConfig,
  ...
}:
let
  enable = additionalConfig.enableLocalLLM or false;
in
lib.mkIf enable {
  home.packages = [ pkgs.aider-chat ];

  # Default to the local Ollama backend. Model must be pulled separately:
  #   ollama pull qwen2.5-coder:14b
  home.file.".aider.conf.yml".text = ''
    model: ollama_chat/qwen2.5-coder:14b
    map-tokens: 4096
    analytics-disable: true
  '';

  home.sessionVariables.OLLAMA_API_BASE = "http://127.0.0.1:11434";
}
