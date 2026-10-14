{ ... }:

{
  my.karabiner.homeManager =
    { config, ... }:
    {
      home.file.karabiner = {
        text = builtins.replaceStrings [ "@homeProfile@" ] [ config.home.profileDirectory ] (
          builtins.readFile ./_karabiner/karabiner.json
        );
        target = "${config.xdg.configHome}/karabiner/karabiner.json";
      };
    };
}
