{ pkgs, ... }:

{
  services.gpg-agent =
    let
      timeout = 7 * 24 * 60 * 60;
    in
    {
      enable = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-qt;

      defaultCacheTtl = timeout;
      defaultCacheTtlSsh = timeout;

      maxCacheTtl = timeout;
      maxCacheTtlSsh = timeout;
    };
}
