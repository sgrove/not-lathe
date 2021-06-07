// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Comps from "./Comps.mjs";
import * as Curry from "rescript/lib/es6/curry.js";
import * as Icons from "../Icons.mjs";
import * as React from "react";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Belt_SetString from "rescript/lib/es6/belt_SetString.js";
import * as ConnectionContext from "./ConnectionContext.mjs";
import * as Js_null_undefined from "rescript/lib/es6/js_null_undefined.js";
import * as Hooks from "react-relay/hooks";
import * as RescriptRelay_Internal from "rescript-relay/src/RescriptRelay_Internal.mjs";
import * as InspectorOverview_oneGraphAppPackageChain_graphql from "../__generated__/InspectorOverview_oneGraphAppPackageChain_graphql.mjs";

function use(fRef) {
  var data = Hooks.useFragment(InspectorOverview_oneGraphAppPackageChain_graphql.node, fRef);
  return RescriptRelay_Internal.internal_useConvertedValue(InspectorOverview_oneGraphAppPackageChain_graphql.Internal.convertFragment, data);
}

function useOpt(opt_fRef) {
  var fr = opt_fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(opt_fRef)) : undefined;
  var nullableFragmentData = Hooks.useFragment(InspectorOverview_oneGraphAppPackageChain_graphql.node, fr !== undefined ? Js_null_undefined.fromOption(Caml_option.some(Caml_option.valFromOption(fr))) : null);
  var data = (nullableFragmentData == null) ? undefined : Caml_option.some(nullableFragmentData);
  return RescriptRelay_Internal.internal_useConvertedValue((function (rawFragment) {
                if (rawFragment !== undefined) {
                  return InspectorOverview_oneGraphAppPackageChain_graphql.Internal.convertFragment(rawFragment);
                }
                
              }), data);
}

var InspectorOverviewFragment = {
  Types: undefined,
  use: use,
  useOpt: useOpt
};

function InspectorOverview(Props) {
  var fragmentRefs = Props.fragmentRefs;
  var onInspectAction = Props.onInspectAction;
  var onDeleteAction = Props.onDeleteAction;
  var chain = use(fragmentRefs);
  var connectionDrag = React.useContext(ConnectionContext.context);
  var match = React.useState(function () {
        
      });
  var setPotentialConnection = match[1];
  var potentialConnection = match[0];
  var actions = Belt_Array.map(chain.actions, (function (action) {
          var match = connectionDrag.value;
          var tmp;
          tmp = typeof match === "number" || !(match.TAG === /* StartedSource */0 && match.sourceActionId !== action.id) ? "" : "node-drop drag-target";
          var dragClassName = tmp + (
            Belt_SetString.has(potentialConnection, action.id) ? " drop-ready" : ""
          );
          return React.createElement("article", {
                      key: action.id,
                      className: "mx-2 " + dragClassName,
                      onMouseEnter: (function ($$event) {
                          var match = connectionDrag.value;
                          if (typeof match === "number" || match.TAG !== /* StartedSource */0) {
                            return ;
                          } else {
                            return Curry._1(setPotentialConnection, (function (s) {
                                          return Belt_SetString.add(s, action.id);
                                        }));
                          }
                        }),
                      onMouseLeave: (function ($$event) {
                          var match = connectionDrag.value;
                          if (typeof match === "number" || match.TAG !== /* StartedSource */0) {
                            return ;
                          } else {
                            return Curry._1(setPotentialConnection, (function (s) {
                                          return Belt_SetString.remove(s, action.id);
                                        }));
                          }
                        }),
                      onMouseUp: (function ($$event) {
                          var clientX = $$event.clientX;
                          var clientY = $$event.clientY;
                          var mouseClientPosition = [
                            clientX,
                            clientY
                          ];
                          Curry._1(setPotentialConnection, (function (s) {
                                  return Belt_SetString.remove(s, action.id);
                                }));
                          var match = connectionDrag.value;
                          if (typeof match === "number") {
                            return ;
                          }
                          if (match.TAG !== /* StartedSource */0) {
                            return ;
                          }
                          var newConnectionDrag_0 = match.sourceActionId;
                          var newConnectionDrag_1 = match.sourceDom;
                          var newConnectionDrag_2 = action.id;
                          var newConnectionDrag = {
                            TAG: 2,
                            sourceActionId: newConnectionDrag_0,
                            sourceDom: newConnectionDrag_1,
                            targetActionId: newConnectionDrag_2,
                            windowPosition: mouseClientPosition,
                            [Symbol.for("name")]: "CompletedPendingVariable"
                          };
                          Curry._1(connectionDrag.onPotentialVariableSourceConnect, newConnectionDrag);
                          
                        })
                    }, React.createElement("div", {
                          className: "flex justify-between items-center cursor-pointer p-1 rounded-sm " + dragClassName
                        }, React.createElement("span", {
                              className: "font-semibold text-sm font-mono pl-2",
                              style: {
                                color: Comps.colors["green-4"]
                              },
                              onClick: (function (param) {
                                  return Curry._1(onInspectAction, action.id);
                                })
                            }, action.name), React.createElement(Comps.Button.make, {
                              onClick: (function ($$event) {
                                  $$event.stopPropagation();
                                  $$event.preventDefault();
                                  var confirmation = confirm("Really delete \"" + action.name + "\"?");
                                  if (confirmation) {
                                    return Curry._1(onDeleteAction, action);
                                  }
                                  
                                }),
                              className: "og-secodary-button",
                              children: null
                            }, React.createElement(Icons.Trash.make, {
                                  className: "inline mr-2",
                                  color: Comps.colors["gray-4"]
                                }), "Delete Action")));
        }));
  return React.createElement(React.Fragment, undefined, React.createElement(Comps.CollapsableSection.make, {
                  title: "Metadata",
                  defaultOpen: false,
                  children: React.createElement("div", {
                        className: "relative text-lg bg-transparent text-gray-800"
                      }, React.createElement("div", {
                            className: "flex items-center ml-2 mr-2"
                          }, React.createElement("textarea", {
                                defaultValue: Belt_Option.getWithDefault(chain.description, ""),
                                className: "border-none px-2 leading-tight outline-none text-white form-input",
                                style: {
                                  backgroundColor: Comps.colors["gray-9"]
                                },
                                placeholder: "Chain description",
                                type: "text",
                                onChange: (function ($$event) {
                                    
                                  })
                              })))
                }), React.createElement(Comps.CollapsableSection.make, {
                  title: "Chain Actions",
                  children: actions
                }));
}

var make = InspectorOverview;

export {
  InspectorOverviewFragment ,
  make ,
  
}
/* Comps Not a pure module */