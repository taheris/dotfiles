# Terminal-aware slurp / expel

`terminal-bridge` is a Rust tool that moves live tmux panes between Alacritty
windows. Processes, working directories and tmux history survive the move;
programs are not restarted.

## Use

After rebuilding Home Manager, the application menu (niri) and Leader Key → t
(macOS) launch Alacritty with ordinary `tmux` startup. Existing Alacritty/tmux
windows on the default server are also eligible; no registration, session-name
prefix or special launcher is required. The commands can be invoked manually:

```sh
terminal-bridge launch
terminal-bridge slurp --wm niri
terminal-bridge expel --wm omniwm
```

- **niri Mod+S / OmniWM Option+S:** merge the terminal in the next column into
  the focused terminal as top/bottom panes. Both terminals must have one pane.
  The emptied tmux session exits naturally, without a GUI close request. If tmux
  is Alacritty's child process, the GUI window closes too; if you started tmux
  inside an existing shell, it returns to that shell instead.
- **niri Mod+X / OmniWM Option+X:** move the active pane of a multi-pane terminal
  into a new Alacritty window. The new client must attach and appear in the same
  workspace before the pane is transferred. Focus follows the expelled pane.
- Unsupported cases retain the native WM slurp/expel operation. This includes
  non-terminals, extra tmux tabs, shared/grouped sessions,
  linked tmux windows, multiple GUI windows in one column, floating terminals,
  and ambiguous GUI-process ownership. No apps are skipped when finding the
  next column, and no workspace boundaries are crossed.

The bridge uses the **ordinary default tmux server**. Sessions may have any name;
expel lets tmux assign its normal automatic session name and tracks its stable ID.
Each GUI terminal still needs an independent session/view: sessions with multiple
attached clients are intentionally excluded. Normal `tmux ls`, attachment and
configuration work as usual. Custom sockets are not currently supported.

If you ran the earlier isolated implementation, its sessions on the old
`terminal-bridge` socket are not migrated or deleted. They remain recoverable with
`tmux -L terminal-bridge attach-session -t SESSION_NAME`; new terminals use the
default server.

## Platform details

niri bindings call the bridge directly. On macOS, Karabiner dispatches Option+S/X
for **all applications**, allowing the bridge to provide native fallback outside
Alacritty. The two corresponding OmniWM native shortcuts are unassigned to avoid
double execution. Command+S/X remain the existing terminal bindings.

OmniWM IPC must be enabled (already set in this repository). The bridge uses the
CLI bundled with `/Applications/OmniWM.app`, avoiding app/CLI protocol mismatches.
Its window query must expose `pid`, `workspace`, `app`, `isFocused`, and
`columnIndex`; versions without column information fall back to native behavior.
Keep Karabiner enabled when using this OmniWM configuration.

The bridge identifies attached clients through process ancestry, never titles.
`alacritty msg create-window` can create multiple GUI windows in the same process;
such cases deliberately fall back rather than guessing which client to move.

Operations are serialized with a per-user lock. Layout and ownership are checked
again before a transfer. Startup failures remove only the bridge's untouched
placeholder pane; the source pane stays put. Operational errors are written to
stderr and do **not** trigger native fallback after a possible partial transfer.
The bridge does not migrate arbitrary non-tmux PTYs or move panes across tmux
servers.

## Verification

```sh
cd packages/terminal-bridge
cargo test
# From the repository root:
nix build .#terminal-bridge
```

The suite tests IPC payload decoding, fallback selection, process/client matching,
real tmux clients on PTYs, process/history preservation, and failure cleanup.
Actual niri/OmniWM focus, window placement and Karabiner dispatch also need a live
desktop smoke test; the headless suite does not exercise compositor GUIs.
