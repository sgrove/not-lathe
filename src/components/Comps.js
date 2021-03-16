// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Caml_option from "bs-platform/lib/es6/caml_option.mjs";

function Comps$Header(Props) {
  var onClick = Props.onClick;
  var children = Props.children;
  var tmp = {
    className: "border-l-4 border-blue-500 pl-2 mt-2 ml-2 text-gray-400"
  };
  if (onClick !== undefined) {
    tmp.onClick = Caml_option.valFromOption(onClick);
  }
  return React.createElement("div", tmp, children);
}

var Header = {
  make: Comps$Header
};

export {
  Header ,
  
}
/* react Not a pure module */
