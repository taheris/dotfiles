{ lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isLinux;

  package = pkgs.librewolf.overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      wrapProgram $out/bin/librewolf \
        --set MOZ_DRM_DEVICE "/dev/dri/renderD128" \
        --set __NV_PRIME_RENDER_OFFLOAD "1" \
        --set __NV_PRIME_RENDER_OFFLOAD_PROVIDER "NVIDIA-G0" \
        --set __GLX_VENDOR_LIBRARY_NAME "nvidia" \
        --set __VK_LAYER_NV_optimus "NVIDIA_only"
    '';
  });

  bin = "${package}/bin/librewolf";

in
mkIf isLinux {
  programs.librewolf = {
    enable = true;
    inherit package;

    profiles.default = {
      isDefault = true;
    };

    nativeMessagingHosts = with pkgs; [
      tridactyl-native
    ];
  };

  xdg = {
    configFile.tridactylrc = {
      source = ./tridactylrc;
      target = "tridactyl/tridactylrc";
    };

    desktopEntries.librewolf = {
      name = "Librewolf";
      genericName = "Web Browser";
      exec = "${bin} --name librewolf %U";
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
          exec = "${bin} --new-window %U";
        };

        new-private-window = {
          name = "New Private Window";
          exec = "${bin} --private-window %U";
        };

        profile-manager-window = {
          name = "Profile Manager";
          exec = "${bin} --ProfileManager";
        };
      };
    };

    mimeApps.defaultApplications = {
      "x-scheme-handler/http" = "librewolf.desktop";
      "x-scheme-handler/https" = "librewolf.desktop";
      "text/html" = "librewolf.desktop";
    };
  };
}
