@deriving(abstract)
type options = {
  @optional
  filter: ReactEvent.Keyboard.t => bool,
  @optional
  filterPreventDefault: bool,
  @optional
  enableOnTags: array<string>,
  @optional
  enabled: bool,
  @optional
  splitKey: string,
  @optional
  keyup: bool,
  @optional
  keydown: bool,
}

type hotkeysHandler = {
  keyup: bool,
  keydown: bool,
  scope: string,
  mods: array<int>,
  shortcut: string,
  key: string,
  splitKey: string,
}

@module("react-hotkeys-hook")
external useHotkeys: (
  ~keys: string,
  ~callback: (ReactEvent.Keyboard.t, hotkeysHandler) => unit,
  ~options: options,
  ~deps: 'any,
) => unit = "useHotkeys"
