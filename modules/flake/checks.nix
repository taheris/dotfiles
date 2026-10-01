{ config, lib, ... }:

{
  perSystem =
    { pkgs, system, ... }:
    let
      darwinHost = if system == "x86_64-darwin" then "m16" else "m1";
      darwinHome = config.flake.darwinConfigurations.${darwinHost}.config.home-manager.users.shaun;
      linuxHome = config.flake.homeConfigurations."shaun@nix".config;
      linuxSystem = config.flake.nixosConfigurations.nix.config;

      gcValid =
        lib.all (gc: gc.automatic && gc.dates == [ "weekly" ] && gc.options == "--delete-older-than 30d") [
          linuxSystem.nix.gc
          linuxHome.nix.gc
        ]
        && linuxSystem.systemd.timers.nix-gc.timerConfig.Persistent
        && linuxHome.systemd.user.timers.nix-gc.Timer.Persistent
        && lib.hasInfix "--delete-older-than 30d" linuxSystem.systemd.services.nix-gc.script;

      agent = darwinHome.launchd.agents.sccache;
      darwinSession = darwinHome.home.sessionVariables;
      linuxSession = linuxHome.home.sessionVariables;
      serverEnvironment = agent.config.EnvironmentVariables;

      darwinValid =
        agent.enable
        && agent.config.RunAtLoad
        && agent.config.KeepAlive
        && agent.config.ProgramArguments == [ darwinSession.RUSTC_WRAPPER ]
        &&
          serverEnvironment == {
            SCCACHE_START_SERVER = "1";
            SCCACHE_NO_DAEMON = "1";
            SCCACHE_IDLE_TIMEOUT = "0";
            SCCACHE_SERVER_PORT = darwinSession.SCCACHE_SERVER_PORT;
            SCCACHE_DIR = darwinSession.SCCACHE_DIR;
            SCCACHE_CACHE_SIZE = darwinSession.SCCACHE_CACHE_SIZE;
          }
        && darwinSession.SCCACHE_SERVER_PORT == "4226"
        && darwinSession.SCCACHE_DIR == "${darwinHome.home.homeDirectory}/.cache/sccache"
        && darwinSession.SCCACHE_CACHE_SIZE == "50G"
        && darwinSession.CARGO_INCREMENTAL == "0";

      linuxValid =
        !(linuxHome.launchd.agents ? sccache)
        && !(linuxSession ? SCCACHE_SERVER_PORT)
        && lib.hasSuffix "/bin/sccache" linuxSession.RUSTC_WRAPPER
        && linuxSession.SCCACHE_DIR == "${linuxHome.home.homeDirectory}/.cache/sccache"
        && linuxSession.SCCACHE_CACHE_SIZE == "50G"
        && linuxSession.CARGO_INCREMENTAL == "0";

      cargoWrapperLine = ''rustc-wrapper = "${darwinSession.RUSTC_WRAPPER}"'';
      cargoCompilerLine = ''rustc = "${lib.removeSuffix "/lib/rustlib/src/rust/library" darwinSession.RUST_SRC_PATH}/bin/rustc"'';
    in
    {
      checks.nix-gc-configuration =
        assert lib.assertMsg gcValid "invalid Linux garbage collection policy";
        pkgs.runCommand "nix-gc-configuration-test" { } ''
          ${lib.optionalString (system == "x86_64-linux") ''
            grep -F -- '--delete-older-than 30d' ${lib.head linuxHome.systemd.user.services.nix-gc.Service.ExecStart}
          ''}
          touch "$out"
        '';

      checks.sccache-configuration =
        assert lib.assertMsg darwinValid "invalid Darwin sccache service configuration";
        assert lib.assertMsg linuxValid "sccache changed Linux behavior";
        pkgs.runCommand "sccache-configuration-test" { } ''
          ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
            grep -F -- ${lib.escapeShellArg cargoCompilerLine} ${lib.escapeShellArg (toString darwinHome.home.file.cargo.source)}
            grep -F -- ${lib.escapeShellArg cargoWrapperLine} ${lib.escapeShellArg (toString darwinHome.home.file.cargo.source)}
          ''}
          touch "$out"
        '';
    };
}
