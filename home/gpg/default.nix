{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isDarwin isLinux;

in
{
  home.file = {
    ".pam-gnupg".text = "9B571D8B78DDF8D06045387D176120709E41CC9D";
  };

  home.packages = with pkgs; [
    gnupg
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks."*" = {
      addKeysToAgent = "yes";
      compression = true;
      controlMaster = "no";
      controlPath = "~/.ssh/master-%r@%n:%p";
      controlPersist = "no";
      forwardAgent = false;
      hashKnownHosts = false;
      serverAliveCountMax = 3;
      serverAliveInterval = 0;
      userKnownHostsFile = "~/.ssh/known_hosts";
    };

    extraConfig = mkIf isDarwin ''
      UseKeychain yes
    '';
  };

  services.gpg-agent =
    let
      timeout = 7 * 24 * 60 * 60;
    in
    {
      enable = true;

      pinentry = mkIf isLinux {
        package = pkgs.wayprompt;
        program = "pinentry-wayprompt";
      };

      defaultCacheTtl = timeout;
      defaultCacheTtlSsh = timeout;

      maxCacheTtl = timeout;
      maxCacheTtlSsh = timeout;

      extraConfig = ''
        allow-preset-passphrase
      '';
    };
}
