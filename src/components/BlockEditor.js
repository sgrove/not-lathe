// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Comps from "./Comps.js";
import * as Curry from "bs-platform/lib/es6/curry.mjs";
import * as React from "react";
import * as Graphql from "graphql";
import * as GraphQLJs from "../bindings/GraphQLJs.js";
import * as Belt_Array from "bs-platform/lib/es6/belt_Array.mjs";
import * as Belt_Option from "bs-platform/lib/es6/belt_Option.mjs";
import * as BsReactMonaco from "../bindings/BsReactMonaco.js";
import * as ReactHotkeysHook from "react-hotkeys-hook";
import GraphiqlExplorer from "@sgrove/graphiql-explorer";

var GraphiQLExplorer = {};

function BlockEditor(Props) {
  var schema = Props.schema;
  var initialBlock = Props.block;
  var onClose = Props.onClose;
  var onSave = Props.onSave;
  var availableFragments = Props.availableFragments;
  var match = React.useState(function () {
        return initialBlock;
      });
  var setBlock = match[1];
  var block = match[0];
  React.useEffect((function () {
          Curry._1(setBlock, (function (param) {
                  return initialBlock;
                }));
          
        }), [initialBlock.body]);
  var updateBlock = function (newOperationDoc) {
    var opDoc = Graphql.parse(newOperationDoc);
    var title = Belt_Option.getWithDefault(Belt_Array.get(GraphQLJs.operationNames(opDoc), 0), "Untitled");
    return Curry._1(setBlock, (function (oldBlock) {
                  return {
                          id: oldBlock.id,
                          title: title,
                          description: oldBlock.description,
                          body: newOperationDoc,
                          kind: oldBlock.kind,
                          contributedBy: oldBlock.contributedBy,
                          services: oldBlock.services
                        };
                }));
  };
  var match$1 = block.kind;
  var explorer = match$1 >= 4 ? null : React.createElement("div", {
          className: "graphiql-container w-full"
        }, React.createElement(GraphiqlExplorer, {
              schema: schema,
              explorerIsOpen: true,
              query: block.body,
              width: "100%",
              height: "100%",
              onEdit: updateBlock,
              availableFragments: availableFragments
            }));
  var editor = React.createElement(BsReactMonaco.Editor.make, {
        height: "100%",
        value: block.body,
        className: "flex-grow h-full",
        language: "graphql",
        theme: "vs-dark",
        options: {
          minimap: {
            enabled: false
          }
        },
        onChange: (function (newOperationDoc, param) {
            return updateBlock(newOperationDoc);
          })
      });
  ReactHotkeysHook.useHotkeys("esc", (function ($$event, _handler) {
          $$event.preventDefault();
          $$event.stopPropagation();
          return Curry._1(onClose, undefined);
        }), {}, undefined);
  return React.createElement("div", {
              className: "flex w-full flex-col"
            }, React.createElement("div", {
                  className: "flex flex-grow flex-row h-full"
                }, explorer, editor), React.createElement("div", {
                  className: "w-full ml-auto flex"
                }, React.createElement(Comps.Button.make, {
                      onClick: (function (param) {
                          return Curry._2(onSave, block, block);
                        }),
                      className: "flex-grow",
                      children: "Save"
                    }), React.createElement(Comps.Button.make, {
                      onClick: (function (param) {
                          return Curry._1(onClose, undefined);
                        }),
                      className: "flex-grow",
                      children: "Cancel"
                    })));
}

var make = BlockEditor;

export {
  GraphiQLExplorer ,
  make ,
  
}
/* Comps Not a pure module */
