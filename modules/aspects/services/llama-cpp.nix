{ ... }:

{
  my.llama-cpp.nixos =
    { pkgs, ... }:
    {
      services.llama-cpp = {
        enable = true;
        package = pkgs.llama-cpp.override { cudaSupport = true; };

        # Start in router mode so models can be managed through the server API.
        settings = {
          cache-type-k = "q8_0";
          cache-type-v = "q8_0";
          flash-attn = "on";
          models-max = 1;
          sleep-idle-seconds = 30 * 60;
        };
      };
    };

  my.llama-cpp.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ (pkgs.llama-cpp.override { cudaSupport = true; }) ];
    };
}
