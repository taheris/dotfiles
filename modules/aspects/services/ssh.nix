{ ... }:

{
  my.ssh.nixos = {
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
}
