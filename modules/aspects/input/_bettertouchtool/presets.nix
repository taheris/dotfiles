{
  lib,
  configHome,
  presetsDir,
}:

let
  inherit (builtins) readDir;
  inherit (lib) escapeShellArg escapeURL filterAttrs hasSuffix mapAttrs' nameValuePair;

  isPreset = name: type: type == "regular" && hasSuffix ".bttpreset" name;
  presets = filterAttrs isPreset (readDir presetsDir);

in
mapAttrs' (
  name: _:
  let
    target = "bettertouchtool/${name}";
    importURL = "btt://import_preset/?path=${escapeURL "${configHome}/${target}"}&replaceExisting=1";

  in
  nameValuePair target {
    source = presetsDir + "/${name}";
    # Import through BTT so its live database and preferences stay writable.
    onChange = ''
      run /usr/bin/open -g ${escapeShellArg importURL}
    '';
  }
) presets
