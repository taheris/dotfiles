{ lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isLinux;

in
mkIf isLinux {
  programs.librewolf = {
    enable = true;

    nativeMessagingHosts = with pkgs; [
      tridactyl-native
    ];
  };

  xdg.configFile.tridactylrc = {
    source = ./tridactylrc;
    target = "tridactyl/tridactylrc";
  };

  xdg.desktopEntries.librewolf =
    let
      bin = "${pkgs.librewolf}/bin/librewolf";
      script = pkgs.writeShellScript "librewolf-prime" ''
        env \
          __NV_PRIME_RENDER_OFFLOAD="1" \
          __NV_PRIME_RENDER_OFFLOAD_PROVIDER="NVIDIA-G0" \
          __GLX_VENDOR_LIBRARY_NAME="nvidia" \
          __VK_LAYER_NV_optimus="NVIDIA_only" \
        ${bin} "$@"
      '';
    in
    {
      name = "Librewolf";
      genericName = "Web Browser";
      exec = "${script} --name librewolf %U";
      icon = "librewolf";
      terminal = false;
      categories = [
        "Network"
        "WebBrowser"
      ];

      mimeType = [
        "application/pdf"
        "application/rdf+xml"
        "application/rss+xml"
        "application/xhtml+xml"
        "application/xhtml_xml"
        "application/xml"
        "image/gif"
        "image/jpeg"
        "image/png"
        "image/webp"
        "text/html"
        "text/xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/ipfs"
        "x-scheme-handler/ipns"
      ];

      actions = {
        new-window = {
          name = "New Window";
          exec = "${script} --new-window %U";
        };

        new-private-window = {
          name = "New Private Window";
          exec = "${script} --private-window %U";
        };

        profile-manager-window = {
          name = "Profile Manager";
          exec = "${script} --ProfileManager";
        };
      };
    };
}
