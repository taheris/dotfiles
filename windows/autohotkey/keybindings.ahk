#SingleInstance

Installkeybdhook true
#UseHook

SetKeyDelay 0

global ctrlXActive := false

ignoreApps := ["emacs.exe", "nvim-qt.exe"]
ignoreTitles := ["neovim"]

globalBindings := {
  ctrl: {
    a: "{Home}",
    b: "{Left}",
    d: "{Del}",
    e: "{End}",
    f: "{Right}",
    h: "{Backspace}",
    k: "macroKillLine",
    n: "{Down}",
    p: "{Up}",
    s: "^f",
    x: "macroCtrlX",
  },

  ctrlX: {
    a: "^a",
    f: "{F11}",
    k: "!{F4}",
    r: "{F5}",
    x: "^x",
  },

  alt: {
    b: "^{Left}",
    f: "^{Right}",
    h: "^+{Left}^x",
    Backspace: "^+{Left}^x",
  },

  altShift: {
    Dot: "^{End}",
    Comma: "^{Home}",
  },
}

^a::
^b::
^c::
^d::
^e::
^f::
^g::
^h::
^i::
^j::
^k::
^l::
^m::
^n::
^o::
^p::
^q::
^r::
^s::
^t::
^u::
^v::
^w::
^x::
^y::
^z::
!a::
!b::
!c::
!d::
!e::
!f::
!g::
!h::
!i::
!j::
!k::
!l::
!m::
!n::
!o::
!p::
!q::
!r::
!s::
!t::
!u::
!v::
!w::
!x::
!y::
!z::
!+,::
!+.::
^Space::
^Backspace::
!Backspace::
{
  processHotkey(A_ThisHotkey)
}

processHotkey(hotkey) {
  bindings := appBindings()
  mods := parseMods(hotkey)
  key := parseKey(hotkey)

  if bindings.HasOwnProp(mods) && bindings.%mods%.HasOwnProp(key) {
    sendBinding(bindings.%mods%.%key%)
  } else {
    sendOriginal(hotkey)
  }
}

appBindings() {
  process := WinGetProcessName("A")

  if process == "WindowsTerminal.exe" {
    running := WinGetTitle("A")
    for title in ignoreTitles {
      if running == title {
        return {}
      }
    }
  } else {
    for app in ignoreApps {
      if process == app {
        return {}
      }
    }
  }

  return globalBindings
}

parseMods(hotkey) {
  global ctrlXActive
  
  if InStr(hotkey, "^+") {
    return "ctrlShift"
  } else if InStr(hotkey, "^") && ctrlXActive {
    return "ctrlX"
  } else if InStr(hotkey, "^") {
    return "ctrl"
  } else if InStr(hotkey, "!+") {
    return "altShift"
  } else if InStr(hotkey, "!") {
    return "alt"
  } else {
    return ""
  }
}

parseKey(hotkey) {
  if InStr(hotkey, "Backspace") {
    return "Backspace"
  } else if InStr(hotkey, "Space") {
    return "Space"
  } else if InStr(hotkey, ".") {
    return "Dot"
  } else if InStr(hotkey, ",") {
    return "Comma"
  } else {
    return SubStr(hotkey, -1, 1)
  }
}

sendBinding(binding) {
  global ctrlXActive

  if SubStr(binding, 1, 5) == "macro" {
    %binding%()
  } else {
    Send binding
  }

  if binding != "macroCtrlX" {
    ctrlXActive := false
  }
}

sendOriginal(hotkey) {
  if hotkey == "^Backspace" {
    Send "^{Backspace}"
  } else if hotkey == "!Backspace" {
    Send "!{Backspace}"
  } else if hotkey == "^Space" {
    Send "^{Space}"
  } else {
    Send hotkey
  }
}

macroKillLine() {
  Send "{ShiftDown}{END}{ShiftUp}"
  Send "^x"
  Send "{Del}"
}

macroCtrlX() {
  global ctrlXActive
  ctrlXActive := true
  SetTimer clearCtrlX, -1000
}

clearCtrlX() {
  global ctrlXActive
  ctrlXActive := false
}
