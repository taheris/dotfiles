{ ... }:

{
  my.ssh = {
    homeManager =
      { ... }:
      {
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;

          settings."*" = {
            AddKeysToAgent = "yes";
            Compression = true;
            ControlMaster = "no";
            ControlPath = "~/.ssh/master-%r@%n:%p";
            ControlPersist = "no";
            ForwardAgent = false;
            HashKnownHosts = false;
            ServerAliveCountMax = 3;
            ServerAliveInterval = 0;
            UserKnownHostsFile = "~/.ssh/known_hosts";
          };
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
