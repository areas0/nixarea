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
      # Default is 4096, which Open WebUI's system prompt + reasoning models
      # (gpt-oss) overflow, cutting the answer off mid-thought. Claude Code's
      # own requests start at ~73K tokens before any message (mostly tool
      # schemas); Ollama silently drops the middle of anything over the limit.
      # gemma4's KV cache is cheap (~8.5 KiB/token), 128K costs ~1 GiB.
      OLLAMA_CONTEXT_LENGTH = "131072";
    };
  };

  services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      # First account created in the UI becomes admin; keep auth on.
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";

      # These only seed a fresh database; once saved, Admin > Settings > Web
      # Search in the UI takes precedence.
      ENABLE_WEB_SEARCH = "True";
      WEB_SEARCH_ENGINE = "searxng";
      SEARXNG_QUERY_URL = "http://127.0.0.1:8888/search?q=<query>";
      WEB_SEARCH_RESULT_COUNT = "5";
    };
  };

  # Local metasearch backend for Open WebUI web search. The "json" format must
  # be enabled or Open WebUI gets a 403. Loopback-only with the limiter off,
  # so the secret_key guards nothing reachable and is fine in the store.
  services.searx = {
    enable = true;
    settings = {
      use_default_settings = true;
      server = {
        bind_address = "127.0.0.1";
        port = 8888;
        secret_key = "local-only-not-a-secret";
        limiter = false;
      };
      search.formats = [
        "html"
        "json"
      ];
      # The default general engines (duckduckgo, startpage, brave) serve
      # CAPTCHAs / rate-limit scrapers, leaving zero results. Bing is off by
      # default but works. Revisit if it starts getting blocked too.
      engines = [
        {
          name = "bing";
          disabled = false;
        }
        {
          name = "duckduckgo";
          disabled = true;
        }
        {
          name = "startpage";
          disabled = true;
        }
        {
          name = "brave";
          disabled = true;
        }
      ];
    };
  };
}
