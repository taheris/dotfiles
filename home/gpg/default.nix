{ lib, pkgs, host, ... }:

let
  inherit (lib) mkIf;

in {
  services.gpg-agent =
    let
      timeout = 7 * 24 * 60 * 60;
    in
    {
      enable = true;
      enableSshSupport = true;
      pinentryPackage = mkIf (host ? isLinux) pkgs.pinentry-qt;

      defaultCacheTtl = timeout;
      defaultCacheTtlSsh = timeout;

      maxCacheTtl = timeout;
      maxCacheTtlSsh = timeout;
    };
}
