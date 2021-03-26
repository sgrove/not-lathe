type element

module Node = {
  type nodeType = [#default | #input | #output | #fragment | #operation]

  type position = {
    x: float,
    y: float,
  }

  type nodeData = {label: React.element}

  @deriving(abstract)
  type t = {
    id: string,
    @as("type") @optional
    typ: nodeType,
    data: nodeData,
    mutable position: position,
    @optional
    draggable: bool,
    @optional
    selectable: bool,
    @optional
    connectable: bool,
    @optional
    className: string,
    @optional
    style: ReactDOMStyle.t,
    @optional
    onClick: ReactEvent.Mouse.t => unit,
  }
}

module Edge = {
  @deriving(abstract)
  type t = {
    id: string,
    source: string,
    target: string,
    @optional
    style: ReactDOMStyle.t,
    @optional
    animated: bool,
    @optional @as("type")
    typ: [
      | #default
      | #straight
      | #step
      | #smoothstep
    ],
  }
}

type reactFlowInstance

type connectionLineType = [
  | #default
  | #straight
  | #step
  | #smoothstep
]

module Provider = {
  @react.component @module("react-flow-renderer")
  external make: (~children: React.element) => React.element = "ReactFlowProvider"
}

module Controls = {
  @module("react-flow-renderer") @react.component
  external make: (
    // - default
    ~showZoom: bool=?,
    // - default
    ~showFitView: bool=?,
    // - default
    ~showInteractive: bool=?,
    // properties
    ~style: ReactDOMStyle.t=?,
    // class name
    ~className: string=?,
    // function that gets triggered when the zoom in button is pressed
    ~onZoomIn: unit => unit=?,
    // function that gets triggered when the zoom out button is pressed
    ~onZoomOut: unit => unit=?,
    // function that gets triggered when the fit-to-view button is pressed
    ~onFitView: unit => unit=?,
    // function that gets triggered when the lock button is pressed - passes the new value
    ~onInteractiveChange: bool => unit=?,
  ) => React.element = "Controls"
}

type connection = {
  target: string,
  source: string,
  sourceHandle: Js.Nullable.t<string>,
  targetHandle: Js.Nullable.t<string>,
}

module Handle = {
  @module("react-flow-renderer") @react.component
  external make: (
    ~type_: [#source | #target],
    ~id: string=?,
    ~position: [#left | #right | #top | #bottom]=?,
    ~onConnect: unit => unit=?,
    ~isValidConnection: connection => bool=?,
    ~style: ReactDOMStyle.t=?,
    ~className: string=?,
  ) => React.element = "Handle"
}

@module("react-flow-renderer") @react.component
external make: (
  ~elements: array<element>,
  ~className: string=?,
  ~style: ReactDOMStyle.t=?,
  ~onElementClick: (ReactEvent.Mouse.t, Node.t) => unit=?,
  ~onElementsRemove: array<Node.t> => unit=?,
  ~onLoad: reactFlowInstance => unit=?,
  ~connectionLineType: connectionLineType=?,
  ~onPaneClick: ReactEvent.Mouse.t => unit=?,
  ~onConnect: {
    "source": string,
    "sourceHandle": option<string>,
    "target": string,
    "targetHandle": option<string>,
  } => unit=?,
  ~onConnectStart: ('event, {"nodeId": string, "handleType": string}) => unit=?,
  // Interaction
  //  This applies to all nodes. You can also change the behavior of a specific node with the draggable node option. If this option is set to false and you have clickable elements inside your node, you need to set pointer-events
  ~nodesDraggable: bool=?,
  //  This applies to all nodes. You can also change the behavior of a specific node with the connectable node option
  ~nodesConnectable: bool=?,
  //  This applies to all elements. You can also change the behavior of a specific node with the selectable node option. If this option is set to false and you have clickable elements inside your node, you need to set pointer-events
  ~elementsSelectable: bool=?,
  //  Zoom the graph in and out using the mousewheel or trackpad
  ~zoomOnScroll: bool=?,
  //  Zoom the graph in and out using pinch
  ~zoomOnPinch: bool=?,
  //  Move the graph while keeping the zoomlevel using mousewheel or trackpad. Overwrites zoomOnScroll
  ~panOnScroll: bool=?,
  // 5. Controls how fast the canvas is moved while using the mousewheel. Only has an effect if panOnScroll is enabled
  ~panOnScrollSpeed: float=?,
  //  Possible values are 'free' (all directions), 'vertical' (only vertical) or 'horizontal' (only horizontal)
  ~panOnScrollMode: [#free | #vertical | #horizontal]=?,
  ~zoomOnDoubleClick: bool=?,
  ~selectNodesOnDrag: bool=?,
  // - If set to false, panning and zooming is disabled
  ~paneMoveable: bool=?,
  //  Possible values are 'strict' (only source to target connections are possible) or 'loose' (source to source and target to target connections are allowed)
  ~connectionMode: [#strict | #loose]=?,
  ~onNodeContextMenu: (ReactEvent.Mouse.t, Node.t) => unit=?,
  ~onPaneContextMenu: ReactEvent.Mouse.t => unit=?,
  ~children: React.element=?,
  ~nodeTypes: Js.t<'a>=?,
) => React.element = "default"

type fitViewOptions = {padding: float, includeHiddenNodes: bool}

type rect = {x: float, y: float, width: float, height: float}

type zoomPanHelper = {
  fitView: fitViewOptions => unit,
  zoomIn: unit => unit,
  zoomOut: unit => unit,
  zoomTo: float => unit,
  setCenter: (float, float, option<float>) => unit,
  fitBounds: (rect, option<float>) => unit,
  initialized: bool,
}

@module("react-flow-renderer") external useZoomPanHelper: unit => zoomPanHelper = "useZoomPanHelper"

module Background = {
  @module("react-flow-renderer") @react.component
  external make: (
    ~variant: [#dots | #lines]=?,
    ~gap: int=?,
    ~size: int=?,
    ~color: string=?,
    ~style: ReactDOMStyle.t=?,
    ~className: string=?,
  ) => React.element = "Background"
}
