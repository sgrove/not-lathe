// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Comps from "./Comps.mjs";
import * as Curry from "rescript/lib/es6/curry.js";
import * as Icons from "../Icons.mjs";
import * as Utils from "../Utils.mjs";
import * as React from "react";
import * as $$String from "rescript/lib/es6/string.js";
import * as $$Promise from "reason-promise/src/js/promise.mjs";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as RescriptRelay from "rescript-relay/src/RescriptRelay.mjs";
import * as RelayRuntime from "relay-runtime";
import * as Belt_SortArray from "rescript/lib/es6/belt_SortArray.js";
import * as Js_null_undefined from "rescript/lib/es6/js_null_undefined.js";
import * as Hooks from "react-relay/hooks";
import * as ReactHotkeysHook from "react-hotkeys-hook";
import * as RescriptRelay_Internal from "rescript-relay/src/RescriptRelay_Internal.mjs";
import * as ActionSearchQuery_graphql from "../__generated__/ActionSearchQuery_graphql.mjs";
import * as ActionSearch_oneGraphStudioChainAction_graphql from "../__generated__/ActionSearch_oneGraphStudioChainAction_graphql.mjs";

function use(variables, fetchPolicy, fetchKey, networkCacheConfig, param) {
  var data = Hooks.useLazyLoadQuery(ActionSearchQuery_graphql.node, RescriptRelay_Internal.internal_cleanObjectFromUndefinedRaw(ActionSearchQuery_graphql.Internal.convertVariables(variables)), {
        fetchKey: fetchKey,
        fetchPolicy: RescriptRelay.mapFetchPolicy(fetchPolicy),
        networkCacheConfig: networkCacheConfig
      });
  return RescriptRelay_Internal.internal_useConvertedValue(ActionSearchQuery_graphql.Internal.convertResponse, data);
}

function useLoader(param) {
  var match = Hooks.useQueryLoader(ActionSearchQuery_graphql.node);
  var loadQueryFn = match[1];
  var loadQuery = React.useMemo((function () {
          return function (param, param$1, param$2, param$3) {
            return Curry._2(loadQueryFn, ActionSearchQuery_graphql.Internal.convertVariables(param), {
                        fetchPolicy: param$1,
                        networkCacheConfig: param$2
                      });
          };
        }), [loadQueryFn]);
  return [
          Caml_option.nullable_to_opt(match[0]),
          loadQuery,
          match[2]
        ];
}

function $$fetch(environment, variables, onResult, networkCacheConfig, fetchPolicy, param) {
  Hooks.fetchQuery(environment, ActionSearchQuery_graphql.node, ActionSearchQuery_graphql.Internal.convertVariables(variables), {
          networkCacheConfig: networkCacheConfig,
          fetchPolicy: RescriptRelay.mapFetchQueryFetchPolicy(fetchPolicy)
        }).subscribe({
        next: (function (res) {
            return Curry._1(onResult, {
                        TAG: 0,
                        _0: ActionSearchQuery_graphql.Internal.convertResponse(res),
                        [Symbol.for("name")]: "Ok"
                      });
          }),
        error: (function (err) {
            return Curry._1(onResult, {
                        TAG: 1,
                        _0: err,
                        [Symbol.for("name")]: "Error"
                      });
          })
      });
  
}

function fetchPromised(environment, variables, networkCacheConfig, fetchPolicy, param) {
  return $$Promise.map(Hooks.fetchQuery(environment, ActionSearchQuery_graphql.node, ActionSearchQuery_graphql.Internal.convertVariables(variables), {
                    networkCacheConfig: networkCacheConfig,
                    fetchPolicy: RescriptRelay.mapFetchQueryFetchPolicy(fetchPolicy)
                  }).toPromise(), (function (res) {
                return ActionSearchQuery_graphql.Internal.convertResponse(res);
              }));
}

function usePreloaded(queryRef, param) {
  var data = Hooks.usePreloadedQuery(ActionSearchQuery_graphql.node, queryRef);
  return RescriptRelay_Internal.internal_useConvertedValue(ActionSearchQuery_graphql.Internal.convertResponse, data);
}

function retain(environment, variables) {
  var operationDescriptor = RelayRuntime.createOperationDescriptor(ActionSearchQuery_graphql.node, ActionSearchQuery_graphql.Internal.convertVariables(variables));
  return environment.retain(operationDescriptor);
}

var Query = {
  Types: undefined,
  use: use,
  useLoader: useLoader,
  $$fetch: $$fetch,
  fetchPromised: fetchPromised,
  usePreloaded: usePreloaded,
  retain: retain
};

function use$1(fRef) {
  var data = Hooks.useFragment(ActionSearch_oneGraphStudioChainAction_graphql.node, fRef);
  return RescriptRelay_Internal.internal_useConvertedValue(ActionSearch_oneGraphStudioChainAction_graphql.Internal.convertFragment, data);
}

