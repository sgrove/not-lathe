/* Using some raw JavaScript to assign a value to window for console debugging */
let assignToWindowForDeveloperDebug = (~name as _name: string, _value: 'b): unit =>
  switch %external(window) {
  | Some(_) => %raw(`window[_name] = _value`)
  | None => ()
  }

module JSON = {
  @val
  external stringify: ('a, @as(json`null`) _, @as(json`2`) _) => string = "JSON.stringify"
}

module Relay = {
  // Cleans up data from Relay for human viewing
  let stringify = a => {
    %raw(`(function stringifyRelayData(data) {
  const helper = (oldObj) => {
    let obj;
    if (oldObj && typeof oldObj === "object") {
      obj = {};

      var allKeys = Object.keys(oldObj);
      for (var i = 0; i < allKeys.length; i++) {
        var k = allKeys[i];

        const isBadKey = k.startsWith("__")

        if (!isBadKey) {
          var value = oldObj[k];

          if (Array.isArray(value)) {
            value = value.map(helper);
          } else if (typeof value === "object") {
            value = helper(value);
          }

          obj[k] = value;
        }
      }
    }
    return obj ?? oldObj;
  };

  return JSON.stringify(helper(data), null, 2);
})`)(a)
  }
}
