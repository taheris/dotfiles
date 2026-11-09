-- Command palette, overview, and session picker.
rex.bind("cmd+p", "client.palette.toggle")
rex.bind("cmd+o", "pane.go_to")
-- Command-K now focuses up instead of opening Rex's default session picker.
rex.bind("shift+cmd+k", "session.switch")

-- tmux prefix and repeatable resizing.
rex.bind("ctrl+space>ctrl+space", "pane.send_key", { key = "ctrl+space" })
rex.mode("repeat", { exclusive = true })
rex.bind("ctrl+space>r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")
rex.bind("ctrl+space>shift+h", "pane.resize", { amount = 5, direction = "left" })
rex.bind("repeat/shift+h", "pane.resize", { amount = 5, direction = "left" })
rex.bind("ctrl+space>shift+j", "pane.resize", { amount = 5, direction = "down" })
rex.bind("repeat/shift+j", "pane.resize", { amount = 5, direction = "down" })
rex.bind("ctrl+space>shift+k", "pane.resize", { amount = 5, direction = "up" })
rex.bind("repeat/shift+k", "pane.resize", { amount = 5, direction = "up" })
rex.bind("ctrl+space>shift+l", "pane.resize", { amount = 5, direction = "right" })
rex.bind("repeat/shift+l", "pane.resize", { amount = 5, direction = "right" })

-- App splits. Shift-Command-S replaces Rex's default Toggle Tab Style.
rex.bind("cmd+s", "pane.split", { direction = "down" })
rex.bind("shift+cmd+s", "pane.split", { direction = "right" })

-- Karabiner sends F17 for Command-H and F18 for Command-Q in Rex only,
-- preserving Shift. These avoid macOS intercepting Hide/Quit/Log Out.
-- Remove the indirection if Rex supports overriding these system shortcuts.
-- https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts.md
rex.bind("f17", "pane.focus", { direction = "left" })
rex.bind("cmd+j", "pane.focus", { direction = "down" })
rex.bind("cmd+k", "pane.focus", { direction = "up" })
rex.bind("cmd+l", "pane.focus", { direction = "right" })
rex.bind("f18", "pane.close")
rex.bind("shift+f18", "client.tab.close")

-- Migrated tmux app shortcuts use Command on macOS, not WM Option keys.
rex.bind("cmd+enter", "pane.zoom")
rex.bind("cmd+x", "pane.move", { direction = "down" })
rex.bind("cmd+b", "pane.move_to_new_tab")
rex.bind("cmd+r", "client.tab.rename")
rex.bind("shift+cmd+r", "session.rename")
rex.bind("cmd+w", "session.switch")
rex.bind("cmd+c", "client.tab.new")
rex.bind("cmd+n", "client.tab.next")
-- Command-P stays the palette. Previous tab uses Rex's Ctrl-Shift-Tab default;
-- Ctrl-Tab is next tab, and the three-finger swipe gestures use this pair.
-- Command-1 through Command-8 already select their tabs by default.
rex.bind("cmd+9", "client.tab.goto", { index = 9 })
rex.bind("ctrl+space>shift+r", "client.config.reload")

-- Passthrough uses Command gestures to forward the original Meta keys.
rex.mode("passthrough", { exclusive = true })
rex.bind("passthrough/escape", "client.mode.exit")
rex.bind("cmd+z", "client.mode.enter", { name = "passthrough" })
rex.bind("passthrough/cmd+.", "pane.send_key", { key = "alt+." })
rex.bind("passthrough/cmd+,", "pane.send_key", { key = "alt+," })
rex.bind("passthrough/f17", "pane.send_key", { key = "alt+h" })
rex.bind("passthrough/cmd+b", "pane.send_key", { key = "alt+b" })
rex.bind("passthrough/cmd+f", "pane.send_key", { key = "alt+f" })
rex.bind("passthrough/cmd+d", "pane.send_key", { key = "alt+d" })
rex.bind("passthrough/cmd+n", "pane.send_key", { key = "alt+n" })
rex.bind("passthrough/cmd+p", "pane.send_key", { key = "alt+p" })
rex.bind("passthrough/cmd+/", "pane.send_key", { key = "alt+/" })
rex.bind("passthrough/shift+cmd+/", "pane.send_key", { key = "alt+shift+/" })

-- Alacritty: CSI-u Shift+Enter is a single key. Command-V remains paste.
rex.bind("shift+enter", "pane.send_key", { key = "shift+enter" })