function useOpt(opt_fRef) {
  var fr = opt_fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(opt_fRef)) : undefined;
  var nullableFragmentData = Hooks.useFragment(ActionSearch_oneGraphStudioChainAction_graphql.node, fr !== undefined ? Js_null_undefined.fromOption(Caml_option.some(Caml_option.valFromOption(fr))) : null);
  var data = (nullableFragmentData == null) ? undefined : Caml_option.some(nullableFragmentData);
  return RescriptRelay_Internal.internal_useConvertedValue((function (rawFragment) {
                if (rawFragment !== undefined) {
                  return ActionSearch_oneGraphStudioChainAction_graphql.Internal.convertFragment(rawFragment);
                }
                
              }), data);
}

var OneGraphStudioChainActionFragment = {
  Types: undefined,
  use: use$1,
  useOpt: useOpt
};

function ActionSearch$Action(Props) {
  var fragmentRefs = Props.fragmentRefs;
  var onInspect = Props.onInspect;
  var onAdd = Props.onAdd;
  var action = use$1(fragmentRefs);
  var color = "B20D5D";
  return React.createElement("div", {
              key: action.name,
              className: "block-search-item flex justify-start cursor-grab text-gray-700 items-center hover:text-blue-400 rounded-md px-2 my-2",
              draggable: true,
              onClick: (function (param) {
                  return Curry._1(onInspect, action);
                }),
              onDoubleClick: (function (param) {
                  return Curry._1(onAdd, action);
                }),
              onDragStart: (function ($$event) {
                  var dataTransfer = $$event.dataTransfer;
                  dataTransfer.effectAllowed = "copyLink";
                  return Curry._2(dataTransfer.setData, "text", action.id);
                })
            }, React.createElement("div", {
                  style: {
                    background: "radial-gradient(ellipse at center, #" + color + " 0%, #" + color + " 30%, transparent 30%)",
                    backgroundRepeat: "repeat-x",
                    height: "10px",
                    width: "10px"
                  }
                }), React.createElement("div", {
                  className: "flex-grow font-medium px-2 py-2 truncate",
                  style: {
                    color: "#F2F2F2"
                  }
                }, action.name), React.createElement("div", {
                  className: "px-2 rounded-r-md py-2",
                  style: {
                    minWidth: "40px"
                  }
                }, Belt_Array.keepMap(action.services, (function (service) {
                        return Belt_Option.map(Utils.serviceImageUrl(undefined, undefined, service), (function (param) {
                                      var friendlyServiceName = param[1];
                                      return React.createElement("img", {
                                                  key: friendlyServiceName,
                                                  className: "rounded-full",
                                                  style: {
                                                    border: "2px",
                                                    borderColor: Comps.colors["gray-6"],
                                                    borderStyle: "solid",
                                                    opacity: "0.80",
                                                    pointerEvents: "none"
                                                  },
                                                  title: friendlyServiceName,
                                                  alt: friendlyServiceName,
                                                  src: param[0],
                                                  width: "24px"
                                                });
                                    }));
                      }))));
}

var Action = {
  OneGraphStudioChainActionFragment: OneGraphStudioChainActionFragment,
  make: ActionSearch$Action
};

