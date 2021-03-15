// const dagreGraph = new dagre.graphlib.Graph();
// dagreGraph.setDefaultEdgeLabel(() => ({}));
type graph

module Graphlib = {
  @module("dagre") @scope("graphlib") @new external graph: unit => graph = "Graph"

  type edgeLabel
  @send external setDefaultEdgeLabel: (graph, unit => edgeLabel) => unit = "setDefaultEdgeLabel"
}

@deriving(abstract)
type dagreGraphOptions = {
  @optional
  rankdir: [#TB | #BT | #RL | #LR],
  @optional ranker: string,
  @optional marginx: float,
  @optional marginy: float,
  @optional ranksep: float,
  @optional edgesep: float,
  @optional nodesep: float,
}

@send external setGraph: (graph, dagreGraphOptions) => unit = "setGraph"

let dagreGraph = Graphlib.graph()
dagreGraph->Graphlib.setDefaultEdgeLabel(() => Js.Dict.empty()->Obj.magic)

type nodeSize = {
  width: float,
  height: float,
  x: float,
  y: float,
}

@send external setNode: (graph, string, nodeSize) => unit = "setNode"
@send external setEdge: (graph, string, string) => unit = "setEdge"

@module("dagre") external layout: graph => unit = "layout"

@send external node: (graph, string) => option<nodeSize> = "node"

let getLayoutedElements = (
  ~nodes: array<ReactFlow.Node.t>,
  ~edges: array<ReactFlow.Edge.t>,
  ~nodeWidth,
  ~nodeHeight,
) => {
  dagreGraph->setGraph(dagreGraphOptions(~rankdir=#TB, ~marginx=2., ~marginy=2., ()))
  nodes->Belt.Array.forEach(node => {
    dagreGraph->setNode(
      node->ReactFlow.Node.idGet,
      {width: nodeWidth, height: nodeHeight, x: 0., y: 0.},
    )
  })
  edges->Belt.Array.forEach(node => {
    dagreGraph->setEdge(node->ReactFlow.Edge.sourceGet, node->ReactFlow.Edge.targetGet)
  })

  dagreGraph->layout

  let nodes = nodes->Belt.Array.map(existingNode => {
    let nodeWithPosition = dagreGraph->node(existingNode->ReactFlow.Node.idGet)

    nodeWithPosition->Belt.Option.forEach(nodeWithPosition => {
      // Unfortunately we need this little hack to pass a slighlty different position
      // in order to notify react flow about the change
      existingNode->ReactFlow.Node.positionSet({
        x: nodeWithPosition.x +. Js.Math.random() /. 1000.,
        y: nodeWithPosition.y +. Js.Math.random() /. 1000.,
      })
    })

    existingNode
  })

  let layoutedElements: array<ReactFlow.element> =
    Belt.Array.concat(nodes, edges->Obj.magic)->Obj.magic
  layoutedElements
}
