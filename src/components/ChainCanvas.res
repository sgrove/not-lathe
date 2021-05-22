module OneGraphAppPackageChainFragment = %relay(`
  fragment ChainCanvas_oneGraphAppPackageChain on OneGraphAppPackageChain {
    id
    actions {
      id
      name
      description
      graphQLOperation
      upstreamActionIds
      ...NodeLabel_oneGraphStudioChainAction
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

type graphNode = {
  action: OneGraphAppPackageChainFragment.Types.fragment_actions,
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
  actions: array<OneGraphAppPackageChainFragment.Types.fragment_actions>,
  ~onEditAction,
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
      false
    })
    ->Belt.SortArray.stableSortBy((a, b) =>
      Js.String2.localeCompare(a.name, b.name)->Belt.Float.toInt
    )
    ->Belt.Array.mapWithIndex((idx, block) => {
      open React
      let nodeTitleWidth = block.name->Js.String2.length->float_of_int *. 7.2
      let nodePadding = 105.

      // Right side should be at 153 to right-align with fragment label
      let x = leftBorder -. nodeTitleWidth -. nodePadding

      let node = ReactFlow.Node.t(
        ~typ=#fragment,
        ~id=block.id,
        ~data={
          label: {"Hi there!"->string},
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
    true
  })

  Js.log2("operationBlocks: ", operationBlocks)

  let levels = Js.Dict.empty()
  let graphLevels = Js.Dict.empty()

  let rec findReqLevel = (action: OneGraphAppPackageChainFragment.Types.fragment_actions) => {
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
    Js.log3("Req level for action: ", action, level)
    levels->Js.Dict.set(action.id, level)
  })

  Js.log2("Graph Levels: ", graphLevels)

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
        let block = action.graphQLOperation

        // let variables = block->Card.getFirstVariables
        // let hasVariables = variables->Belt.Array.length > 0

        let typ = switch true {
        | true => #default
        | false => #input
        }

        let level = node.level

        let halfWidth = totalWidth /. 2.

        let furthestLeft = halfWidth -. graphLevel.width /. 2.

        let x = furthestLeft +. node.left

        let node = ReactFlow.Node.t(
          ~typ,
          ~id=action.id,
          ~data={
            label: <NodeLabel
              onEditAction
              actionRef={action.fragmentRefs}
              onDragStart={(
                ~event as _: ReactEvent.Mouse.t,
                ~request as _: NodeLabel.OneGraphStudioChainActionFragment.Types.fragment,
                ~domRef as _: Js.Nullable.t<Dom.element>,
              ) => ()}
              onPotentialVariableSourceConnect={_ => ()}
            />,
          },
          ~position={
            x: x,
            y: 100. +. (nodeHeight +. 10.0) *. level->float_of_int,
          },
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
let make = (~removeEdge, ~removeRequest, ~trace, ~chainRef, ~onActionInspected, ~onEditAction) => {
  let chain = OneGraphAppPackageChainFragment.use(chainRef)
  let diagram = diagramFromApi(chain.actions, ~onEditAction)

  <ReactFlow
    nodeTypes={
      "fragment": FragmentNodeComponent.make,
    }
    style={ReactDOMStyle.make(
      ~borderWidth="1px",
      ~borderStyle="solid",
      ~borderColor=Comps.colors["gray-10"],
      (),
    )}
    onElementsRemove={elements => {
      ()
      //   setState(oldState => {
      //     let newChain = elements->Belt.Array.reduce(oldState.chain, (accChain, element) => {
      //       let typ = switch (
      //         Obj.magic(element)["source"]->Js.Undefined.toOption,
      //         Obj.magic(element)["target"]->Js.Undefined.toOption,
      //       ) {
      //       | (Some(source), Some(target)) => #edge(source, target)
      //       | _ => #node(Obj.magic(element)["id"])
      //       }

      //       let newChain = switch typ {
      //       | #edge(source, targetRequestId) =>
      //         let newChain = removeEdge(accChain, ~dependencyId=source, ~targetRequestId)
      //         newChain
      //       | #node(source) =>
      //         let targetRequest = accChain.requests->Belt.Array.getBy(request => {
      //           request.operation.id == source
      //         })

      //         let newChain =
      //           targetRequest
      //           ->Belt.Option.map(targetRequest => removeRequest(accChain, targetRequest))
      //           ->Belt.Option.getWithDefault(accChain)
      //         newChain
      //       }

      //       newChain
      //     })

      //     let diagram = diagramFromChain(newChain)

      //     {
      //       ...oldState,
      //       inspected: Nothing({chain: newChain, trace: None}),
      //       chain: newChain,
      //       diagram: diagram,
      //     }
      //   })
    }}
    elements={diagram.elements}
    zoomOnScroll=false
    onPaneClick={_ => {
      ()
      //   setState(oldState => {
      //     ...oldState,
      //     inspected: Nothing({chain: oldState.chain, trace: trace}),
      //   })
    }}
    onPaneContextMenu={event => {
      // ReactEvent.Mouse.preventDefault(event)
      ()
    }}
    onNodeContextMenu={(_event, _node) => {
      ()
    }}
    panOnScroll=true
    onConnect={info => {
      let source = info["source"]
      let target = info["target"]

      let sourceRequest = chain.actions->Belt.Array.getBy(action => {
        action.id == source
      })

      let targetRequest = chain.actions->Belt.Array.getBy(action => {
        action.id == target
      })

      switch (sourceRequest, targetRequest) {
      | (None, _)
      | (_, None) =>
        Js.Console.warn("Couldn't find source or target request to connect")
      | (Some(source), Some(target)) => // setState(oldState => {
        //   let newRequests = oldState.chain.requests->Belt.Array.map(request => {
        //     switch target.id == request.id {
        //     | false => request
        //     | true =>
        //       let varDeps = request.variableDependencies->Belt.Array.map(varDep => {
        //         let dependency = switch varDep.dependency {
        //         | ArgumentDependency(argDep) =>
        //           let newArgDep = {
        //             ...argDep,
        //             fromRequestIds: argDep.fromRequestIds
        //             ->Belt.Array.concat([source.id])
        //             ->Utils.String.distinctStrings,
        //           }

        //           Chain.ArgumentDependency(newArgDep)
        //         | other => other
        //         }
        //         let varDep = {...varDep, dependency: dependency}

        //         varDep
        //       })

        //       {
        //         ...request,
        //         variableDependencies: varDeps,
        //         dependencyRequestIds: request.dependencyRequestIds
        //         ->Belt.Array.concat([source.id])
        //         ->Utils.String.distinctStrings,
        //       }
        //     }
        //   })

        //   let sortedRequests = Chain.toposortRequests(newRequests)

        //   switch sortedRequests {
        //   | Error(#circularDependencyDetected) => oldState
        //   | Ok(sortedRequests) =>
        //     let newChain = {...oldState.chain, requests: sortedRequests}

        //     let diagram = diagramFromChain(newChain)

        //     {...oldState, chain: newChain, diagram: diagram}
        //   }
        // })
        ()
      }
    }}
    onElementClick={(_, node) => {
      let id = node->ReactFlow.Node.idGet

      onActionInspected(id)
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
}
