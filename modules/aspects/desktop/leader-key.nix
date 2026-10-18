{ ... }:

{
  my.leader-key = {
    darwin.homebrew.casks = [ "leader-key" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        configDir = "${config.xdg.configHome}/leader-key";
        managedConfig = "${configDir}/config.nix.json";
        liveConfig = "${configDir}/config.json";

        spawnEmacs = pkgs.writeShellScript "leader-key-emacs" ''
          ${config.programs.emacs.package}/bin/emacsclient -n -c -a ${config.programs.emacs.package}/bin/emacs \
            </dev/null >>"''${TMPDIR:-/tmp}/leader-key-emacs.log" 2>&1 &
        '';

        spawnTerminal = pkgs.writeShellScript "leader-key-terminal" ''
          ${pkgs.terminal-bridge}/bin/terminal-bridge launch \
            </dev/null >>"''${TMPDIR:-/tmp}/leader-key-terminal.log" 2>&1 &
        '';

        spawnWeb = pkgs.writeShellScript "leader-key-web" ''
          /usr/bin/osascript \
            -e 'tell application "Safari" to make new document' \
            -e 'tell application "Safari" to activate'
        '';
      in
      {
        targets.darwin.defaults."com.brnbw.Leader-Key" = {
          inherit configDir;
          # KeyboardShortcuts stores a JSON string: physical A, Carbon Option.
          # https://github.com/mikker/LeaderKey/blob/v1.17.3/Leader%20Key/Constants.swift
          KeyboardShortcuts_navigate = builtins.toJSON {
            carbonKeyCode = 0;
            carbonModifiers = 2048;
          };
          theme = "cheater";
          screen = "activeWindow";
          SUEnableAutomaticChecks = false;
          SUAutomaticallyUpdate = false;
        };

        xdg.configFile."leader-key/config.nix.json" = {
          text = builtins.toJSON {
            type = "group";
            actions = [
              {
                key = "e";
                label = "Emacs";
                type = "command";
                value = "${spawnEmacs}";
              }
              {
                key = "t";
                label = "Terminal";
                type = "command";
                value = "${spawnTerminal}";
              }
              {
                key = "w";
                label = "Web";
                type = "command";
                value = "${spawnWeb}";
              }
            ];
          };

          # Like OmniWM, keep the live config writable for GUI experiments.
          onChange = ''
            run ${pkgs.coreutils}/bin/install -m 0600 -- ${lib.escapeShellArg managedConfig} ${lib.escapeShellArg liveConfig}
          '';
        };

        launchd.agents.leader-key = {
          enable = true;
          config = {
            Label = "org.nix-community.home.leader-key";
            ProgramArguments = [ "/Applications/Leader Key.app/Contents/MacOS/Leader Key" ];
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/leader-key.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/leader-key.log";
          };
        };

        # The released app reads its keymap and global shortcut at startup,
        # rather than observing external changes to the file/UserDefaults.
        home.activation.leaderKey =
          lib.hm.dag.entryAfter
            [
              "onFilesChange"
              "setDarwinDefaults"
              "setupLaunchAgents"
            ]
            ''
              # Let launchd serialize termination/relaunch; pkill followed by open
              # races LaunchServices while the old process is still exiting.
              run /bin/launchctl kickstart -k "gui/$(/usr/bin/id -u)/org.nix-community.home.leader-key"
            '';
      };
  };
}
