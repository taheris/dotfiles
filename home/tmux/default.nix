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

      bind-key Space   copy-mode
      bind-key C-Space copy-mode

      bind-key v split-window -h -c "#{pane_current_path}"
      bind-key s split-window -c "#{pane_current_path}"

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      unbind   -T copy-mode-vi Enter
      bind-key -T copy-mode-vi Enter send-keys -X copy-pipe "pbcopy"
      bind-key -T copy-mode-vi y     send-keys -X copy-pipe "pbcopy" \; send -X cancel
      bind-key -T copy-mode-vi v     send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v   send-keys -X rectangle-toggle \; send -X begin-selection

      unbind b
      unbind p
      unbind r
      unbind R
      bind b break-pane
      bind p paste-buffer
      bind r move-window -r
      bind R source-file ~/.config/tmux/tmux.conf \; display "tmux config reloaded"

      unbind -
      unbind =
      bind - select-layout even-horizontal
      bind = select-layout even-vertical

      bind c new-window -c "#{pane_current_path}"
      bind e setw synchronize-panes on
      bind E setw synchronize-panes off
    '';
  };
}
