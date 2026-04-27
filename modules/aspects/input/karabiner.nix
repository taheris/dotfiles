{ ... }:
{
  my.karabiner.homeManager =
    { config, ... }:
    {
      home.file.karabiner = {
        source = ./_karabiner/karabiner.json;
        target = "${config.xdg.configHome}/karabiner/karabiner.json";
      };
    };
}
