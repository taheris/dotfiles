{ ... }:

{
  my.tmux.homeManager =
    { pkgs, ... }:
    {
      programs.tmux = {
        enable = true;

        baseIndex = 1;
        clock24 = true;
        escapeTime = 10;
        historyLimit = 100000;
        keyMode = "vi";
        mouse = true;
        prefix = "C-Space";
        terminal = "xterm-256color";

        plugins = [ pkgs.tmuxPlugins.nord ];

        extraConfig = ''
          set -g status-position top
          set -g status-interval 2
          set -g default-command "which reattach-to-user-namespace > /dev/null && reattach-to-user-namespace -l $SHELL || $SHELL"
          set -g renumber-windows on

          # Auto-equalize panes when one closes
          set-hook -g pane-exited "select-layout -E"

          # Splits (vim mnemonics, inherit cwd)
          bind -n M-v split-window -h -c "#{pane_current_path}"
          bind -n M-s split-window -c "#{pane_current_path}"

          # Pane navigation (hjkl)
          bind -n M-h select-pane -L
          bind -n M-j select-pane -D
          bind -n M-k select-pane -U
          bind -n M-l select-pane -R

          # Swap panes (HJKL)
          bind -n M-H swap-pane -d -t '{left-of}'
          bind -n M-J swap-pane -d -t '{down-of}'
          bind -n M-K swap-pane -d -t '{up-of}'
          bind -n M-L swap-pane -d -t '{right-of}'

          # Pane resize (prefix, repeatable)
          bind -r H resize-pane -L 5
          bind -r J resize-pane -D 5
          bind -r K resize-pane -U 5
          bind -r L resize-pane -R 5

          # Pane actions
          bind -n M-q kill-pane
          bind -n M-Enter resize-pane -Z
          bind -n M-= select-layout -E
          bind -n M-x swap-pane -D
          bind -n M-b break-pane

          # Windows
          bind -n M-r command-prompt "rename-window '%%'"
          bind -n M-R command-prompt "rename-session '%%'"
          bind -n M-w choose-tree -Zs
          bind -n M-c new-window -c "#{pane_current_path}"
          bind -n M-n next-window
          bind -n M-p previous-window
          bind -n M-1 select-window -t 1
          bind -n M-2 select-window -t 2
          bind -n M-3 select-window -t 3
          bind -n M-4 select-window -t 4
          bind -n M-5 select-window -t 5
          bind -n M-6 select-window -t 6
          bind -n M-7 select-window -t 7
          bind -n M-8 select-window -t 8
          bind -n M-9 select-window -t 9
          bind -n M-Q kill-window
          bind -n M-` last-window

          # Copy-mode
          bind -n M-Space copy-mode

          # Popup
          bind -n M-o display-popup -E -d "#{pane_current_path}"

          # Passthrough (M-z then key forwards Alt combo to terminal)
          bind -n M-z switch-client -T passthrough
          bind -T passthrough M-. send-keys M-.
          bind -T passthrough M-, send-keys M-,
          bind -T passthrough M-h send-keys M-h
          bind -T passthrough M-b send-keys M-b
          bind -T passthrough M-f send-keys M-f
          bind -T passthrough M-d send-keys M-d
          bind -T passthrough M-n send-keys M-n
          bind -T passthrough M-p send-keys M-p
          bind -T passthrough M-/ send-keys M-/
          bind -T passthrough M-? send-keys M-?

          # Copy-mode-vi
          unbind   -T copy-mode-vi Enter
          bind-key -T copy-mode-vi Enter send-keys -X copy-pipe "pbcopy"
          bind-key -T copy-mode-vi y     send-keys -X copy-pipe "pbcopy" \; send -X cancel
          bind-key -T copy-mode-vi v     send-keys -X begin-selection
          bind-key -T copy-mode-vi C-v   send-keys -X rectangle-toggle \; send -X begin-selection

          # Prefix bindings (infrequent ops)
          bind r move-window -r
          bind R source-file ~/.config/tmux/tmux.conf \; display "tmux config reloaded"
          bind e setw synchronize-panes on
          bind E setw synchronize-panes off
        '';
      };
    };
}
