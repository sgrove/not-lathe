// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Dagre from "dagre";
import * as Belt_Array from "bs-platform/lib/es6/belt_Array.mjs";
import * as Belt_Option from "bs-platform/lib/es6/belt_Option.mjs";

var Graphlib = {};

var dagreGraph = new (Dagre.graphlib.Graph)();

dagreGraph.setDefaultEdgeLabel(function (param) {
      return {};
    });

function getLayoutedElements(nodes, edges, nodeWidth, nodeHeight) {
  dagreGraph.setGraph({
        rankdir: "TB",
        marginx: 2,
        marginy: 2
      });
  Belt_Array.forEach(nodes, (function (node) {
          dagreGraph.setNode(node.id, {
                width: nodeWidth,
                height: nodeHeight,
                x: 0,
                y: 0
              });
          
        }));
  Belt_Array.forEach(edges, (function (node) {
          dagreGraph.setEdge(node.source, node.target);
          
        }));
  Dagre.layout(dagreGraph);
  var nodes$1 = Belt_Array.map(nodes, (function (existingNode) {
          var nodeWithPosition = dagreGraph.node(existingNode.id);
          Belt_Option.forEach(nodeWithPosition, (function (nodeWithPosition) {
                  existingNode.position = {
                    x: nodeWithPosition.x + Math.random() / 1000,
                    y: nodeWithPosition.y + Math.random() / 1000
                  };
                  
                }));
          return existingNode;
        }));
  return Belt_Array.concat(nodes$1, edges);
}

export {
  Graphlib ,
  dagreGraph ,
  getLayoutedElements ,
  
}
/* dagreGraph Not a pure module */
