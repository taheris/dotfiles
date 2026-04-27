{ ... }:

{
  my.ssh = {
    homeManager =
      { lib, pkgs, ... }:
      let
        inherit (lib) mkIf;
        inherit (pkgs.stdenv) isDarwin;
      in
      {
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
      };

    nixos = {
      services.openssh = {
        enable = true;
        openFirewall = false;

        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };

      services.gnome.gcr-ssh-agent.enable = false;

      programs.ssh = {
        askPassword = "";
        startAgent = true;
      };

      environment.sessionVariables.SSH_ASKPASS_REQUIRE = "never";
    };
  };
}
