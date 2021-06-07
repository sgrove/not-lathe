// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";

function toSimpleString(connectionDrag) {
  if (typeof connectionDrag === "number") {
    return "Empty";
  }
  switch (connectionDrag.TAG | 0) {
    case /* StartedSource */0 :
        return "StartedSource";
    case /* StartedTarget */1 :
        return "StartedTarget";
    case /* CompletedPendingVariable */2 :
        return "CompletedPendingVariable";
    case /* Completed */3 :
        return "Completed";
    case /* CompletedWithTypeMismatch */4 :
        return "CompletedWithTypeMismatch";
    
  }
}

var context = React.createContext({
      onDragStart: (function (param) {
          
        }),
      onDragEnd: (function (param) {
          
        }),
      value: /* Empty */0,
      onPotentialScriptSourceConnect: (function (param, param$1, param$2, param$3, param$4) {
          
        }),
      onPotentialVariableSourceConnect: (function (param) {
          
        }),
      onPotentialActionSourceConnect: (function (param) {
          
        })
    });

var provider = context.Provider;

function ConnectionContext$Provider(Props) {
  var value = Props.value;
  var children = Props.children;
  return React.createElement(provider, {
              value: value,
              children: children
            });
}

var Provider = {
  provider: provider,
  make: ConnectionContext$Provider
};

export {
  toSimpleString ,
  context ,
  Provider ,
  
}
/* context Not a pure module */