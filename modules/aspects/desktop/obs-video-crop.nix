{ ... }:

{
  my.obs-video-crop = {
    darwin.homebrew.casks = [ "obs" ];

    homeManager =
      { config, pkgs, ... }:
      let
        logDir = "${config.home.homeDirectory}/Library/Logs/obs-video-crop";
        shortcut = pkgs.writeShellScriptBin "obs-video-crop-shortcut" ''
          umask 077
          mkdir -p "${logDir}"
          exec ${pkgs.obs-video-crop}/bin/obs-video-crop --notify >>"${logDir}/crop.log" 2>&1
        '';
      in
      {
        home.packages = [
          pkgs.obs-video-crop
          shortcut
        ];
      };
  };
}
