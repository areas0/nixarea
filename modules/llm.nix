{ pkgs-unstable, ... }:
{
  services.ollama = {
    enable = true;
    # ollama-cuda is the CUDA-enabled variant (pkgs-unstable.ollama is CPU-only).
    # As of 26.05 `acceleration` was removed — the package alone selects the backend.
    package = pkgs-unstable.ollama-cuda;
    host = "127.0.0.1";
    port = 11434;
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      # q8_0 KV cache ~halves attention VRAM at negligible quality cost;
      # buys ~2 GB headroom on 14B models against the 16 GB budget.
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_KEEP_ALIVE = "30m";
    };
  };
}
