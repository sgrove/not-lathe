/* Using some raw JavaScript to assign a value to window for console debugging */
let assignToWindowForDeveloperDebug = (~name as _name: string, _value: 'b): unit =>
  switch %external(window) {
  | Some(_) => %raw(`window[_name] = _value`)
  | None => ()
  }
