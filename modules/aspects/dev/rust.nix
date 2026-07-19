{ inputs, ... }:

{
  my.rust.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      inherit (lib) mkIf mkMerge optionalAttrs;
      inherit (pkgs.stdenv) isDarwin isLinux;
      inherit (pkgs.stdenv.hostPlatform) system;

      # Reuse the sandbox's exact toolchain derivation — sccache hashes the
      # compiler binary, so a re-instantiated fenix would miss cross-boundary.
      wrixLib = inputs.wrix.legacyPackages.${system}.lib;
      wrixToolchain = wrixLib.profiles.rust.toolchain;

      sccacheBin = "${pkgs.sccache}/bin/sccache";
      sccacheCacheDir = "${config.home.homeDirectory}/.cache/sccache";
      sccacheCacheSize = "50G";
      sccacheServerPort = "4226";

      sccacheEnvironment = {
        SCCACHE_DIR = sccacheCacheDir;
        SCCACHE_CACHE_SIZE = sccacheCacheSize;
      };

      packages = with pkgs; [
        cargo-audit
        cargo-bloat
        cargo-deny
        cargo-expand
        cargo-flamegraph
        cargo-fuzz
        cargo-outdated
        cargo-sweep
        cargo-release
        cargo-udeps
        cargo-update
        rustup
        sccache
        tokei
        wasm-pack
      ];

      linuxPackages = with pkgs; [
        cargo-rr
        cargo-valgrind
        clang
        mold
        rr
      ];

    in
    {
      home = {
        packages = mkMerge [
          packages
          (mkIf isLinux linuxPackages)
        ];

        file.cargo = {
          target = ".cargo/config.toml";
          source = (pkgs.formats.toml { }).generate "cargo-config" {
            build = {
              rustc = "${wrixToolchain}/bin/rustc";
              rustc-wrapper = sccacheBin;
            };

            profile.dev = {
              split-debuginfo = "unpacked";
            };

            target.x86_64-unknown-linux-gnu = optionalAttrs isLinux {
              linker = "clang";
              rustflags = [
                "-C"
                "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"
              ];
            };
          };
        };

        sessionPath = [
          "${wrixToolchain}/bin"
          "${config.home.homeDirectory}/.cargo/bin"
        ];

        sessionVariables =
          sccacheEnvironment
          // {
            CARGO_INCREMENTAL = "0";
            RUST_SRC_PATH = "${wrixToolchain}/lib/rustlib/src/rust/library";
            RUSTC_WRAPPER = sccacheBin;
          }
          // optionalAttrs isDarwin {
            SCCACHE_SERVER_PORT = sccacheServerPort;
          };

        # On the first activation that introduces the launchd agent, stop an
        # existing client-spawned daemon before Home Manager claims the port.
        # Subsequent agent replacements are handled by setupLaunchAgents.
        activation.stopAdHocSccache = mkIf isDarwin (
          lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ] ''
            if [[ -z "''${oldGenPath:-}" || ! -e "$oldGenPath/LaunchAgents/org.nix-community.home.sccache.plist" ]]; then
              verboseEcho "Stopping any ad-hoc sccache daemon on port ${sccacheServerPort}"
              SCCACHE_SERVER_PORT=${sccacheServerPort} ${sccacheBin} --stop-server >/dev/null 2>&1 || true
            fi
          ''
        );
      };

      launchd.agents.sccache = mkIf isDarwin {
        enable = true;
        domain = "user";
        config = {
          ProgramArguments = [ sccacheBin ];
          EnvironmentVariables = sccacheEnvironment // {
            SCCACHE_START_SERVER = "1";
            SCCACHE_NO_DAEMON = "1";
            SCCACHE_IDLE_TIMEOUT = "0";
            SCCACHE_SERVER_PORT = sccacheServerPort;
          };
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/sccache.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/sccache.log";
        };
      };
    };
}
