// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Curry from "bs-platform/lib/es6/curry.mjs";
import * as React from "react";

function useDebounce(value, delay) {
  var match = React.useState(function () {
        return value;
      });
  var setDebouncedValue = match[1];
  React.useEffect((function () {
          var handler = setTimeout((function (param) {
                  return Curry._1(setDebouncedValue, (function (param) {
                                return value;
                              }));
                }), delay);
          return (function (param) {
                    clearTimeout(handler);
                    
                  });
        }), [
        value,
        delay
      ]);
  return match[0];
}

export {
  useDebounce ,
  
}
/* react Not a pure module */
