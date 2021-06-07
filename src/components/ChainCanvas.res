module Fragment = %relay(`
  fragment ChainCanvas_chain on OneGraphAppPackageChain {
    id
    actions {
      id
      name
      description
      graphqlOperation
      graphqlOperationKind
      upstreamActionIds
      ...NodeLabel_action
    }
  }
`)

type diagram = {
  nodes: array<ReactFlow.Node.t>,
  edges: array<ReactFlow.Edge.t>,
  elements: array<ReactFlow.element>,
}

type diagramEdgeData = {
  id: string,
  source: string,
  target: string,
}

module FragmentNodeComponent = {
  @react.component @module("./FragmentNode.js")
  external make: (~data: 'a) => React.element = "default"
}

module MouseCursorNodeComponent = {
  @react.component @module("./MouseCursorNode.js")
  external make: (~data: 'a) => React.element = "default"
}

module FlowRemoteConnector = {
  @react.component @module("./FlowRemoteConnector.js")
  external make: (
    ~id: string,
    ~sourceX: float,
    ~sourceY: float,
    ~targetX: float,
    ~targetY: float,
    ~style: ReactDOMStyle.t=?,
    ~data: 'data=?,
    ~arrowHeadType: 'arrowHeadType=?,
    ~markerEndId: string=?,
  ) => React.element = "default"
}

type graphNode = {
  action: Fragment.Types.fragment_actions,
  level: int,
  left: float,
}

type graphLevel = {
  nodeCount: int,
  width: float,
  nodes: array<graphNode>,
  level: int,
}

let emptyGraphLevel = level => {
  nodeCount: 0,
  width: 0.,
  nodes: [],
  level: level,
}

let diagramFromApi = (
  actions: array<Fragment.Types.fragment_actions>,
  ~onEditAction,
  ~sharedBlockPositions: option<Yjs.Document.Map.t>,
): //   ~onDragStart,
//   ~schema,
//   ~onPotentialVariableSourceConnect,
//   (),
diagram => {
  let nodeHeight = 50.
  let nodeGap = 10.

  let nodeStyle = ReactDOMStyle.make(
    ~width="unset",
    // ~background="unset",
    // ~padding="0px",
    // ~margin="0px",
    // ~backgroundColor="rgb(27, 29, 31)",
    // ~color="rgb(240,240,240)",
    // ~borderWidth="1px",
    // ~borderColor="rgb(63,63,63)",
    (),
  )

  let leftBorder = 300.

  let fragmentNodes =
    actions
    ->Belt.Array.keep(action => {
      action.graphqlOperationKind === #FRAGMENT
    })
    ->Belt.SortArray.stableSortBy((a, b) =>
      Js.String2.localeCompare(a.name, b.name)->Belt.Float.toInt
    )
    ->Belt.Array.mapWithIndex((idx, block) => {
      let nodeTitleWidth = block.name->Js.String2.length->float_of_int *. 7.2
      let nodePadding = 105.

      // Right side should be at 153 to right-align with fragment label
      let x = leftBorder -. nodeTitleWidth -. nodePadding

      let node = ReactFlow.Node.t(
        ~typ=#fragment,
        ~id=block.id,
        ~data={
          label: {"Hi there!"->React.string},
        },
        ~position={x: x, y: nodeHeight *. idx->float_of_int +. 10. +. 30.},
        ~draggable=false,
        ~connectable=false,
        ~style=nodeStyle,
        ~className="node-label",
        (),
      )
      node
    })

  let fragmentLabelNode = switch fragmentNodes->Belt.Array.length {
  | 0 => []
  | _ =>
    let node = ReactFlow.Node.t(
      ~typ=#fragment,
      ~id="fragmentColumnLabel",
      ~data={
        label: {"Reusable Fragments"->React.string},
      },
      ~position={x: 5., y: 10.},
      ~draggable=false,
      ~connectable=false,
      ~style=ReactDOMStyle.make(~width="unset", ()),
      (),
    )
    [node]
  }

  let operationBlocks = actions->Belt.Array.keep(action => {
    action.graphqlOperationKind !== #FRAGMENT
  })

  let levels = Js.Dict.empty()
  let graphLevels = Js.Dict.empty()

  let rec findReqLevel = (action: Fragment.Types.fragment_actions) => {
    let level = levels->Js.Dict.get(action.id)

    switch level {
    | Some(level) => level
    | None =>
      let highestDependency = action.upstreamActionIds->Belt.Array.reduce(-2, (level, nextId) => {
        actions
        ->Belt.Array.getBy(actionDependency => {
          actionDependency.id == nextId
        })
        ->Belt.Option.flatMap(actionDependency => {
          switch actionDependency.id == action.id {
          | false =>
            let dependencyLevel = findReqLevel(actionDependency)
            levels->Js.Dict.set(nextId, dependencyLevel)

            Some(Js.Math.max_int(level, dependencyLevel))
          | true => None
          }
        })
        ->Belt.Option.getWithDefault(level)
      })

      let requestLevel = highestDependency + 1

      let nodeTitleWidth = action.name->Js.String2.length->float_of_int *. 7.2
      let nodePadding = 105.
      let requestWidth = nodeTitleWidth +. nodePadding +. nodeGap

      let graphLevel =
        graphLevels
        ->Js.Dict.get(requestLevel->string_of_int)
        ->Belt.Option.getWithDefault(emptyGraphLevel(requestLevel))

      let graphNode = {
        action: action,
        level: requestLevel,
        left: graphLevel.width,
      }

      let newGraphLevel = {
        ...graphLevel,
        width: graphLevel.width +. requestWidth,
        nodeCount: graphLevel.nodeCount + 1,
        nodes: graphLevel.nodes->Belt.Array.concat([graphNode]),
      }

      graphLevels->Js.Dict.set(requestLevel->string_of_int, newGraphLevel)

      requestLevel
    }
  }

  operationBlocks->Belt.Array.forEach(action => {
    let level = findReqLevel(action)
    levels->Js.Dict.set(action.id, level)
  })

  let totalWidth =
    graphLevels
    ->Js.Dict.values
    ->Belt.Array.reduce(0., (highest, next) => next.width > highest ? next.width : highest)

  let operationNodes =
    graphLevels
    ->Js.Dict.values
    ->Belt.SortArray.stableSortBy((a, b) => a.level - b.level)
    ->Belt.Array.map(graphLevel =>
      graphLevel.nodes->Belt.Array.map(node => {
        let action = node.action

        let typ = switch true {
        | true => #default
        | false => #input
        }

        let level = node.level

        let halfWidth = totalWidth /. 2.

        let furthestLeft = halfWidth -. graphLevel.width /. 2.

        let x = furthestLeft +. node.left

        let existingPosition = sharedBlockPositions->Belt.Option.flatMap(positions => {
          positions->Yjs.Document.Map.get(action.id)->Js.Undefined.toOption
        })

        let position = existingPosition->Belt.Option.getWithDefault({
          ReactFlow.Node.x: x,
          y: 100. +. (nodeHeight +. 10.0) *. level->float_of_int,
        })

        let node = ReactFlow.Node.t(
          ~typ,
          ~id=action.id,
          ~data={
            label: <NodeLabel onEditAction actionRef={action.fragmentRefs} />,
          },
          ~position,
          ~draggable=true,
          ~connectable=true,
          ~style=nodeStyle,
          ~className="node-label",
          (),
        )
        node
      })
    )
    ->Belt.Array.concatMany

  let actionEdge =
    actions
    ->Belt.Array.map(action => {
      let target = action.id

      let r = action.upstreamActionIds->Belt.Array.keepMap(actionId => {
        let reifiedAction = actions->Belt.Array.getBy(subAction => {
          subAction.id == actionId
        })

        reifiedAction->Belt.Option.map(actionDependency => {
          let source = actionDependency.id
          let id = j`${source}-${target}`

          let edge: diagramEdgeData = {id: id, source: source, target: target}
          edge
        })
      })
      r
    })
    ->Belt.Array.concatMany

  let distinct = Belt.Set.String.empty

  let (_, distinctEdges) = Belt.Array.concat(actionEdge, [])->Belt.Array.reduce((distinct, []), (
    (distinct, edges),
    edge,
  ) => {
    switch distinct->Belt.Set.String.has(edge.id) {
    | false => (distinct->Belt.Set.String.add(edge.id), edges->Belt.Array.concat([edge]))
    | true => (distinct, edges)
    }
  })

  let edges = distinctEdges->Belt.Array.map(({id, source, target}) => {
    let edge = ReactFlow.Edge.t(
      ~id,
      ~source,
      ~target,
      ~animated=true,
      ~style={
        ReactDOMStyle.make(~stroke="rgb(78,160,23)", ~strokeWidth="2px", ())
      },
      ~typ=#step,
      (),
    )
    edge
  })

  let nodes = Belt.Array.concat(fragmentNodes, operationNodes)

  let elements = Belt.Array.concatMany([nodes, edges->Obj.magic, fragmentLabelNode])->Obj.magic

  {nodes: nodes, edges: edges, elements: elements}
}

@react.component
let make = (~chainRef, ~onActionInspected, ~onEditAction, ~onSelectionCleared, ~onConnect) => {
  let chain = Fragment.use(chainRef)
  open React
  let collaborationContext = useContext(CollaborationContext.context)
  let sharedBlockPositions = collaborationContext.getSharedMap(~channelId=chain.id, ~id="positions")
  let diagram = chain.actions->diagramFromApi(~onEditAction, ~sharedBlockPositions)
  let {project} = ReactFlow.useZoomPanHelper()

  let connectorLines = []
  let mouseCursors = []

  collaborationContext.getSharedChannelState(~id=chain.id)->Belt.Option.forEach(((
    localClientId,
    states,
  )) => {
    let entries = Obj.magic(states)["entries"](.)->Js.Array.from

    entries->Belt.Array.forEach(((
      clientId: Yjs.Awareness.clientId,
      presence: CollaborationContext.presence,
    )) =>
      switch (
        clientId == localClientId,
        Js.Undefined.toOption(presence.position),
        Js.Undefined.toOption(presence.connectSourceActionId),
      ) {
      | (true, _, _)
      | (_, None, _) => ()
      | (false, Some(mousePosition), connectSourceActionId) =>
        let mouseElementId = j`cursor-${clientId->Obj.magic}`
        let mouseCursor = ReactFlow.Node.t(
          ~typ=#mouseCursor,
          ~id=mouseElementId,
          ~data={
            label: <div
              className="presence-mouse" style={ReactDOMStyle.make(~color=presence.color, ())}>
              <div>
                <Icons.MouseCursor
                  className="inline-block" color=presence.color width="16px" height="16px"
                />
                {presence.audioVolumeLevel
                ->Js.Undefined.toOption
                ->Belt.Option.mapWithDefault(React.null, level =>
                  <Icons.Volume.Auto
                    className="inline-block" color=presence.color width="16px" height="16px" level
                  />
                )}
              </div>
              <div className="pl-2">
                <span className="pl-2"> {presence.name->React.string} </span>
              </div>
            </div>,
          },
          ~position={
            x: mousePosition.x,
            y: mousePosition.y,
          },
          ~draggable=false,
          ~connectable=true,
          ~selectable=false,
          ~className="node-label",
          (),
        )

        connectSourceActionId->Belt.Option.forEach(connectSourceActionId => {
          let connectorLine = ReactFlow.Edge.t(
            ~typ=#straight,
            ~id=j`edges-connect-line-${clientId->Obj.magic}`,
            ~source=connectSourceActionId,
            ~target=mouseElementId,
            ~style={ReactDOMStyle.make(~stroke=presence.color, ~strokeWidth="3px", ())},
            (),
          )
          let _: int = connectorLines->Js.Array2.push(connectorLine)
        })

        let _: int = mouseCursors->Js.Array2.push(mouseCursor)
      }
    )
  })

  let elements = Belt.Array.concatMany([
    diagram.elements,
    connectorLines->Obj.magic,
    mouseCursors->Obj.magic,
  ])

  let diagram = {
    ...diagram,
    elements: elements,
  }

  <div
    onMouseMove={event => {
      let boundingRect = Obj.magic(
        ReactEvent.Mouse.currentTarget(event),
      )["getBoundingClientRect"](.)
      let left: int = boundingRect["left"]
      let top: int = boundingRect["top"]
      let screenPosition = {
        ReactFlow.x: (event->ReactEvent.Mouse.clientX - left)->float_of_int,
        y: (event->ReactEvent.Mouse.clientY - top)->float_of_int,
      }

      let projectedPosition = project(. screenPosition)

      collaborationContext.updateLocalPosition(~channelId=chain.id, ~position=projectedPosition)
    }}
    style={ReactDOMStyle.make(~width="100%", ~height="100%", ())}>
    <ReactFlow
      nodeTypes={
        "fragment": FragmentNodeComponent.make,
        "mouseCursor": MouseCursorNodeComponent.make,
      }
      edgeTypes={
        "remote": FlowRemoteConnector.make,
      }
      style={ReactDOMStyle.make(
        ~borderWidth="1px",
        ~borderStyle="solid",
        ~borderColor=Comps.colors["gray-10"],
        (),
      )}
      elements={diagram.elements}
      zoomOnScroll=false
      onPaneClick={_ => {
        onSelectionCleared()
      }}
      onPaneContextMenu={event => {
        ReactEvent.Mouse.preventDefault(event)
      }}
      onNodeContextMenu={(_event, _node) => {
        ()
      }}
      panOnScroll=true
      onConnectStart={(event, node) => {
        let boundingRect = Obj.magic(
          ReactEvent.Mouse.currentTarget(event),
        )["getBoundingClientRect"](.)
        let left: int = boundingRect["left"]
        let top: int = boundingRect["top"]
        let screenPosition = {
          ReactFlow.x: (event->ReactEvent.Mouse.clientX - left)->float_of_int,
          y: (event->ReactEvent.Mouse.clientY - top)->float_of_int,
        }

        Js.log3("Connect start: ", event, node)

        let projectedPosition = project(. screenPosition)

        collaborationContext.updateConnectSourceActionId(
          ~channelId=chain.id,
          ~sourceActionId=Some(node["nodeId"]),
        )
      }}
      onConnectEnd={(_event, _node) => {
        collaborationContext.updateConnectSourceActionId(~channelId=chain.id, ~sourceActionId=None)
      }}
      onConnect={info => {
        let sourceAction = chain.actions->Belt.Array.getBy(action => {
          action.id == info["source"]
        })

        let targetAction = chain.actions->Belt.Array.getBy(action => {
          action.id == info["target"]
        })

        switch (sourceAction, targetAction) {
        | (None, _)
        | (_, None) =>
          Js.Console.warn("Couldn't find source or target request to connect")
        | (Some(source), Some(target)) =>
          onConnect(~sourceActionId=source.id, ~targetActionId=target.id)
        }
      }}
      onElementClick={(_, node) => {
        node->ReactFlow.Node.idGet->onActionInspected
      }}
      onNodeDrag={(_event, node) => {
        switch sharedBlockPositions {
        | None => ()
        | Some(sharedBlockPositions) =>
          let id = node->ReactFlow.Node.idGet
          let position = node->ReactFlow.Node.positionGet
          sharedBlockPositions->Yjs.Document.Map.set(id, position)
        }
      }}
      connectionLineType=#smoothstep>
      <ReactFlow.Controls showZoom=false showFitView=true showInteractive=false />
      <ReactFlow.Background
        variant=#lines
        gap={20}
        size={1}
        color={Comps.colors["gray-1"]}
        style={ReactDOMStyle.make(~backgroundColor="rgb(31, 33, 37)", ())}
      />
    </ReactFlow>
  </div>
}
