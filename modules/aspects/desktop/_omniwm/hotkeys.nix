{ lib }:

let
  inherit (lib) concatMap range;

  expand =
    prefixes: suffixes:
    concatMap (prefix: map (suffix: "${prefix}.${toString suffix}") suffixes) prefixes;
in
# Required OmniWM schema 4 actions; missing bindings are generated as Unassigned.
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
  "openCommandPalette"
  "raiseAllFloatingWindows"
  "rescueOffscreenWindows"
  "toggleFocusedWindowFloating"
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
    [ "setContainerPrimarySpan" "setWindowPrimarySpan" "setWindowSecondarySpan" ]
    [ "decrease10Percent" "increase10Percent" ]
++ expand [ "resizeGrow" "resizeShrink" ] [ "horizontal" "vertical" ]
++ expand [ "resizeFocusedWindow" ] [ "grow" "shrink" ]
