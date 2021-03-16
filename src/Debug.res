/* Using some raw JavaScript to assign a value to window for console debugging */
let assignToWindowForDeveloperDebug = (~name as _name: string, _value: 'b): unit =>
  switch %external(window) {
  | Some(_) => %raw(`window[_name] = _value`)
  | None => ()
  }

@val external prompt: string => option<string> = "prompt"
@val external alert: string => unit = "alert"
@val external confirm: string => bool = "confirm"
