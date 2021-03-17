// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Chain from "../Chain.js";
import * as React from "react";
import * as ChainEditor from "./ChainEditor.js";

function Studio(Props) {
  var schema = Props.schema;
  var config = Props.config;
  var navButton = function (onClick, content) {
    return React.createElement("button", {
                className: "mr-2 ml-2",
                onClick: onClick
              }, content);
  };
  return React.createElement("div", undefined, React.createElement("nav", {
                  className: "p-2 bg-black text-white"
                }, navButton((function (param) {
                        
                      }), "OneGraph"), navButton((function (param) {
                        
                      }), "> Workspace")), React.createElement(ChainEditor.make, {
                  schema: schema,
                  initialChain: Chain.chain,
                  config: config
                }));
}

var make = Studio;

export {
  make ,
  
}
/* Chain Not a pure module */
