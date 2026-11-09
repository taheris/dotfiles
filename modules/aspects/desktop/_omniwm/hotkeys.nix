{ lib }:

let
  inherit (lib) concatMap range;

  expand =
    prefixes: suffixes:
    concatMap (prefix: map (suffix: "${prefix}.${toString suffix}") suffixes) prefixes;
in
# Required OmniWM schema 5 actions; missing bindings are generated as Unassigned.
[
  "workspaceBackAndForth"
  "switchWorkspace.next"
  "switchWorkspace.previous"
  "focusPrevious"
  "focusDownOrLeft"
  "focusUpOrRight"
  "focusWindowTop"
  "focusWindowBottom"
  "focusWindowDownOrTop"
  "focusWindowUpOrBottom"
  "focusWindowOrWorkspaceDown"
  "focusWindowOrWorkspaceUp"
  "centerColumn"
  "centerVisibleColumns"
  "moveWindowToWorkspaceUp"
  "moveWindowToWorkspaceDown"
  "moveColumnToWorkspaceUp"
  "moveColumnToWorkspaceDown"
  "moveWindowDown"
  "moveWindowUp"
  "moveWindowDownOrToWorkspaceDown"
  "moveWindowUpOrToWorkspaceUp"
  "consumeWindowIntoColumn"
  "expelWindowFromColumn"
  "focusMonitorNext"
  "focusMonitorPrevious"
  "focusMonitorLast"
  "toggleFullscreen"
  "toggleNativeFullscreen"
  "moveColumnToFirst"
  "moveColumnToLast"
  "toggleColumnTabbed"
  "focusColumnFirst"
  "focusColumnLast"
  "cycleSizeForward"
  "cycleSizeBackward"
  "cycleWindowPrimarySpanForward"
  "cycleWindowPrimarySpanBackward"
  "cycleWindowSecondarySpanForward"
  "cycleWindowSecondarySpanBackward"
  "toggleContainerFullPrimarySpan"
  "expandContainerToAvailablePrimarySpan"
  "resetWindowSecondarySpan"
  "balanceSizes"
  "moveToRoot"
  "toggleSplit"
  "swapSplit"
  "preselectClear"
  "volumeUp"
  "volumeDown"
  "volumeMute"
  "mediaPlayPause"
  "mediaNext"
  "mediaPrevious"
  "toggleShortcutPause"
  "beginPrefix"
  "toggleWindowMode"
  "exitKeyboardMode"
  "openShellApp.example"
  "newShellAppWindow.example"
  "openCommandPalette"
  "raiseAllFloatingWindows"
  "rescueOffscreenWindows"
  "toggleFocusedWindowFloating"
  "toggleFloatingFocus"
  "closeFocusedWindow"
  "openMenuAnywhere"
  "setWindowMark"
  "removeWindowMark"
  "toggleWorkspaceBarVisibility"
  "toggleHiddenBarPanel"
  "toggleQuakeTerminal"
  "toggleWorkspaceLayout"
  "toggleOverview"
  "toggleSystemStats"
]
++ expand [ "toggleScratchpad" "assignFocusedWindowToScratchpad" ] (range 1 10)
++ expand [ "switchWorkspace" "moveToWorkspace" "moveColumnToWorkspace" "focusColumn" ] (range 0 8)
++ expand [
  "switchWorkspaceSlot"
  "moveToWorkspaceSlot"
  "focusWindowInColumn"
  "moveColumnToIndex"
] (range 1 9)
++
  expand
    [ "focus" "move" "moveColumn" "moveWorkspaceToMonitor" "moveWindowToMonitor" "preselect" ]
    [ "left" "right" "up" "down" ]
++
  expand
    [ "resizeContainerPrimarySpan" "resizeWindowPrimarySpan" "resizeWindowSecondarySpan" ]
    [ "shrink" "grow" ]
++ expand [ "resizeGrow" "resizeShrink" ] [ "horizontal" "vertical" ]
++ expand [ "resizeFocusedWindow" ] [ "grow" "shrink" ]
++
  expand
    [ "openCommandPalette" ]
    [
      "windows"
      "menu"
      "clipboard"
      "commands"
      "applications"
      "files"
    ]
++
  expand
    [ "toggleShellWidget" ]
    [
      "battery-details"
      "clock"
      "control-center"
      "hidden-bar"
      "media"
      "notifications"
      "system-stats"
      "volume"
      "wifi"
      "workspaces"
    ]
