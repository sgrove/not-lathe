// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Chain from "./Chain.js";
import * as Curry from "bs-platform/lib/es6/curry.mjs";
import * as React from "react";
import * as Graphql from "graphql";
import * as Inspector from "./components/Inspector.js";
import * as Belt_Array from "bs-platform/lib/es6/belt_Array.mjs";
import * as OneGraphRe from "./OneGraphRe.js";
import * as Belt_Option from "bs-platform/lib/es6/belt_Option.mjs";
import * as Caml_option from "bs-platform/lib/es6/caml_option.mjs";

function Form$Main(Props) {
  var schema = Props.schema;
  var chainId = Props.chainId;
  var match = React.useState(function () {
        return {};
      });
  var setFormVariables = match[1];
  var formVariables = match[0];
  var match$1 = React.useState(function () {
        return {
                chainExecutionResults: undefined
              };
      });
  var setState = match$1[1];
  var chain = Chain.loadFromLocalStorage(chainId);
  var form = Belt_Option.getWithDefault(Belt_Option.map(chain, (function (chain) {
              var compiledOperation = Inspector.transformChain(chain);
              var targetChain = Belt_Array.get(compiledOperation.chains, 0);
              return Belt_Array.map(targetChain.exposedVariables, (function (exposedVariable) {
                            var def_variable = {
                              name: {
                                kind: "Name",
                                value: exposedVariable.exposedName,
                                loc: undefined
                              }
                            };
                            var def_type = Graphql.parseType(exposedVariable.upstreamType);
                            var def = {
                              variable: def_variable,
                              type: def_type
                            };
                            return Inspector.formInput(schema, def, setFormVariables, {});
                          }));
            })), null);
  return React.createElement("div", {
              className: "border-t border-gray-500 h-screen",
              style: {
                backgroundColor: "rgb(60, 60, 60)"
              }
            }, React.createElement("nav", {
                  className: "flex flex-row border-b-2 border-blue-500 py-1 px-2"
                }, React.createElement("button", {
                      className: "text-left text-gray-600 hover:text-blue-500 focus:outline-none text-blue-500 flex-grow"
                    }, "Chain Form")), React.createElement("form", {
                  className: "text-left text-gray-600 hover:text-blue-500 focus:outline-none text-blue-500 flex-grow"
                }, form), React.createElement("button", {
                  className: "w-full focus:outline-none text-white text-sm py-2.5 px-5 border-b-4 border-gray-600 rounded-md bg-gray-500 hover:bg-gray-400",
                  type: "button",
                  onClick: (function (param) {
                      return Belt_Option.forEach(chain, (function (chain) {
                                    var compiledOperation = Inspector.transformChain(chain);
                                    var targetChain = Belt_Array.get(compiledOperation.chains, 0);
                                    var variables = Caml_option.some(formVariables);
                                    var __x = OneGraphRe.basicFetchOneGraphPersistedQuery("4b34d36f-83e5-4789-9cf7-fe1ebe1ce527", undefined, chainId, variables, targetChain.operationName);
                                    __x.then(function (result) {
                                          return Promise.resolve(Curry._1(setState, (function (param) {
                                                            return {
                                                                    chainExecutionResults: result
                                                                  };
                                                          })));
                                        });
                                    
                                  }));
                    })
                }, "Submit Form"), Belt_Option.getWithDefault(Belt_Option.map(match$1[0].chainExecutionResults, (function (results) {
                        return React.createElement(React.Fragment, undefined, React.createElement("h1", undefined, "Form results: "), React.createElement("pre", undefined, JSON.stringify(results, null, 2)));
                      })), null));
}

var Main = {
  make: Form$Main
};

function Form(Props) {
  var schema = Props.schema;
  var chainId = Props.chainId;
  return React.createElement(Form$Main, {
              schema: schema,
              chainId: chainId
            });
}

var make = Form;

export {
  Main ,
  make ,
  
}
/* Chain Not a pure module */