function ActionSearch(Props) {
  var onAdd = Props.onAdd;
  var onInspect = Props.onInspect;
  var onCreate = Props.onCreate;
  var onClose = Props.onClose;
  var data = use(undefined, undefined, undefined, undefined, undefined);
  var actions = data.oneGraph.studio.actions;
  var inputRef = React.useRef(null);
  ReactHotkeysHook.useHotkeys("/", (function ($$event, _handler) {
          return Belt_Option.forEach(Caml_option.nullable_to_opt(inputRef.current), (function (inputRef) {
                        $$event.preventDefault();
                        return Curry._1(inputRef.focus, undefined);
                      }));
        }), {}, undefined);
  var match = React.useState(function () {
        return {
                search: undefined,
                results: Belt_SortArray.stableSortBy(actions, (function (a, b) {
                        return $$String.compare(a.name.toLocaleLowerCase(), b.name.toLocaleLowerCase());
                      }))
              };
      });
  var setState = match[1];
  var state = match[0];
  var searchActions = function (actions, term) {
    return Belt_Array.keep(actions, (function (action) {
                    var titleMatch = Belt_Option.isSome(Caml_option.null_to_opt(action.name.match(new RegExp(term, "ig"))));
                    var servicesMatch = Belt_Array.some(action.services, (function (service) {
                            return Belt_Option.isSome(Caml_option.null_to_opt(service.match(new RegExp(term, "ig"))));
                          }));
                    if (titleMatch) {
                      return true;
                    } else {
                      return servicesMatch;
                    }
                  })).sort(function (a, b) {
                return $$String.compare(a.name.toLocaleLowerCase(), b.name.toLocaleLowerCase());
              });
  };
  React.useEffect((function () {
          var term = state.search;
          if (term !== undefined) {
            var results = searchActions(actions, term);
            Curry._1(setState, (function (oldState) {
                    return {
                            search: oldState.search,
                            results: results
                          };
                  }));
          }
          
        }), [actions.length]);
  var match$1 = state.search;
  return React.createElement("div", {
              className: "flex w-full m-0 h-full block select-none",
              style: {
                backgroundColor: Comps.colors["gray-9"]
              }
            }, React.createElement("div", {
                  className: "w-full max-h-full"
                }, React.createElement(Comps.Header.make, {
                      style: {
                        display: "flex",
                        marginRight: "6px",
                        justifyContent: "space-between"
                      },
                      children: null
                    }, "Action Library", React.createElement("span", {
                          className: "text-white cursor-pointer",
                          onClick: (function (param) {
                              return Curry._1(onClose, undefined);
                            })
                        }, "⨂")), React.createElement("div", {
                      className: "rounded-lg px-3 py-2 overflow-y-hidden",
                      style: {
                        height: "calc(100% - 40px)"
                      }
                    }, React.createElement("div", {
                          className: "flex items-center rounded-md inline-block",
                          style: {
                            backgroundColor: Comps.colors["gray-7"]
                          }
                        }, React.createElement("div", {
                              className: "pl-2"
                            }, React.createElement(Icons.Search.make, {
                                  color: Comps.colors["gray-4"]
                                })), React.createElement("input", {
                              ref: inputRef,
                              className: "w-full rounded-md text-gray-200 leading-tight focus:outline-none py-2 px-2 border-0 text-white",
                              id: "search",
                              style: {
                                backgroundColor: Comps.colors["gray-7"]
                              },
                              spellCheck: false,
                              placeholder: "Search for actions",
                              type: "text",
                              onKeyDown: (function ($$event) {
                                  var key = $$event.key;
                                  if (key !== "Escape") {
                                    return ;
                                  }
                                  var target = $$event.target;
                                  target.value = "";
                                  Curry._1(target.blur, undefined);
                                  return Curry._1(setState, (function (_oldState) {
                                                return {
                                                        search: undefined,
                                                        results: actions
                                                      };
                                              }));
                                }),
                              onChange: (function ($$event) {
                                  var query = $$event.target.value;
                                  var search = query === "" ? undefined : query;
                                  var results = search !== undefined ? searchActions(actions, search) : actions;
                                  return Curry._1(setState, (function (_oldState) {
                                                return {
                                                        search: search,
                                                        results: results
                                                      };
                                              }));
                                })
                            }), React.createElement("div", {
                              className: "flex items-center rounded-md inline "
                            }, React.createElement(Comps.Select.make, {
                                  children: null,
                                  onChange: (function ($$event) {
                                      var match = $$event.target.value;
                                      var kind;
                                      switch (match) {
                                        case "compute" :
                                            kind = "COMPUTE";
                                            break;
                                        case "mutation" :
                                            kind = "MUTATION";
                                            break;
                                        case "query" :
                                            kind = "QUERY";
                                            break;
                                        case "subscription" :
                                            kind = "SUBSCRIPTION";
                                            break;
                                        default:
                                          kind = undefined;
                                      }
                                      return Belt_Option.forEach(kind, Curry.__1(onCreate));
                                    }),
                                  style: {
                                    backgroundImage: "none",
                                    width: "3ch"
                                  },
                                  value: "never"
                                }, React.createElement("option", {
                                      value: "+"
                                    }, "+"), React.createElement("option", {
                                      value: "query"
                                    }, "+ New Query Action"), React.createElement("option", {
                                      value: "mutation"
                                    }, "+ New Mutation Action"), React.createElement("option", {
                                      value: "subscription"
                                    }, "+ New Subscription Action"), React.createElement("option", {
                                      value: "compute"
                                    }, "+ New Compute Action")))), React.createElement("div", {
                          className: "py-3 text-sm h-full overflow-y-scroll"
                        }, Belt_Array.map((
                                  match$1 !== undefined ? state.results : actions
                                ).slice(0).sort(function (a, b) {
                                  return $$String.compare(a.name.toLocaleLowerCase(), b.name.toLocaleLowerCase());
                                }), (function (action) {
                                return React.createElement(ActionSearch$Action, {
                                            fragmentRefs: action.fragmentRefs,
                                            onInspect: onInspect,
                                            onAdd: (function (action) {
                                                Curry._1(onAdd, action);
                                                return Belt_Option.forEach(Caml_option.nullable_to_opt(inputRef.current), (function (dom) {
                                                              dom.value = "";
                                                              return Curry._1(setState, (function (oldState) {
                                                                            return {
                                                                                    search: undefined,
                                                                                    results: oldState.results
                                                                                  };
                                                                          }));
                                                            }));
                                              }),
                                            key: action.id
                                          });
                              }))))));
}

var make = ActionSearch;

export {
  Query ,
  Action ,
  make ,
  
}
/* Comps Not a pure module */