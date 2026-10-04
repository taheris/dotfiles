{ lib, ... }:

let
  inherit (builtins) fromTOML readFile;
  inherit (lib) concatMapStrings subtractLists;

  settings = readFile ./_omniwm/settings.toml;
  configuredActions = map (hotkey: hotkey.id) (fromTOML settings).hotkeys;
  requiredActions = import ./_omniwm/hotkeys.nix { inherit lib; };
  unassignedActions = subtractLists configuredActions requiredActions;

in
{
  my.omniwm.homeManager = {
    xdg.configFile."omniwm/settings.toml".text =
      settings
      + concatMapStrings (id: ''

        [[hotkeys]]
        binding = "Unassigned"
        id = "${id}"
      '') unassignedActions;
  };
}
