{ my, ... }:

{
  den.hosts.aarch64-darwin.m1 = {
    user = "shaun";
    fontSize = 16;
    hasLinuxBuilder = true;
    users.shaun = { };
  };

  den.aspects.m1 =
    { ... }:
    {
      includes = [
        my.linux-builder
        my.darwin
        my.gpg
      ];

      darwin = {
        nix.buildMachines = [
          {
            hostName = "nix";
            sshUser = "shaun";
            sshKey = "/etc/nix/nix_builder_key";
            systems = [
              "aarch64-linux"
              "x86_64-linux"
            ];
            supportedFeatures = [
              "benchmark"
              "big-parallel"
              "kvm"
              "nixos-test"
            ];
          }
        ];

        nixpkgs.hostPlatform = "aarch64-darwin";

        system.primaryUser = "shaun";
      };
    };
}
