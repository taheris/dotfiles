{ ... }:

{
  my.gpg = {
    homeManager =
      { lib, pkgs, ... }:
      let
        inherit (lib) mkIf;
        inherit (pkgs.stdenv) isLinux;

      in
      {
        home.file.".pam-gnupg".text = ''
          04869B61117CD7602E290767EDF9247026B079CE
          9B571D8B78DDF8D06045387D176120709E41CC9D
        '';

        home.packages = [ pkgs.gnupg ];

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
      };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.pam_u2f ];

        security.pam.services = {
          login.gnupg = {
            enable = true;
            noAutostart = true;
            storeOnly = true;
          };

          sudo.u2fAuth = true;
        };
      };
  };
}
