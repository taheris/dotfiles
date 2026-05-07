{ ... }:

{
  my.ollama.nixos =
    { pkgs, ... }:
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;

        environmentVariables = {
          CUDA_ERROR_LEVEL = "50";
          OLLAMA_FLASH_ATTENTION = "True";
          OLLAMA_KEEP_ALIVE = "30m";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
        };
      };
    };
}
