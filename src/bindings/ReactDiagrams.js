// Generated by ReScript, PLEASE EDIT WITH CARE

import * as ReactDiagramsBridgeJs from "./ReactDiagramsBridge.js";

var LinkFactory = {};

var Dagre = {};

function customClickAction(prim) {
  return new ReactDiagramsBridgeJs.CustomClickAction(prim);
}

var ActionEventBus = {
  customClickAction: customClickAction
};

var Engine = {
  LinkFactory: LinkFactory,
  Dagre: Dagre,
  ActionEventBus: ActionEventBus
};

var DefaultLinkModel = {};

var RightAngleLinkModel = {};

var Port = {};

function rightAnglePortModel(prim, prim$1, prim$2) {
  return new ReactDiagramsBridgeJs.RightAnglePortModel(prim, prim$1, prim$2);
}

var DefaultNodeModel = {};

var Link = {};

var Canvas = {};

var DiagramModel = {};

var InputType = {};

export {
  Engine ,
  DefaultLinkModel ,
  RightAngleLinkModel ,
  Port ,
  rightAnglePortModel ,
  DefaultNodeModel ,
  Link ,
  Canvas ,
  DiagramModel ,
  InputType ,
  
}
/* ./ReactDiagramsBridge.js Not a pure module */
