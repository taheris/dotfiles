#SingleInstance

Installkeybdhook true
#UseHook

SetKeyDelay 0

global ctrlXActive := false

hyperKey := "vkE8"
hyperMods := "^!+"
ignoreApps := ["nvim-qt.exe"]

bindings := {
  hyper: {
    c: "^c",
    d: "{PgDn}",
    f: "^f",
    j: "{Down}",
    k: "{Up}",
    n: "{Media_Next}",
    p: "{Media_Prev}",
    s: "{Media_Play_Pause}",
    u: "{PgUp}",
    v: "#^v",
    x: "^x",
    Tab: "!{Tab}",
    Space: "#{Space}",
    Backspace: "^+{Left}{Backspace}",
    Escape: "^{Escape}",
    Dot: "^{End}",
    Comma: "^{Home}",
  },

  ctrl: {
    a: "{Home}",
    b: "{Left}",
    d: "{Del}",
    e: "{End}",
    f: "{Right}",
    h: "{Backspace}",
    k: "{ShiftDown}{End}{ShiftUp}{Backspace}{Del}",
    n: "{Down}",
    p: "{Up}",
    x: activateCtrlX,
  },

  ctrlX: {
    f: "{F11}",
    q: "!{F4}",
    r: "{F5}",
  },

  alt: {
    b: "^{Left}",
    f: "^{Right}",
    h: "^+{Left}{Backspace}",
  },

  winAlt: {
    h: leftDesktop,
    l: rightDesktop,
  },

  winShift: {
    d: "{Volume_Down}",
    h: "#{Left}",
    j: "#{Down}",
    k: "#{Up}",
    l: "#{Right}",
    m: "{Volume_Mute}",
    u: "{Volume_Up}",
  },
}

emacsBindings := {
  hyper: bindings.hyper,
  winAlt: bindings.winAlt,
  winShift: bindings.winShift,
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
^Tab::
^Space::
^Backspace::
^Escape::
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
!Tab::
!Space::
!Backspace::
!Escape::
vkE8 & a::
vkE8 & b::
vkE8 & c::
vkE8 & d::
vkE8 & e::
vkE8 & f::
vkE8 & g::
vkE8 & h::
vkE8 & i::
vkE8 & j::
vkE8 & k::
vkE8 & l::
vkE8 & m::
vkE8 & n::
vkE8 & o::
vkE8 & p::
vkE8 & q::
vkE8 & r::
vkE8 & s::
vkE8 & t::
vkE8 & u::
vkE8 & v::
vkE8 & w::
vkE8 & x::
vkE8 & y::
vkE8 & z::
vkE8 & .::
vkE8 & ,::
vkE8 & Tab::
vkE8 & Space::
vkE8 & Backspace::
vkE8 & Escape::
{
  processHotkey(A_ThisHotkey)
}

processHotkey(hotkey) {
  bindings := appBindings()
  hotkey := parseHyper(hotkey)

  mods := parseMods(hotkey)
  if not bindings.HasOwnProp(mods) {
    return sendOriginal(hotkey)
  }

  key := parseKey(hotkey)
  if bindings.%mods%.HasOwnProp(key) {
    sendBinding(bindings.%mods%.%key%)
  } else {
    sendOriginal(hotkey)
  }
}

appBindings() {
  try
    process := WinGetProcessName("A")
  catch TargetError
    return bindings

  switch process {
  case "emacs.exe":
    return emacsBindings
  }

  for app in ignoreApps {
    if process == app {
      return {}
    }
  }

  return bindings
}

parseHyper(hotkey) {
  if not InStr(hotkey, hyperKey) {
    return hotkey
  }

  start := 1 + StrLen(hyperKey . " & ")
  binding := SubStr(hotkey, start)

  if GetKeyState("Alt") {
    return "#!" . binding
  } else if GetKeyState("Shift") {
    return "#+" . binding
  } else {
    return hyperMods . binding
  }
}

parseMods(hotkey) {
  global ctrlXActive

  if InStr(hotkey, hyperMods) {
    return "hyper"
  } else if InStr(hotkey, "#!") {
    return "winAlt"
  } else if InStr(hotkey, "#+") {
    return "winShift"
  } else if InStr(hotkey, "^") && ctrlXActive {
    return "ctrlX"
  } else if InStr(hotkey, "^") {
    return "ctrl"
  } else if InStr(hotkey, "!") {
    return "alt"
  } else {
    return ""
  }
}

parseKey(hotkey) {
  if InStr(hotkey, "Tab") {
    return "Tab"
  } else if InStr(hotkey, "Backspace") {
    return "Backspace"
  } else if InStr(hotkey, "Space") {
    return "Space"
  } else if InStr(hotkey, "Escape") {
    return "Escape"
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

  if IsObject(binding) {
    binding()
  } else {
    Send binding
  }

  if ctrlXActive and binding != activateCtrlX {
    ctrlXActive := false
  }
}

sendOriginal(hotkey) {
  switch hotkey {
  case "^Backspace":
    Send "^{Backspace}"
  case "!Backspace":
    Send "!{Backspace}"
  case "^Space":
    Send "^{Space}"
  default:
    Send hotkey
  }
}

activateCtrlX() {
  global ctrlXActive

  ctrlXActive := true
  deactivate() {
    ctrlXActive := false
  }

  SetTimer deactivate, -1000
}

leftDesktop() {
  Send "#^{Left}"
  MouseGetPos , , &id
  WinActivate id
}

rightDesktop() {
  Send "#^{Right}"
  MouseGetPos , , &id
  WinActivate id
}
