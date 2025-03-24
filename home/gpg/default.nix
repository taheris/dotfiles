{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isLinux;

in
{
  home.file = {
    "${config.xdg.configHome}/pam-gnupg".text = "9B571D8B78DDF8D06045387D176120709E41CC9D";
  };

  home.packages = with pkgs; [
    gnupg
  ];

  services.gpg-agent =
    let
      timeout = 7 * 24 * 60 * 60;
    in
    {
      enable = true;
      enableSshSupport = true;
      pinentryPackage = mkIf isLinux pkgs.pinentry-qt;

      defaultCacheTtl = timeout;
      defaultCacheTtlSsh = timeout;

      maxCacheTtl = timeout;
      maxCacheTtlSsh = timeout;

      extraConfig = ''
        allow-preset-passphrase
      '';
    };
}
