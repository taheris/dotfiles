{ ... }:

{
  my.vlc.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
      epgExtension = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/yaser55v/vlc-epg/v2.2.2/vlc_epg.lua";
        hash = "sha256-KQJfnbLAa01Q03YYWogsYaMLD2jZcZemLKfB91mVTUM=";
      };
      extensionDir =
        if isDarwin then
          "Library/Application Support/org.videolan.vlc/lua/extensions"
        else
          "${config.xdg.dataHome}/vlc/lua/extensions";
      flatpakExtension = "${config.home.homeDirectory}/.var/app/org.videolan.VLC/data/vlc/lua/extensions/vlc_epg.lua";
    in
    {
      # Open VLC > Extensions > VLC EPG on Darwin or View > VLC EPG on Linux
      home.file."${extensionDir}/vlc_epg.lua".source = epgExtension;

      # Flatpak cannot follow a Home Manager symlink into /nix/store. Copy the
      # extension into its private data directory without granting store access.
      home.activation.vlcEpgFlatpak = lib.mkIf isLinux (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${pkgs.coreutils}/bin/install -D -m 0644 -- ${epgExtension} ${lib.escapeShellArg flatpakExtension}
        ''
      );
    };
}
