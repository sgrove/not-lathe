module SimpleTooltip = {
  @react.component @module("react-simple-tooltip")
  external make: (
    ~arrow: float=?,
    ~background: string=?,
    ~border: string=?,
    ~color: string=?,
    ~content: React.element=?,
    ~customCss: ReactDOMStyle.t=?,
    ~fadeDuration: float=?,
    ~fadeEasing: string=?,
    ~fixed: bool=?,
    ~fontFamily: bool=?,
    ~fontSize: bool=?,
    ~padding: float=?,
    ~placement: [#left | #top | #right | #bottom]=?,
    ~radius: float=?,
    ~zIndex: int=?,
    ~children: React.element,
  ) => React.element = "default"
}

module FragmentNodeComponent = {
  @react.component @module("./FragmentNode.js")
  external make: (~data: Js.t<'a>) => React.element = "default"
}

type blockEdit = Nothing | Create(Card.block) | Edit(Card.block)

type diagram = {
  nodes: array<ReactFlow.Node.t>,
  edges: array<ReactFlow.Edge.t>,
  elements: array<ReactFlow.element>,
}

type scriptEditor = {
  isOpen: bool,
  editor: option<BsReactMonaco.editor>,
  monaco: option<BsReactMonaco.monaco>,
}

type debuggable =
  | Chain
  | CompiledChain

type state = {
  diagram: option<diagram>,
  card: option<Card.block>,
  schema: GraphQLJs.schema,
  chain: Chain.t,
  compiledChain: option<Chain.mockCompiledChain>,
  chainResult: option<Js.Json.t>,
  scriptFunctions: array<string>,
  chainExecutionResults: option<Js.Json.t>,
  blocks: array<Card.block>,
  inspected: Inspector.inspectable,
  blockEdit: blockEdit,
  scriptEditor: scriptEditor,
  savedChainId: option<string>,
  requestValueCache: Js.Dict.t<Js.Json.t>,
  debugUIItems: array<debuggable>,
  connectionDrag: ConnectionContext.connectionDrag,
}

let makeBlankBlock = (kind): Card.block => {
  let (kind: Card.operationKind, body) = switch kind {
  | #query => (Query, "query Untitled { __typename }")
  | #mutation => (Mutation, "mutation Untitled { __typename }")
  | #subscription => (Subscription, "subscription Untitled { __typename }")
  | #compute => (
      Compute,
      `# Fields on ComputeType will turn into variables for you to compute
# based on other blocks or user input
type ComputeType {
  name: String!
}`,
    )
  }

  {
    title: "Untitled",
    id: Uuid.v4(),
    services: [],
    body: body,
    description: "TODO",
    contributedBy: None,
    kind: kind,
  }
}

let compileChain = (schema, chain: Chain.t): option<Chain.mockCompiledChain> => {
  try {
    let compiled = chain->Chain.compileAsObj
    let parsedOperationDoc = compiled.operationDoc->GraphQLJs.parse
    let mockedVariables = GraphQLJs.Mock.mockOperationDocVariables(schema, parsedOperationDoc)

    Some({
      compiled: compiled,
      variables: mockedVariables,
    })
  } catch {
  | _ex => None
  }
}

module BlockSearch = {
  type state = {
    search: option<string>,
    results: array<Card.block>,
  }

  @val external alert: string => unit = "alert"

  @react.component
  let make = (
    ~onAdd: Card.block => unit,
    ~onInspect: Card.block => unit,
    ~blocks: array<Card.block>,
    ~onCreate,
  ) => {
    open React

    let (state, setState) = useState(() => {
      search: None,
      results: blocks
      ->Belt.Array.copy
      ->Js.Array2.sortInPlaceWith((a, b) =>
        String.compare(a.title->Js.String2.toLocaleLowerCase, b.title->Js.String2.toLocaleLowerCase)
      ),
    })

    let searchBlocks = (blocks: array<Card.block>, term) =>
      blocks
      ->Belt.Array.keep(block => {
        let titleMatch =
          block.title
          ->Js.String2.match_(term->Js.Re.fromStringWithFlags(~flags="ig"))
          ->Belt.Option.isSome

        let servicesMatch =
          block.services->Belt.Array.some(service =>
            service
            ->Js.String2.match_(term->Js.Re.fromStringWithFlags(~flags="ig"))
            ->Belt.Option.isSome
          )

        titleMatch || servicesMatch
      })
      ->Js.Array2.sortInPlaceWith((a, b) =>
        String.compare(a.title->Js.String2.toLocaleLowerCase, b.title->Js.String2.toLocaleLowerCase)
      )

    useEffect1(() => {
      switch state.search {
      | None => ()
      | Some(term) =>
        let results = blocks->searchBlocks(term)
        setState(oldState => {...oldState, results: results})
      }
      None
    }, [blocks->Belt.Array.length])

    <div
      className="flex w-full m-0 h-full block select-none"
      style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-9"], ())}>
      <div className="w-full max-h-full">
        <Comps.Header> {"Block Library"->React.string} </Comps.Header>
        <div
          className="rounded-lg px-3 py-2 overflow-y-hidden"
          style={ReactDOMStyle.make(~height="calc(100% - 40px)", ())}>
          <div
            className="flex items-center  rounded-md inline-block"
            style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}>
            <div className="pl-2"> <Icons.Search color={Comps.colors["gray-4"]} /> </div>
            <input
              className="w-full rounded-md text-gray-200 leading-tight focus:outline-none py-2 px-2 border-0 text-white"
              style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}
              id="search"
              spellCheck=false
              type_="text"
              placeholder="Search for blocks"
              onChange={event => {
                let query = ReactEvent.Form.target(event)["value"]
                let search = switch query {
                | "" => None
                | other => Some(other)
                }

                let results = switch search {
                | None => blocks
                | Some(term) => blocks->searchBlocks(term)
                }

                setState(_oldState => {search: search, results: results})
              }}
            />
            <div className="flex items-center rounded-md inline ">
              <Comps.Select
                style={ReactDOMStyle.make(~width="3ch", ~backgroundImage="none", ())}
                value="never"
                onChange={event => {
                  let kind = switch ReactEvent.Form.target(event)["value"] {
                  | "query" => Some(#query)
                  | "mutation" => Some(#mutation)
                  | "subscription" => Some(#subscription)
                  | "compute" => Some(#compute)
                  | _ => None
                  }

                  kind->Belt.Option.forEach(kind => onCreate(kind))
                }}>
                <option value="+"> {"+"->React.string} </option>
                <option value="query"> {"+ New Query Block"->React.string} </option>
                <option value="mutation"> {"+ New Mutation Block"->React.string} </option>
                <option value="subscription"> {"+ New Subscription Block"->React.string} </option>
                <option value="compute"> {"+ New Compute Block"->React.string} </option>
              </Comps.Select>

              // <button className="p-2 hover:bg-blue-200 rounded-md" >
              //   {"+"->React.string}
              // </button>
            </div>
          </div>
          <div className="py-3 text-sm h-full overflow-y-scroll">
            {switch state.search {
            | None => blocks
            | Some(_) => state.results
            }
            ->Belt.Array.copy
            ->Js.Array2.sortInPlaceWith((a, b) =>
              String.compare(
                a.title->Js.String2.toLocaleLowerCase,
                b.title->Js.String2.toLocaleLowerCase,
              )
            )
            ->Belt.Array.map((block: Card.block) => {
              <div
                key={block.title}
                className="block-search-item flex justify-start cursor-grab text-gray-700 items-center hover:text-blue-400 rounded-md px-2 my-2"
                onDoubleClick={_ => onAdd(block)}
                onClick={_ => onInspect(block)}>
                <div
                  style={
                    let color = switch block.kind {
                    | Query => "1BBE83"
                    | Mutation => "B20D5D"
                    | Subscription => "F2C94C"
                    | Fragment => "F2C94C"
                    | Compute => Comps.colors["gray-10"]
                    }

                    ReactDOMStyle.make(
                      ~background=j`radial-gradient(ellipse at center, #${color} 0%, #${color} 30%, transparent 30%)`,
                      ~width="10px",
                      ~height="10px",
                      ~backgroundRepeat="repeat-x",
                      (),
                    )
                  }
                />
                <div
                  style={ReactDOMStyle.make(~color="#F2F2F2", ())}
                  className="flex-grow font-medium px-2 py-2 truncate">
                  {block.title->string}
                </div>
                <div
                  style={ReactDOMStyle.make(~minWidth="40px", ())}
                  className="px-2 rounded-r-md py-2">
                  {block.services
                  ->Belt.Array.keepMap(service =>
                    service
                    ->Utils.serviceImageUrl
                    ->Belt.Option.map(((url, friendlyServiceName)) =>
                      <img
                        key={friendlyServiceName}
                        alt=friendlyServiceName
                        title=friendlyServiceName
                        style={ReactDOMStyle.make(
                          ~pointerEvents="none",
                          ~opacity="0.80",
                          ~border="2px",
                          ~borderStyle="solid",
                          ~borderColor=Comps.colors["gray-6"],
                          (),
                        )}
                        width="24px"
                        src=url
                        className="rounded-full"
                      />
                    )
                  )
                  ->array}
                </div>
              </div>
            })
            ->array}
          </div>
        </div>
      </div>
    </div>
  }
}

type diagramEdgeData = {
  id: string,
  source: string,
  target: string,
}

module InspectedContextProvider = {
  let context = React.createContext((None: option<Inspector.inspectable>))

  let provider = React.Context.provider(context)

  @react.component
  let make = (~value, ~children) => {
    React.createElement(provider, {"value": value, "children": children})
  }
}

module NodeLabel = {
  type state = {isOpen: bool}

  @react.component
  let make = (
    ~request: option<Chain.request>,
    ~block: Card.block,
    ~onEditBlock,
    ~onDragStart,
    ~schema as _,
    ~onPotentialVariableSourceConnect,
  ) => {
    let services =
      block.services
      ->Belt.Array.keepMap(service =>
        service
        ->Utils.serviceImageUrl
        ->Belt.Option.map(((url, friendlyServiceName)) =>
          <img
            key={friendlyServiceName}
            className="shadow-lg rounded-full"
            alt=friendlyServiceName
            title=friendlyServiceName
            style={ReactDOMStyle.make(~pointerEvents="none", ())}
            src=url
            width="16px"
            height="16px"
          />
        )
      )
      ->React.array

    open React
    let connectionDrag = useContext(ConnectionContext.context)

    let domRef = React.useRef(Js.Nullable.null)

    let className = switch connectionDrag {
    | ConnectionContext.StartedSource({sourceRequest})
    | Completed({sourceRequest}) if Some(sourceRequest) == request => "bg-green-700"
    | _ => ""
    }

    <div
      ref={ReactDOM.Ref.domRef(domRef)}
      className={"flex align-middle items-center min-w-max flex-col " ++ className}
      onMouseDown={event => {
        switch event->ReactEvent.Mouse.altKey {
        | false => ()
        | true =>
          event->ReactEvent.Mouse.preventDefault
          event->ReactEvent.Mouse.stopPropagation
          request->Belt.Option.forEach(request =>
            onDragStart(~event, ~request, ~domRef=domRef.current)
          )
        }
      }}
      onMouseUp={event => {
        request->Belt.Option.forEach(sourceRequest => {
          switch connectionDrag {
          | StartedTarget(dragInfo) =>
            let clientX = event->ReactEvent.Mouse.clientX
            let clientY = event->ReactEvent.Mouse.clientY
            let mouseClientPosition = (clientX, clientY)

            let connectionDrag = ConnectionContext.Completed({
              sourceRequest: sourceRequest,
              sourceDom: dragInfo.sourceDom,
              windowPosition: mouseClientPosition,
              target: dragInfo.target,
            })
            onPotentialVariableSourceConnect(~connectionDrag)
          | _ => ()
          }
        })
      }}
      onContextMenu={event => {
        ()
      }}>
      // <ReactFlow.Handle
      //   type_=#target
      //   position=#top
      //   className="rounded-lg border-2"
      //   style={ReactDOMStyle.make(
      //     ~backgroundColor="black",
      //     ~borderWidth="2px",
      //     ~padding="10px",
      //     ~background="radial-gradient(ellipse at center, rgb(78,160,23) 0%, rgb(78,160,23) 30%, transparent 30%)",
      //     ~borderColor="rgb(78,160,23)",
      //     ~top="-24px",
      //     (),
      //   )}
      // />
      <div className="flex flex-row items-center justify-end font-mono">
        <div className="m-2"> {services} </div>
        <div className="flex-1 inline-block "> {block.title->string} </div>
        <div
          className="p-2 hover:shadow-lg rounded-md hover:border-gray-300 cursor-pointer m-0"
          onClick={event => {
            ReactEvent.Mouse.preventDefault(event)
            onEditBlock(block)
          }}>
          <Icons.GraphQL color="rgb(181,181,181)" width="16px" height="16px" />
        </div>
      </div>
      // <ReactFlow.Handle
      //   type_=#source
      //   position=#bottom
      //   className="rounded-lg border-2"
      //   style={ReactDOMStyle.make(
      //     ~backgroundColor="black",
      //     ~borderWidth="2px",
      //     ~padding="10px",
      //     ~background="radial-gradient(ellipse at center, rgb(78,160,23) 0%, rgb(78,160,23) 30%, transparent 30%)",
      //     ~borderColor="rgb(78,160,23)",
      //     ~marginTop="20px",
      //     ~bottom="-24px",
      //     (),
      //   )}
      // />
    </div>
  }
}

module OperationNodeComponent = {
  @react.component
  let make = (~data) => {
    <div className="rounded-sm node-label p-2"> <div> {data["label"]} </div> </div>
  }
}

type graphNode = {
  request: Chain.request,
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

let diagramFromChain = (
  chain: Chain.t,
  ~onEditBlock,
  ~onDragStart,
  ~schema,
  ~onPotentialVariableSourceConnect,
  (),
): diagram => {
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

  let fragmentNodes =
    chain.blocks
    ->Belt.Array.keep(block => {
      switch block.kind {
      | Fragment => true
      | _ => false
      }
    })
    ->Belt.SortArray.stableSortBy((a, b) =>
      Js.String2.localeCompare(a.title, b.title)->Belt.Float.toInt
    )
    ->Belt.Array.mapWithIndex((idx, block) => {
      let nodeTitleWidth = block.title->Js.String2.length->float_of_int *. 7.2
      let nodePadding = 105.

      // Right side should be at 153 to right-align with fragment label
      let x = 160. -. nodeTitleWidth -. nodePadding

      let node = ReactFlow.Node.t(
        ~typ=#fragment,
        ~id=block.id->Uuid.toString,
        ~data={
          label: <NodeLabel
            onEditBlock request=None block schema onDragStart onPotentialVariableSourceConnect
          />,
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

  let operationBlocks = chain.blocks->Belt.Array.keep(block => {
    switch block.kind {
    | Fragment => false
    | _ => true
    }
  })

  let levels = Js.Dict.empty()
  let graphLevels = Js.Dict.empty()

  let rec findReqLevel = (request: Chain.request) => {
    let level = levels->Js.Dict.get(request.id)

    switch level {
    | Some(level) => level
    | None =>
      let highestDependency = request.dependencyRequestIds->Belt.Array.reduce(-2, (
        level,
        nextId,
      ) => {
        chain.requests
        ->Belt.Array.getBy(depReq => {
          depReq.id == nextId
        })
        ->Belt.Option.flatMap(depReq => {
          switch depReq.id == request.id {
          | false =>
            let dependencyLevel = findReqLevel(depReq)
            levels->Js.Dict.set(nextId, dependencyLevel)

            Some(Js.Math.max_int(level, dependencyLevel))
          | true => None
          }
        })
        ->Belt.Option.getWithDefault(level)
      })

      let requestLevel = highestDependency + 1

      let nodeTitleWidth = request.operation.title->Js.String2.length->float_of_int *. 7.2
      let nodePadding = 105.
      let requestWidth = nodeTitleWidth +. nodePadding +. nodeGap

      let graphLevel =
        graphLevels
        ->Js.Dict.get(requestLevel->string_of_int)
        ->Belt.Option.getWithDefault(emptyGraphLevel(requestLevel))

      let graphNode = {
        request: request,
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

  operationBlocks->Belt.Array.forEach(block => {
    let req = chain.requests->Belt.Array.getBy(req => {
      req.id == block.title
    })

    req->Belt.Option.forEach(req => {
      let level = findReqLevel(req)
      levels->Js.Dict.set(req.id, level)
    })
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
        let req = node.request
        let block = req.operation

        let variables = block->Card.getFirstVariables
        let hasVariables = variables->Belt.Array.length > 0

        let typ = switch hasVariables {
        | true => #default
        | false => #input
        }

        let level = node.level

        let halfWidth = totalWidth /. 2.

        let furthestLeft = halfWidth -. graphLevel.width /. 2.

        let x = 250. +. furthestLeft +. node.left

        let node = ReactFlow.Node.t(
          ~typ,
          ~id=block.id->Uuid.toString,
          ~data={
            label: <NodeLabel
              onEditBlock
              request=Some(node.request)
              block
              schema
              onDragStart
              onPotentialVariableSourceConnect
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

  let argDepEdges: array<diagramEdgeData> =
    chain.blocks
    ->Belt.Array.map(block => {
      let req = chain.requests->Belt.Array.getBy(req => {
        req.id == block.title
      })

      let target = block.id->Uuid.toString

      req
      ->Belt.Option.map(req => {
        let ast = GraphQLJs.parse(req.operation.body)

        let variables =
          (
            ast.definitions->Belt.Array.get(0)->Belt.Option.getExn
          ).variableDefinitions->Belt.Option.getWithDefault([])

        variables->Belt.Array.map(varDef => {
          let varName = varDef.variable.name.value
          let argDep =
            req.variableDependencies
            ->Belt.Array.getBy(argDep => {
              switch (argDep.name == varName, argDep.dependency) {
              | (true, ArgumentDependency(_)) => true
              | _ => false
              }
            })
            ->Belt.Option.flatMap(argDep => {
              switch argDep.dependency {
              | ArgumentDependency(dep) => Some(dep)
              | _ => None
              }
            })

          switch argDep {
          | None => []
          | Some(argDep) =>
            let edges = argDep.fromRequestIds->Belt.Array.keepMap(requestId => {
              let requestDependency = chain.requests->Belt.Array.getBy(existingRequest => {
                existingRequest.id == requestId
              })

              requestDependency->Belt.Option.map(requestDependency => {
                let source = requestDependency.operation.id->Uuid.toString
                let id = j`${source}-${target}`

                let edge = {id: id, source: source, target: target}

                (id, edge)
              })
            })

            let distinct = Belt.Set.String.empty

            let (_, edges) = edges->Belt.Array.reduce((distinct, []), (
              (distinct, edges),
              (id, edge),
            ) => {
              switch distinct->Belt.Set.String.has(id) {
              | false => (distinct->Belt.Set.String.add(id), edges->Belt.Array.concat([edge]))
              | true => (distinct, edges)
              }
            })

            edges
          }
        })
      })
      ->Belt.Option.getWithDefault([])
      ->Belt.Array.concatMany
    })
    ->Belt.Array.concatMany

  let reqEdge =
    chain.requests
    ->Belt.Array.map(request => {
      let target = request.operation.id->Uuid.toString

      let r = request.dependencyRequestIds->Belt.Array.keepMap(requestId => {
        let reifiedRequest = chain.requests->Belt.Array.getBy(req => {
          req.id == requestId
        })

        reifiedRequest->Belt.Option.map(requestDependency => {
          let source = requestDependency.operation.id->Uuid.toString
          let id = j`${source}-${target}`

          let edge = {id: id, source: source, target: target}
          edge
        })
      })
      r
    })
    ->Belt.Array.concatMany

  let distinct = Belt.Set.String.empty

  let (_, distinctEdges) = Belt.Array.concat(argDepEdges, reqEdge)->Belt.Array.reduce(
    (distinct, []),
    ((distinct, edges), edge) => {
      switch distinct->Belt.Set.String.has(edge.id) {
      | false => (distinct->Belt.Set.String.add(edge.id), edges->Belt.Array.concat([edge]))
      | true => (distinct, edges)
      }
    },
  )

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

  // let layoutedElements = Dagre.getLayoutedElements(~nodes, ~edges, ~nodeWidth=10., ~nodeHeight=50.)

  let elements = Belt.Array.concatMany([nodes, edges->Obj.magic, fragmentLabelNode])->Obj.magic

  {nodes: nodes, edges: edges, elements: elements}
}

let backgroundStyle = ReactDOMStyle.make(
  ~height="100%",
  ~backgroundColor="rgb(60, 60, 60)",
  ~backgroundSize="50px 50px",
  ~display="flex",
  ~backgroundImage="linear-gradient(0deg, transparent 24%, rgba(255, 255, 255, 0.05) 25%, rgba(255, 255, 255, 0.05) 26%, transparent 27%, transparent 74%, rgba(255, 255, 255, 0.05) 75%, rgba(255, 255, 255, 0.05) 76%, transparent 77%, transparent), linear-gradient(90deg, transparent 24%, rgba(255, 255, 255, 0.05) 25%, rgba(255, 255, 255, 0.05) 26%, transparent 27%, transparent 74%, rgba(255, 255, 255, 0.05) 75%, rgba(255, 255, 255, 0.05) 76%, transparent 77%, transparent)",
  ~borderRadius="0px",
  (),
)

type requestScriptTypeScriptSignature = {
  functionFromScriptInputType: string,
  functionFromScriptOutputType: string,
  functionFromScriptName: string,
}

let requestScriptTypeScriptSignature = (
  request: Chain.request,
  schema: GraphQLJs.schema,
  chain: Chain.t,
): requestScriptTypeScriptSignature => {
  let chainFragmentsDoc =
    chain.blocks
    ->Belt.Array.keepMap(block => {
      switch block.kind {
      | Fragment => Some(block.body)
      | _ => None
      }
    })
    ->Js.Array2.joinWith("\n\n")
    ->Js.String2.concat("\n\nfragment INTERNAL_UNUSED on Query { __typename }")

  let chainFragmentDefinitions = GraphQLJs.Mock.gatherFragmentDefinitions({
    "operationDoc": chainFragmentsDoc,
  })

  let upstreamArgDepRequestIds =
    request.variableDependencies
    ->Belt.Array.keepMap(varDep => {
      switch varDep.dependency {
      | ArgumentDependency(argDep) => Some(argDep.fromRequestIds)
      | _ => None
      }
    })
    ->Belt.Array.concatMany

  let upstreamRequestDependencyIds = request.dependencyRequestIds

  let upstreamRequestIds =
    Belt.Array.concat(upstreamArgDepRequestIds, upstreamRequestDependencyIds)->Utils.distinctStrings

  let inputType = {
    let dependencyRequests = chain.requests->Belt.Array.keepMap(request => {
      switch upstreamRequestIds->Js.Array2.indexOf(request.id) {
      | -1 => None
      | _ =>
        let ast = request.operation.body->GraphQLJs.parse
        let dependencyRequest = ast.definitions->Belt.Array.get(0)

        dependencyRequest->Belt.Option.map(dependencyRequest => {
          let tsSignature = GraphQLJs.Mock.typeScriptForOperation(
            schema,
            dependencyRequest,
            ~fragmentDefinitions=chainFragmentDefinitions,
          )
          (request.id, tsSignature)
        })
      }
    })

    dependencyRequests
    ->Belt.Array.reduce(Js.Dict.empty(), (acc, (name, tsType)) => {
      acc->Js.Dict.set(name, tsType)
      acc
    })
    ->ignore

    let fields =
      dependencyRequests
      ->Belt.Array.map(((name, tsType)) => {
        j`"${name}": ${tsType}`
      })
      ->Js.Array2.joinWith(", ")

    j`{${fields}}`
  }

  let inputType = inputType->Obj.magic

  let inputType = switch inputType {
  | ""
  | "{}" => "EmptyObject"
  | other => other
  }

  let operationDef = (request.operation.body->GraphQLJs.parse).definitions->Belt.Array.get(0)

  let outputTypeForVariables =
    operationDef
    ->Belt.Option.map(operationDef => {
      let signature =
        request.variableDependencies
        ->Belt.Array.keepMap(varDep => {
          switch varDep.dependency {
          | ArgumentDependency(argDep) => Some(argDep.name)
          | _ => None
          }
        })
        ->GraphQLJs.Mock.typeScriptSignatureForOperationVariables(schema, operationDef)

      switch signature {
      | "{}" => "EmptyObject"
      | other => other
      }
    })
    ->Belt.Option.getWithDefault("// No operation definition for request")

  let names = request->Chain.requestScriptNames

  let outputType = j`export type ${names.returnTypeName} = ${outputTypeForVariables}`
  let inputType = j`export type ${names.inputTypeName} = ${inputType}`

  {
    functionFromScriptInputType: inputType,
    functionFromScriptOutputType: outputType,
    functionFromScriptName: names.functionName,
  }
}

type monacoTypelib = {
  importLine: string,
  dDotTs: string,
}

let monacoTypelibForChain = (schema, chain: Chain.t) => {
  let types =
    chain.requests->Belt.Array.map(request =>
      request->requestScriptTypeScriptSignature(schema, chain)
    )

  let dDotTsDefs =
    types
    ->Belt.Array.map(typeSigs => {
      j`${typeSigs.functionFromScriptInputType}
${typeSigs.functionFromScriptOutputType}
`
    })
    ->Js.Array2.joinWith("\n\n")

  let dDotTs = j`type EmptyObject = Record<any, never>

${dDotTsDefs}`

  let names = chain.requests->Belt.Array.map(Chain.requestScriptNames)

  let importedNames =
    names
    ->Belt.Array.map(({inputTypeName, returnTypeName}) => {
      [inputTypeName, returnTypeName]
    })
    ->Belt.Array.concatMany
    ->Js.Array2.joinWith(", ")

  let importLine = j`import { ${importedNames} } from 'oneGraphStudio';`

  {dDotTs: dDotTs, importLine: importLine}
}

module Script = {
  @react.component
  let make = (
    ~schema,
    ~chain: Chain.t,
    ~functionName as _=?,
    ~onChange,
    ~className=?,
    ~onMount,
    ~onPotentialScriptSourceConnect,
  ) => {
    let (localContent, setLocalContent) = React.useState(() => chain.script)
    let content = chain.script

    let editor = React.useRef(None)
    let monaco = React.useRef(None)

    let {dDotTs: types} = monacoTypelibForChain(schema, chain)

    let connectionDrag = React.useContext(ConnectionContext.context)
    let connectionDragRef = React.useRef(connectionDrag)

    React.useEffect1(() => {
      connectionDragRef.current = connectionDrag

      None
    }, [connectionDrag->ConnectionContext.toSimpleString])

    React.useEffect1(() => {
      content == localContent
        ? ()
        : editor.current->Belt.Option.forEach(editor => {
            let position = editor->BsReactMonaco.getPosition

            let model = editor->BsReactMonaco.getModel("file:///main.tsx")
            let fullRange = model->BsReactMonaco.Model.getFullModelRange
            let edit = BsReactMonaco.editOperation(~range=fullRange, ~text=content, ())
            editor->BsReactMonaco.executeEdits(
              Js.Nullable.return("externalContentChange"),
              ~edits=[edit],
            )
            editor->BsReactMonaco.setPosition(position)
          })

      None
    }, [content])

    React.useEffect1(() => {
      monaco.current->Belt.Option.forEach(monaco => {
        let {dDotTs: newTypes, importLine} = monacoTypelibForChain(schema, chain)
        let () = BsReactMonaco.TypeScript.addLib(. monaco, newTypes, content)

        let newImports = importLine

        let hasImport =
          chain.script
          ->Js.String2.match_(Js.Re.fromString("import[\s\S.]+from[\s\S]+'oneGraphStudio';"))
          ->Belt.Option.isSome

        let newScript = hasImport
          ? chain.script->Js.String2.replaceByRe(
              Js.Re.fromString("import[\s\S.]+from[\s\S]+'oneGraphStudio';"),
              newImports,
            )
          : `${newImports}

${chain.script}`

        onChange(newScript)
      })

      None
    }, [types])

    let filename = "file:///main.tsx"

    <div
      style={ReactDOMStyle.make(
        ~height="calc(100vh - 40px - 384px - 56px)",
        /* TODO: Figure this out: if overflowY is hidden, the page won't scroll, but the tooltips are cut off */
        // ~overflowY="hidden",
        (),
      )}>
      <BsReactMonaco.Editor
        ?className
        theme="vs-dark"
        language="typescript"
        defaultValue={content}
        options={
          "minimap": {"enabled": false},
        }
        height="100%"
        path=filename
        onChange={(newScript, _) => {
          setLocalContent(_ => newScript)
          onChange(newScript)
        }}
        onMount={(editorHandle, monacoInstance) => {
          Debug.assignToWindowForDeveloperDebug(~name="myEditor", editorHandle)
          Debug.assignToWindowForDeveloperDebug(~name="myMonaco", monacoInstance)
          Debug.assignToWindowForDeveloperDebug(~name="ts", TypeScript.ts)

          let _disposable = editorHandle->BsReactMonaco.onMouseUp(mouseEvent => {
            Debug.assignToWindowForDeveloperDebug(~name="editorMouseEvent", mouseEvent)

            open ConnectionContext

            switch connectionDragRef.current {
            | Empty
            | Completed(_)
            | CompletedWithTypeMismatch(_)
            | StartedTarget(_) => ()
            | StartedSource({sourceRequest, sourceDom}) =>
              let position = mouseEvent["target"]["position"]
              let lineNumber = position["lineNumber"]
              let column = position["column"]

              let event = mouseEvent["event"]
              let mousePositionX = event["posx"]
              let mousePositionY = event["posy"]
              let mousePosition = (mousePositionX, mousePositionY)

              onPotentialScriptSourceConnect(
                ~sourceRequest,
                ~sourceDom,
                ~scriptPosition={lineNumber: lineNumber, column: column},
                ~mousePosition,
              )
            }
          })

          let () = BsReactMonaco.TypeScript.addLib(. monacoInstance, types, content)
          let () = BsReactMonaco.registerPrettier(monacoInstance)
          let modelOptions = BsReactMonaco.Model.modelOptions(~tabSize=2, ())

          editor.current = Some(editorHandle)
          monaco.current = Some(monacoInstance)

          editorHandle
          ->BsReactMonaco.getModel(filename)
          ->BsReactMonaco.Model.updateOptions(modelOptions)

          onMount(~editor=editorHandle, ~monaco=monacoInstance)
        }}
      />
    </div>
  }
}

module Modal = {
  @react.component
  let make = (~children) => {
    <div
      style={ReactDOMStyle.make(~zIndex="9999", ())}
      className="flex items-center justify-center absolute left-0 bottom-0 w-full h-full bg-gray-800 bg-opacity-60">
      <div
        className="rounded-lg w-4/5 h-4/5"
        style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-8"], ())}>
        <div className="flex flex-col p-1 h-full">
          <div className="flex h-full"> {children} </div>
        </div>
      </div>
    </div>
  }
}

module ConnectorLine = {
  type state = {mousePosition: (int, int)}

  @send external getBoundingClientRect: Dom.element => Dom.domRect = "getBoundingClientRect"

  @react.component
  let make = (~source, ~onDragEnd, ~invert) => {
    open React

    let (state, setState) = useState(() => {
      let rect = Obj.magic(getBoundingClientRect(source))

      {
        mousePosition: (rect["x"] + rect["width"] / 2, rect["y"] + rect["height"] / 2),
      }
    })

    let onMouseMove = event => {
      let x = event["pageX"]
      let y = event["pageY"]
      setState(_oldState => {mousePosition: (x, y)})
    }

    let onMouseUp = event => {
      Debug.assignToWindowForDeveloperDebug(~name="mouseupevent", event)
      onDragEnd()
    }

    useEffect0(() => {
      %external(window)->Belt.Option.forEach(window => {
        window["document"]["addEventListener"]("mousemove", onMouseMove)
        window["document"]["addEventListener"]("mouseup", onMouseUp)
      })

      let cleanup = %external(window)->Belt.Option.map(window => {
        () => {
          window["document"]["removeEventListener"]("mousemove", onMouseMove)
          window["document"]["removeEventListener"]("mouseup", onMouseUp)
        }
      })

      cleanup
    })
    let (mouseX, mouseY) = state.mousePosition
    let (anchorX, anchorY) = {
      let rect = Obj.magic(getBoundingClientRect(source))

      let scrollY = Utils.windowScrollY()->Belt.Option.getWithDefault(0)

      (rect["x"] + rect["width"] / 2, rect["y"] + rect["height"] / 2 + scrollY)
    }
    let (startX, startY, endX, endY) = switch invert {
    | false => (anchorX, anchorY, mouseX, mouseY)
    | true => (mouseX, mouseY, anchorX, anchorY)
    }

    <div
      className="absolute w-full h-full pointer-events-none"
      style={ReactDOMRe.Style.make(~top="0px", ~left="0px", ~zIndex="9999", ~cursor="none", ())}
      onMouseMove={event => {
        let x = event->ReactEvent.Mouse.clientX
        let y = event->ReactEvent.Mouse.clientY
        setState(_oldState => {mousePosition: (x, y)})
      }}>
      <svg
        className="relative w-full h-full pointer-events-none"
        xmlns="http://www.w3.org/2000/svg"
        style={ReactDOMRe.Style.make(~top="0px", ~left="0px", ~zIndex="9999", ~cursor="none", ())}>
        <filter id="blurMe"> <feGaussianBlur in_="SourceGraphic" stdDeviation="5" /> </filter>
        <marker
          id="connectMarker" markerHeight="4" markerWidth="2" orient="auto" refX="0.1" refY="2">
          <path fill="green" d="M0 0v4l2-2z" />
        </marker>
        <line
          style={ReactDOMRe.Style.make(~cursor="none", ())}
          stroke="green"
          strokeWidth="3"
          markerEnd="url(#connectMarker)"
          x1={startX->string_of_int}
          y1={startY->string_of_int}
          x2={endX->string_of_int}
          y2={endY->string_of_int}
        />
        <line
          style={ReactDOMRe.Style.make(~cursor="none", ())}
          stroke="#22ff22"
          strokeWidth="4"
          className="moving-path"
          markerEnd="url(#connectMarker)"
          filter="url(#blurMe)"
          strokeDasharray={"50"}
          x1={startX->string_of_int}
          y1={startY->string_of_int}
          x2={endX->string_of_int}
          y2={endY->string_of_int}
        />
      </svg>
    </div>
  }
}

module Diagram = {
  @react.component
  let make = (
    ~setState,
    ~diagram,
    ~chain: Chain.t,
    ~removeEdge,
    ~removeRequest,
    ~diagramFromChain,
  ) => {
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
        setState(oldState => {
          let newChain = elements->Belt.Array.reduce(oldState.chain, (accChain, element) => {
            let typ = switch (
              Obj.magic(element)["source"]->Js.Undefined.toOption,
              Obj.magic(element)["target"]->Js.Undefined.toOption,
            ) {
            | (Some(source), Some(target)) => #edge(source, target)
            | _ => #node(Obj.magic(element)["id"])
            }

            let newChain = switch typ {
            | #edge(source, targetRequestId) =>
              let newChain = removeEdge(accChain, ~dependencyId=source, ~targetRequestId)
              newChain
            | #node(source) =>
              let targetRequest = accChain.requests->Belt.Array.getBy(request => {
                request.operation.id == source
              })

              let newChain =
                targetRequest
                ->Belt.Option.map(targetRequest => removeRequest(accChain, targetRequest))
                ->Belt.Option.getWithDefault(accChain)
              newChain
            }

            newChain
          })

          let diagram = diagramFromChain(newChain)

          {...oldState, chain: newChain, diagram: diagram}
        })
      }}
      elements=diagram.elements
      zoomOnScroll=false
      onPaneClick={_ => {
        setState(oldState => {...oldState, inspected: Nothing(oldState.chain)})
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

        let sourceRequest = chain.requests->Belt.Array.getBy(request => {
          request.operation.id->Uuid.toString == source
        })

        let targetRequest = chain.requests->Belt.Array.getBy(request => {
          request.operation.id->Uuid.toString == target
        })

        switch (sourceRequest, targetRequest) {
        | (None, _)
        | (_, None) =>
          Js.Console.warn("Couldn't find source or target request to connect")
        | (Some(source), Some(target)) =>
          setState(oldState => {
            let newRequests = oldState.chain.requests->Belt.Array.map(request => {
              switch target.id == request.id {
              | false => request
              | true =>
                let varDeps = request.variableDependencies->Belt.Array.map(varDep => {
                  let dependency = switch varDep.dependency {
                  | ArgumentDependency(argDep) =>
                    let newArgDep = {
                      ...argDep,
                      fromRequestIds: argDep.fromRequestIds
                      ->Belt.Array.concat([source.id])
                      ->Utils.distinctStrings,
                    }

                    Chain.ArgumentDependency(newArgDep)
                  | other => other
                  }
                  let varDep = {...varDep, dependency: dependency}

                  varDep
                })

                {
                  ...request,
                  variableDependencies: varDeps,
                  dependencyRequestIds: request.dependencyRequestIds
                  ->Belt.Array.concat([source.id])
                  ->Utils.distinctStrings,
                }
              }
            })

            let sortedRequests = Chain.toposortRequests(newRequests)

            switch sortedRequests {
            | Error(#circularDependencyDetected) => oldState
            | Ok(sortedRequests) =>
              let newChain = {...oldState.chain, requests: sortedRequests}

              let diagram = diagramFromChain(newChain)

              {...oldState, chain: newChain, diagram: diagram}
            }
          })
        }
      }}
      onElementClick={(_, node) => {
        let id = node->ReactFlow.Node.idGet

        let request: option<Inspector.inspectable> =
          chain.requests
          ->Belt.Array.getBy(req => {
            req.operation.id->Uuid.toString == id
          })
          ->Belt.Option.map(req => {
            let inspected: Inspector.inspectable = Request({
              chain: chain,
              request: req,
            })
            inspected
          })

        let inspected = switch request {
        | Some(inspected) => Some(inspected)
        | None =>
          let block = chain.blocks->Belt.Array.getBy(block => block.id->Uuid.toString == id)
          block->Belt.Option.map((block): Inspector.inspectable => Block(block))
        }

        inspected->Belt.Option.forEach(inspected => {
          setState(oldState => {...oldState, inspected: inspected})
        })
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
}

module Main = {
  @react.component
  let make = (
    ~schema,
    ~initialChain: Chain.t,
    ~config: Config.Studio.t,
    ~oneGraphAuth: OneGraphAuth.t,
  ) => {
    let (_missingAuthServices, setMissingAuthServices) = React.useState(() => [])

    let (state, setState) = React.useState(() => {
      let scriptFunctions = try {
        let parsedScript = Acorn.parse(
          initialChain.script,
          Acorn.parseOptions(~ecmaVersion=2020, ~sourceType=#"module", ()),
        )

        let functionNames = Acorn.collectExportedFunctionNames(parsedScript)
        functionNames
      } catch {
      | _ => []
      }

      let inspected: Inspector.inspectable = Nothing(initialChain)
      // Request({
      //   chain: initialChain,
      //   request: initialChain.requests->Belt.Array.get(1)->Belt.Option.getExn,
      // })
      // Block(Card.blocks[0])

      {
        diagram: None,
        chain: initialChain,
        card: Some(Card.watchTwitterFollower),
        schema: schema,
        chainResult: None,
        scriptFunctions: scriptFunctions,
        inspected: inspected,
        blockEdit: Nothing,
        blocks: Card.blocks,
        compiledChain: compileChain(schema, initialChain),
        scriptEditor: {
          isOpen: true,
          monaco: None,
          editor: None,
        },
        chainExecutionResults: None,
        savedChainId: None,
        requestValueCache: Js.Dict.empty(),
        debugUIItems: [],
        connectionDrag: Empty,
      }
    })

    React.useEffect0(() => {
      let diagramFromChain = chain =>
        diagramFromChain(
          chain,
          ~schema,
          ~onEditBlock=block => {
            setState(oldState => {...oldState, blockEdit: Edit(block)})
          },
          ~onDragStart=(
            ~event as _: ReactEvent.Mouse.t,
            ~request: Chain.request,
            ~domRef: Js.Nullable.t<Dom.element>,
          ) => {
            let connectionDrag =
              domRef
              ->Js.Nullable.toOption
              ->Belt.Option.mapWithDefault(ConnectionContext.Empty, domRef => StartedSource({
                sourceRequest: request,
                sourceDom: domRef,
              }))

            setState(oldState => {...oldState, connectionDrag: connectionDrag})
          },
          ~onPotentialVariableSourceConnect=(
            ~connectionDrag as _: ConnectionContext.connectionDrag,
          ) => (),
          (),
        )

      let diagram = state.chain->diagramFromChain

      setState(oldState => {...oldState, diagram: Some(diagram)})
      None
    })

    let selectRequestFunctionScript = (request: Chain.request) => {
      let names = request->Chain.requestScriptNames
      let functionName = names.functionName

      let source = state.chain.script

      let sourceFile = TypeScript.createSourceFile(~name="main.ts", ~source, ~target=99, true)
      let pos = TypeScript.findFnPos(sourceFile, functionName)

      pos->Belt.Option.forEach(({start, end}) => {
        state.scriptEditor.editor->Belt.Option.forEach(editor => {
          let model = editor->BsReactMonaco.getModel("file://main.tsx")

          let start = model->BsReactMonaco.getPositionAt(start)
          let end = model->BsReactMonaco.getPositionAt(end)

          editor->BsReactMonaco.revealLineInCenter(start.lineNumber, ~scroll=1)
          editor->BsReactMonaco.setSelection({
            startLineNumber: start.lineNumber,
            startColumn: start.column,
            endLineNumber: end.lineNumber,
            endColumn: end.column,
          })
        })
      })
    }

    let onPotentialVariableSourceConnect = (~connectionDrag: ConnectionContext.connectionDrag) => {
      setState(oldState => {
        {
          ...oldState,
          connectionDrag: connectionDrag,
        }
      })
    }

    let diagramFromChain = chain => Some(
      diagramFromChain(
        chain,
        ~schema,
        ~onEditBlock=block => {
          setState(oldState => {...oldState, blockEdit: Edit(block)})
        },
        ~onDragStart=(
          ~event as _: ReactEvent.Mouse.t,
          ~request: Chain.request,
          ~domRef: Js.Nullable.t<Dom.element>,
        ) => {
          let connectionDrag =
            domRef
            ->Js.Nullable.toOption
            ->Belt.Option.mapWithDefault(ConnectionContext.Empty, domRef => StartedSource({
              sourceRequest: request,
              sourceDom: domRef,
            }))
          setState(oldState => {...oldState, connectionDrag: connectionDrag})
        },
        ~onPotentialVariableSourceConnect,
        (),
      ),
    )

    let {fitView} = ReactFlow.useZoomPanHelper()

    let onRequestInspected = request => {
      let inspected: Inspector.inspectable = Request({
        chain: state.chain,
        request: request,
      })

      setState(oldState => {...oldState, inspected: inspected})
    }

    React.useEffect1(() => {
      try {
        let parsedScript = Acorn.parse(
          state.chain.script,
          Acorn.parseOptions(~ecmaVersion=2020, ~sourceType=#"module", ()),
        )

        let functionNames = Acorn.collectExportedFunctionNames(parsedScript)
        setState(oldState => {...oldState, scriptFunctions: functionNames})
      } catch {
      | _ => ()
      }

      None
    }, [state.chain.script])

    React.useEffect1(() => {
      setState(oldState => {...oldState, chain: {...oldState.chain, name: initialChain.name}})
      None
    }, [initialChain.name])

    React.useEffect1(() => {
      state.chain.requests->Belt.Array.length > 3
        ? fitView({
            padding: 0.2,
            includeHiddenNodes: false,
          })
        : ()
      None
    }, [state.chain.requests->Belt.Array.length])

    let onExecuteRequest = (~request: Chain.request, ~variables) => {
      let ast = request.operation.body->GraphQLJs.parse
      let operationName = ast.definitions[0].name.value

      // TODO: Only send referenced fragments
      let chainFragments =
        state.chain.blocks
        ->Belt.Array.keepMap(block => {
          switch block.kind {
          | Fragment => Some(block.body)
          | _ => None
          }
        })
        ->Js.Array2.joinWith("\n\n")

      let fullDoc = j`${request.operation.body}

${chainFragments}`->Js.String2.trim

      let promise = OneGraphRe.fetchOneGraph(
        oneGraphAuth,
        fullDoc,
        Some(operationName),
        Some(variables->Obj.magic),
      )

      promise->Js.Promise.then_(result => {
        setState(oldState => {
          oldState.requestValueCache->Js.Dict.set(request.id, result->Obj.magic)
          let newOne = oldState.requestValueCache->Js.Dict.entries->Js.Dict.fromArray

          {
            ...oldState,
            requestValueCache: newOne,
          }
        })->Js.Promise.resolve
      }, _)->ignore
    }

    let addBlock = (superBlock: Card.block) => {
      let ast = superBlock.body->GraphQLJs.parse

      let blocks = ast.definitions->Belt.Array.map(definition => {
        let services =
          definition
          ->Obj.magic
          ->GraphQLUtils.gatherAllReferencedServices(~schema)
          ->Belt.Array.map(service => service.slug)

        let blank = makeBlankBlock(#query)

        let block = {
          ...blank,
          id: Uuid.v4(),
          title: definition.name.value,
          services: services,
          body: GraphQLJs.printAst(definition->Obj.magic),
          kind: switch definition.operation->Obj.magic {
          | None => Fragment
          | Some(#query) => Query
          | Some(#mutation) => Mutation
          | Some(#subscription) => Subscription
          },
        }

        block
      })

      let inspectedReq = ref(None)

      let newChain = blocks->Belt.Array.reduce(state.chain, (newChain, block) => {
        switch block.kind {
        | Fragment => {...newChain, blocks: newChain.blocks->Belt.Array.concat([block])}
        | _ =>
          let operationDoc = block.body->GraphQLJs.parse
          let definition = operationDoc.definitions[0]
          let variableNames = definition->GraphQLUtils.getOperationVariables

          let variableDependencies = variableNames->Belt.Array.map(((
            variableName,
            _variableType,
          )) => {
            let argDep: Chain.argumentDependency = {
              fromRequestIds: [],
              maxRecur: None,
              ifMissing: #SKIP,
              ifList: #FIRST,
              functionFromScript: "",
              name: variableName,
            }

            let _varDep: Chain.variableDependency = {
              name: variableName,
              dependency: ArgumentDependency(argDep),
            }

            let varDep: Chain.variableDependency = {
              name: variableName,
              dependency: Direct({
                name: variableName,
                value: Variable(variableName),
              }),
            }

            varDep
          })

          let newReq: Chain.request = {
            id: block.title,
            operation: block,
            variableDependencies: variableDependencies,
            dependencyRequestIds: [],
          }

          inspectedReq := Some(newReq)

          let names = newReq->Chain.requestScriptNames

          let nameExistsInScript =
            newChain.script
            ->Js.String2.match_(Js.Re.fromString(j`export function ${names.functionName}`))
            ->Belt.Option.isSome

          let newScript: string = nameExistsInScript
            ? newChain.script
            : newChain.script ++
              j`

export function ${names.functionName} (payload : ${names.inputTypeName}) : ${names.returnTypeName} {
  return {}
}`
          let newChain: Chain.t = {
            name: newChain.name,
            scriptDependencies: newChain.scriptDependencies,
            blocks: newChain.blocks->Belt.Array.concat([block]),
            requests: newChain.requests->Belt.Array.concat([newReq]),
            script: newScript,
          }

          let {dDotTs: _newTypes, importLine} = monacoTypelibForChain(schema, newChain)

          let newImports = importLine

          let hasImport =
            newScript
            ->Js.String2.match_(Js.Re.fromString("import[\s\S.]+from[\s\S]+'oneGraphStudio';"))
            ->Belt.Option.isSome

          let newScript = hasImport
            ? newScript->Js.String2.replaceByRe(
                Js.Re.fromString("import[\s\S.]+from[\s\S]+'oneGraphStudio';"),
                newImports,
              )
            : `${newImports}

${newScript}`

          let newChain: Chain.t = {
            ...newChain,
            script: newScript,
          }

          newChain
        }
      })

      let diagram = diagramFromChain(newChain)

      let inspected =
        inspectedReq.contents
        ->Belt.Option.map(request => Inspector.Request({request: request, chain: newChain}))
        ->Belt.Option.getWithDefault(state.inspected)

      setState(oldState => {
        ...oldState,
        chain: newChain,
        diagram: diagram,
        inspected: inspected,
      })
    }

    let removeRequest = (oldChain: Chain.t, targetRequest: Chain.request) => {
      let newRequests = oldChain.requests->Belt.Array.keepMap(request => {
        switch request.id == targetRequest.id {
        | true => None
        | false =>
          let varDeps = request.variableDependencies->Belt.Array.map(varDep => {
            let dependency = switch varDep.dependency {
            | ArgumentDependency(argDep) =>
              Chain.ArgumentDependency({
                ...argDep,
                fromRequestIds: argDep.fromRequestIds->Belt.Array.keep(id =>
                  id != targetRequest.id
                ),
              })
            | other => other
            }

            {...varDep, dependency: dependency}
          })

          let newRequest = {
            ...request,
            variableDependencies: varDeps,
            dependencyRequestIds: request.dependencyRequestIds->Belt.Array.keep(id =>
              id != targetRequest.id
            ),
          }

          Some(newRequest)
        }
      })

      let newChain = {
        ...oldChain,
        requests: newRequests,
        blocks: oldChain.blocks->Belt.Array.keep(oldBlock => oldBlock != targetRequest.operation),
      }

      newChain
    }

    let removeEdge = (oldChain: Chain.t, ~dependencyId, ~targetRequestId) => {
      let newRequests = oldChain.requests->Belt.Array.map(request => {
        switch request.id == targetRequestId {
        | false => request
        | true =>
          let varDeps = request.variableDependencies->Belt.Array.map(varDep => {
            let dependency = switch varDep.dependency {
            | ArgumentDependency(argDep) =>
              Chain.ArgumentDependency({
                ...argDep,
                fromRequestIds: argDep.fromRequestIds->Belt.Array.keep(id => id != dependencyId),
              })
            | other => other
            }

            {...varDep, dependency: dependency}
          })

          let newRequest = {
            ...request,
            variableDependencies: varDeps,
            dependencyRequestIds: request.dependencyRequestIds->Belt.Array.keep(id =>
              id != dependencyId
            ),
          }
          newRequest
        }
      })

      {...oldChain, requests: newRequests}
    }

    let blockSearch =
      <BlockSearch
        blocks={state.blocks}
        onInspect={block => {
          setState(oldState => {...oldState, inspected: Block(block)})
        }}
        onAdd={addBlock}
        onCreate={kind => {
          setState(oldState => {
            ...oldState,
            blockEdit: Create(makeBlankBlock(kind)),
          })
        }}
      />

    let sidebar = {
      <Inspector
        inspected={state.inspected}
        chain={state.chain}
        onAddBlock={addBlock}
        schema={state.schema}
        onDragStart={(~connectionDrag) => {
          setState(oldState => {
            ...oldState,
            connectionDrag: connectionDrag,
          })
        }}
        onRequestInspected
        oneGraphAuth
        onExecuteRequest
        onDeleteRequest={(targetRequest: Chain.request) => {
          setState(oldState => {
            let newChain = removeRequest(oldState.chain, targetRequest)

            let diagram = diagramFromChain(newChain)

            {
              ...oldState,
              chain: newChain,
              inspected: Nothing(newChain),
              diagram: diagram,
            }
          })
        }}
        onDeleteEdge={(~targetRequestId, ~dependencyId) => {
          setState(oldState => {
            let newChain = removeEdge(oldState.chain, ~targetRequestId, ~dependencyId)

            let diagram = diagramFromChain(newChain)

            {
              ...oldState,
              chain: newChain,
              inspected: Nothing(newChain),
              diagram: diagram,
            }
          })
        }}
        onPotentialVariableSourceConnect
        requestValueCache={state.requestValueCache}
        onReset={() => {
          setState(oldState => {...oldState, inspected: Nothing(state.chain)})
        }}
        savedChainId={state.savedChainId}
        onRequestCodeInspected={(~request) => {
          selectRequestFunctionScript(request)
        }}
        onPersistChain={() => {
          let compiled = state.chain->Inspector.transformChain
          let targetChain = compiled.chains->Belt.Array.getUnsafe(0)
          let freeVariables =
            targetChain.exposedVariables->Belt.Array.map(exposed => exposed.exposedName)

          OneGraphRe.persistQuery(
            ~appId=config.oneGraphAppId,
            ~persistQueryToken=config.persistQueryToken,
            ~queryToPersist=compiled.operationDoc,
            ~freeVariables,
            ~accessToken=config.chainAccessToken,
            ~fixedVariables=None,
            ~onComplete={
              results => {
                try {
                  let docId = Obj.magic(
                    results,
                  )["data"]["oneGraph"]["createPersistedQuery"]["persistedQuery"]["id"]

                  state.chain->Chain.saveToLocalStorage(docId)
                  setState(oldState => {
                    ...oldState,
                    savedChainId: Some(docId),
                  })
                } catch {
                | ex => Js.Console.error2("Error saving chain locally", ex)
                }
              }
            },
          )
        }}
        chainExecutionResults={state.chainExecutionResults}
        transformAndExecuteChain={(~variables) => {
          state.chain
          ->Inspector.transformAndExecuteChain(~oneGraphAuth, ~variables)
          ->Js.Promise.then_(result => {
            let json = result->Obj.magic
            setState(oldState => {...oldState, chainExecutionResults: json})->Js.Promise.resolve
          }, _)
          ->ignore
        }}
        onLogin={service => {
          oneGraphAuth->OneGraphAuth.login(service)->Js.Promise.then_(_ => {
            oneGraphAuth->OneGraphAuth.isLoggedIn(service)->Js.Promise.then_(isLoggedIn => {
              switch isLoggedIn {
              | false => ()
              | true =>
                setMissingAuthServices(oldMissingAuthServices => {
                  oldMissingAuthServices->Belt.Array.keep(oldService => oldService != service)
                })
              }->Js.Promise.resolve
            }, _)
          }, _)->ignore
        }}
        onChainUpdated={newChain => {
          let inspected: Inspector.inspectable = switch state.inspected {
          | Nothing(_) => Nothing(newChain)
          | Block(block) => Block(block)
          | Request(v) =>
            let request =
              newChain.requests
              ->Belt.Array.getBy(existingRequest => existingRequest.id == v.request.id)
              ->Belt.Option.getWithDefault(v.request)
            Request({request: request, chain: newChain})
          | RequestArgument({request, variableName}) =>
            let request =
              newChain.requests
              ->Belt.Array.getBy(existingRequest => existingRequest.id == request.id)
              ->Belt.Option.getWithDefault(request)
            RequestArgument({variableName: variableName, chain: newChain, request: request})
          }

          let diagram = diagramFromChain(newChain)

          setState(oldState => {
            ...oldState,
            chain: newChain,
            inspected: inspected,
            diagram: diagram,
          })
        }}
      />
    }

    <div style={ReactDOMStyle.make(~height="calc(100vh - 56px)", ())}>
      <InspectedContextProvider value={Some(state.inspected)}>
        <ConnectionContext.Provider value={state.connectionDrag}>
          <div className="flex">
            <div
              className="w-1/6 m:w-1/6 l:w-1/6 2xl:w-1/12 xl:w-1/6 "
              style={ReactDOMStyle.make(
                ~backgroundColor=Comps.colors["gray-9"],
                ~height="calc(100vh - 56px)",
                (),
              )}>
              {blockSearch}
            </div>
            <div className="w-1/2 m:w-1/2 xl:w-1/2 2xl:w-10/12">
              <div style={ReactDOMStyle.make(~height="calc(50vh - 28px)", ())}>
                {state.diagram->Belt.Option.mapWithDefault(React.null, diagram =>
                  <Diagram
                    setState diagram chain=state.chain removeEdge removeRequest diagramFromChain
                  />
                )}
              </div>
              <div style={ReactDOMStyle.make(~height="calc(50vh - 67px)", ())}>
                <div
                  className=""
                  onClick={_ => {
                    setState(oldState => {
                      ...oldState,
                      scriptEditor: {
                        ...oldState.scriptEditor,
                        isOpen: !oldState.scriptEditor.isOpen,
                      },
                    })
                  }}>
                  <Comps.Header
                    style={ReactDOMStyle.make(
                      ~backgroundColor=Comps.colors["gray-9"],
                      ~marginLeft="0px",
                      ~marginRight="0px",
                      ~display="flex",
                      (),
                    )}>
                    <div className="flex-grow"> {"Chain JavaScript"->React.string} </div>
                    <div>
                      <button
                        onClick={_ => {
                          state.scriptEditor.editor->Belt.Option.forEach(editor => {
                            let script = editor->BsReactMonaco.getValue
                            let newScript = script->Prettier.format({
                              "parser": "babel",
                              "plugins": [Prettier.babel],
                              "singleQuote": true,
                            })

                            setState(oldState => {
                              ...oldState,
                              chain: {...oldState.chain, script: newScript},
                            })
                          })
                        }}
                        title="Format code">
                        <Icons.Prettier.Dark height="16px" width="16px" />
                      </button>
                    </div>
                  </Comps.Header>
                </div>
                {false
                  ? React.null
                  : <Script
                      schema={state.schema}
                      chain={state.chain}
                      className=?{switch state.scriptEditor.isOpen {
                      | false => Some("none")
                      | true => None
                      }}
                      onPotentialScriptSourceConnect={(
                        ~sourceRequest,
                        ~sourceDom,
                        ~scriptPosition: ConnectionContext.scriptPosition,
                        ~mousePosition as (x, y): (int, int),
                      ) => {
                        setState(oldState => {
                          let connectionDrag = ConnectionContext.Completed({
                            sourceRequest: sourceRequest,
                            target: Script({scriptPosition: scriptPosition}),
                            windowPosition: (x, y),
                            sourceDom: sourceDom,
                          })

                          {
                            ...oldState,
                            connectionDrag: connectionDrag,
                          }
                        })
                      }}
                      onMount={(~editor, ~monaco) => {
                        setState(oldState => {
                          ...oldState,
                          scriptEditor: {
                            ...oldState.scriptEditor,
                            editor: Some(editor),
                            monaco: Some(monaco),
                          },
                        })
                      }}
                      onChange={newScript => {
                        try {
                          let newChain = {
                            ...state.chain,
                            script: newScript,
                          }

                          // let parsedScript = Acorn.parse(
                          //   newChain.script,
                          //   Acorn.parseOptions(~ecmaVersion=2020, ~sourceType=#"module", ()),
                          // )

                          let functionNames = []

                          let inspected: Inspector.inspectable = switch state.inspected {
                          | Nothing(_) => Nothing(newChain)
                          | Block(block) => Block(block)
                          | Request(v) =>
                            let request =
                              newChain.requests
                              ->Belt.Array.getBy(existingRequest =>
                                existingRequest.id == v.request.id
                              )
                              ->Belt.Option.getWithDefault(v.request)
                            Request({request: request, chain: newChain})
                          | RequestArgument({request, variableName}) =>
                            let request =
                              newChain.requests
                              ->Belt.Array.getBy(existingRequest =>
                                existingRequest.id == request.id
                              )
                              ->Belt.Option.getWithDefault(request)
                            RequestArgument({
                              variableName: variableName,
                              chain: newChain,
                              request: request,
                            })
                          }

                          setState(oldState => {
                            {
                              ...oldState,
                              scriptFunctions: functionNames,
                              chain: newChain,
                              inspected: inspected,
                            }
                          })
                        } catch {
                        | err => Js.Console.error2("Error updating script from editor: ", err)
                        }
                      }}
                    />}
              </div>
            </div>
            <div className="w-1/3 2xl:w-1/6"> {sidebar} </div>
          </div>
          {switch state.blockEdit {
          | Nothing => React.null
          | Create(block) as action | Edit(block) as action =>
            let isCreateAction = switch action {
            | Create(_) => true
            | _ => false
            }

            let editor =
              <BlockEditor
                schema={state.schema}
                block
                onClose={() => {
                  setState(oldState => {...oldState, blockEdit: Nothing})
                }}
                onSave={(~initial: Card.block, ~modified as superBlock: Card.block) => {
                  let ast = superBlock.body->GraphQLJs.parse
                  let initialAst = (initial.body->GraphQLJs.parse).definitions[0]

                  let newOperationDefinitionCount =
                    ast.definitions
                    ->Belt.Array.keep(definition => {
                      switch Obj.magic(definition)["kind"] {
                      | "FragmentDefinition"
                      | "ObjectTypeDefinition" => false
                      | _ => true
                      }
                    })
                    ->Belt.Array.length

                  let guessedInitialBlock = ref(None)

                  let blocks = ast.definitions->Belt.Array.mapWithIndex((_idx, definition) => {
                    let kind = switch Obj.magic(definition)["kind"] {
                    | "FragmentDefinition" => #fragment
                    | "ObjectTypeDefinition" => #objectType
                    | _ => definition.operation
                    }

                    let definition = switch kind {
                    | #objectType =>
                      let compiled = definition->GraphQLJs.Mock.compileComputeToIdentityQuery
                      Debug.assignToWindowForDeveloperDebug(
                        ~name="computedCompiled",
                        [definition->Obj.magic, compiled],
                      )
                      compiled
                    | _ => definition
                    }

                    let sameNameAsInitial = initialAst.name.value == definition.name.value
                    let sameOperationKindChanged = switch (
                      newOperationDefinitionCount,
                      initial.kind,
                      kind,
                    ) {
                    | (0, Fragment, #fragment) => true
                    | (1, _, #fragment) => false
                    | (1, _, _) => true
                    | _ => false
                    }

                    let sameOperationAsInitial = switch (
                      sameNameAsInitial,
                      sameOperationKindChanged,
                    ) {
                    | (false, false) => false
                    | (true, _)
                    | (_, true) => true
                    }

                    let services =
                      definition
                      ->Obj.magic
                      ->GraphQLUtils.gatherAllReferencedServices(~schema)
                      ->Belt.Array.map(service => service.slug)

                    let blank = makeBlankBlock(#query)

                    let title =
                      definition.name.value->Obj.magic->Belt.Option.getWithDefault("Untitled")

                    let block = {
                      ...blank,
                      id: sameOperationAsInitial ? initial.id : Uuid.v4(),
                      title: title,
                      services: services,
                      body: GraphQLJs.printAst(definition->Obj.magic),
                      kind: switch kind {
                      | #fragment => Fragment
                      | #query => Query
                      | #mutation => Mutation
                      | #subscription => Subscription
                      | #objectType => Compute
                      },
                    }

                    switch (sameNameAsInitial, sameOperationKindChanged) {
                    | (true, _) | (_, true) => guessedInitialBlock := Some(block)
                    | _ => ()
                    }

                    block
                  })

                  try {
                    setState(oldState => {
                      let newChain = blocks->Belt.Array.reduce(oldState.chain, (
                        newChain,
                        block,
                      ) => {
                        switch block.kind {
                        | Fragment => {
                            ...newChain,
                            blocks: newChain.blocks
                            ->Belt.Array.keep(existingBlock => existingBlock.id != block.id)
                            ->Belt.Array.concat([block]),
                          }
                        | _ =>
                          let isLikelyInitialBlock = Some(block) == guessedInitialBlock.contents

                          let initialReq = isLikelyInitialBlock
                            ? newChain.requests->Belt.Array.getBy(request => {
                                request.operation.id == initial.id
                              })
                            : None

                          let doc = block.body->GraphQLJs.parse
                          let definition = doc.definitions[0]
                          let variableNames = definition->GraphQLUtils.getOperationVariables

                          let variableDependencies = variableNames->Belt.Array.map(((
                            variableName,
                            _variableType,
                          )) => {
                            let existingVarDep = initialReq->Belt.Option.flatMap(request =>
                              request.variableDependencies->Belt.Array.getBy(
                                existingVariableDependency => {
                                  existingVariableDependency.name == variableName
                                },
                              )
                            )

                            let variableDep: Chain.variableDependencyKind = Direct({
                              {name: variableName, value: Variable(variableName)}
                            })

                            let varDep: Chain.variableDependency =
                              existingVarDep->Belt.Option.getWithDefault({
                                name: variableName,
                                dependency: variableDep,
                              })

                            varDep
                          })

                          let newReq: Chain.request = {
                            id: block.title,
                            operation: block,
                            variableDependencies: variableDependencies,
                            dependencyRequestIds: initialReq->Belt.Option.mapWithDefault([], req =>
                              req.dependencyRequestIds
                            ),
                          }

                          let names = newReq->Chain.requestScriptNames

                          let nameExistsInScript =
                            newChain.script
                            ->Js.String2.match_(
                              Js.Re.fromString(j`export function ${names.functionName}`),
                            )
                            ->Belt.Option.isSome

                          let newScript: string = nameExistsInScript
                            ? newChain.script
                            : newChain.script ++
                              j`

export function ${names.functionName} (payload : ${names.inputTypeName}) : ${names.returnTypeName} {
  return {}
}`

                          let newChain: Chain.t = {
                            name: newChain.name,
                            scriptDependencies: newChain.scriptDependencies,
                            blocks: newChain.blocks
                            ->Belt.Array.keep(existingBlock => existingBlock.id != block.id)
                            ->Belt.Array.concat([block]),
                            requests: newChain.requests
                            ->Belt.Array.keep(existingRequest => existingRequest.id != newReq.id)
                            ->Belt.Array.concat([newReq]),
                            script: newScript,
                          }

                          let newScript = {
                            let {dDotTs: _newTypes, importLine} = monacoTypelibForChain(
                              schema,
                              newChain,
                            )

                            let newImports = importLine

                            let hasImport =
                              newScript
                              ->Js.String2.match_(
                                Js.Re.fromString("import[\s\S.]+from[\s\S]+'oneGraphStudio';"),
                              )
                              ->Belt.Option.isSome

                            switch hasImport {
                            | false =>
                              `${newImports}

${newScript}`
                            | true =>
                              newScript->Js.String2.replaceByRe(
                                Js.Re.fromString("import[\s\S.]+from[\s\S]+'oneGraphStudio';"),
                                newImports,
                              )
                            }
                          }

                          let newChain: Chain.t = {
                            ...newChain,
                            script: newScript,
                          }

                          newChain
                        }
                      })

                      let newInitialBlock =
                        newChain.blocks
                        ->Belt.Array.getBy(block => block.id == initial.id)
                        ->Belt.Option.getWithDefault(blocks[0])

                      let inspected: Inspector.inspectable = switch isCreateAction {
                      | true =>
                        let request =
                          newChain.requests->Belt.Array.getBy(req =>
                            req.operation.id == newInitialBlock.id
                          )

                        request->Belt.Option.mapWithDefault(
                          Inspector.Nothing(newChain),
                          request => {
                            let newRequest = {...request, operation: newInitialBlock}
                            Request({request: newRequest, chain: newChain})
                          },
                        )
                      | false =>
                        switch oldState.inspected {
                        | Block(_) => Block(newInitialBlock)
                        | Nothing(_) => Nothing(newChain)
                        | Request({request}) =>
                          let newRequest = {...request, operation: newInitialBlock}
                          Request({request: newRequest, chain: newChain})
                        | RequestArgument({request, variableName}) =>
                          let newRequest = {...request, operation: newInitialBlock}
                          RequestArgument({
                            variableName: variableName,
                            chain: newChain,
                            request: newRequest,
                          })
                        }
                      }

                      let newBlocks = blocks

                      let allBlocks = switch oldState.blockEdit {
                      | _ => oldState.blocks->Belt.Array.concat(newBlocks)
                      // | _ =>
                      //   oldState.blocks->Belt.Array.keepMap(existingBlock => {
                      //     Some(existingBlock.id == newBlock.id ? newBlock : existingBlock)
                      //   })
                      }

                      let diagram = diagramFromChain(newChain)

                      {
                        ...oldState,
                        chain: newChain,
                        blockEdit: Nothing,
                        inspected: inspected,
                        diagram: diagram,
                        blocks: allBlocks,
                      }
                    })
                  } catch {
                  | _ => ()
                  }
                }}
              />

            <Modal> {editor} </Modal>
          }}
          {switch state.connectionDrag {
          | Empty => React.null
          | CompletedWithTypeMismatch({
              sourceRequest,
              variableTarget,
              windowPosition: (x, y),
              potentialFunctionMatches,
              dataPath,
              targetVariableType,
              sourceType,
            }) =>
            open React
            let onClick: option<string> => unit = name => {
              setState(oldState => {
                let parsed = try {
                  Some(
                    TypeScript.createSourceFile(
                      ~name="main.ts",
                      ~source=oldState.chain.script,
                      ~target=99,
                      true,
                    ),
                  )
                } catch {
                | _ => None
                }

                let targetVariableDependency = variableTarget.variableDependency

                let newRequests = oldState.chain.requests->Belt.Array.map(request => {
                  switch variableTarget.targetRequest.id == request.id {
                  | false => request
                  | true =>
                    let varDeps = request.variableDependencies->Belt.Array.map(varDep => {
                      switch varDep.name == targetVariableDependency.name {
                      | true =>
                        let dependency = Chain.ArgumentDependency({
                          name: targetVariableDependency.name,
                          ifMissing: #SKIP,
                          ifList: #FIRST,
                          fromRequestIds: request.dependencyRequestIds,
                          functionFromScript: "TBD",
                          maxRecur: None,
                        })

                        {...varDep, dependency: dependency}

                      | false =>
                        let dependency = switch varDep.dependency {
                        | ArgumentDependency(argDep) =>
                          let newArgDep = {
                            ...argDep,
                            fromRequestIds: argDep.fromRequestIds
                            ->Belt.Array.concat([sourceRequest.id])
                            ->Utils.distinctStrings,
                          }

                          Chain.ArgumentDependency(newArgDep)
                        | other => other
                        }
                        let varDep = {...varDep, dependency: dependency}

                        varDep
                      }
                    })

                    {
                      ...request,
                      variableDependencies: varDeps,
                      dependencyRequestIds: request.dependencyRequestIds
                      ->Belt.Array.concat([sourceRequest.id])
                      ->Utils.distinctStrings,
                    }
                  }
                })

                let request = newRequests->Belt.Array.getBy(request => {
                  variableTarget.targetRequest.id == request.id
                })

                let lineNumbers = request->Belt.Option.flatMap(request => {
                  let names = request->Chain.requestScriptNames

                  let target = parsed->Belt.Option.flatMap(parsed =>
                    parsed
                    ->TypeScript.findFnPos(names.functionName)
                    ->Belt.Option.map(({start, firstStatementStart}) => {
                      let {line} = parsed->TypeScript.getLineAndCharacterOfPosition(start)
                      let firstStatementLine = firstStatementStart->Belt.Option.mapWithDefault(
                        line,
                        firstStatementStart => {
                          let {line} =
                            parsed->TypeScript.getLineAndCharacterOfPosition(firstStatementStart)
                          line
                        },
                      )

                      (line, firstStatementLine)
                    })
                  )
                  target
                })

                let _re = Js.Re.fromStringWithFlags(~flags="g", "\\[.+\\]")
                let binding = // Should we use the last item, or the targetVariable name?
                // dataPath[dataPath->Js.Array2.length - 1]->Js.String2.replaceByRe(re, "")
                targetVariableDependency.name

                let nullableTargetVariableType =
                  targetVariableType->Belt.Option.map(typ =>
                    typ->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("!", ~flags="g"), "")
                  )

                let nullablePrintedType =
                  sourceType->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("!", ~flags="g"), "")

                let defaultCoercerName = j`${nullablePrintedType}To${nullableTargetVariableType->Belt.Option.getWithDefault(
                    "Unknown",
                  )}`

                let coercerName = switch name {
                | None =>
                  Utils.prompt(
                    "Coercer function name: ",
                    ~default=Some(defaultCoercerName),
                  )->Belt.Option.getWithDefault(defaultCoercerName)
                | Some(name) => name
                }

                let coercerExists = switch coercerName {
                | "INTERNAL_PASSTHROUGH" => true
                | _ =>
                  parsed
                  ->Belt.Option.flatMap(parsed => parsed->TypeScript.findFnPos(coercerName))
                  ->Belt.Option.isSome
                }

                let newScript = lineNumbers->Belt.Option.map(((
                  _fnLineNumber,
                  fnBodyLineNumber,
                )) => {
                  let newBinding = switch coercerName {
                  | "INTERNAL_PASSTHROUGH" =>
                    j`\tlet ${binding} = ${dataPath->Js.Array2.joinWith("?.")}`
                  | _ => j`\tlet ${binding} = ${coercerName}(${dataPath->Js.Array2.joinWith("?.")})`
                  }

                  let temp = oldState.chain.script->Js.String2.split("\n")

                  let _ =
                    temp->Js.Array2.spliceInPlace(
                      ~pos=fnBodyLineNumber + 1,
                      ~remove=0,
                      ~add=[newBinding],
                    )

                  let signatureReturnType =
                    nullableTargetVariableType->Belt.Option.mapWithDefault("", t => j`: ${t}`)

                  let newFunctionDefinition = j`function ${coercerName}(${binding} : ${nullablePrintedType}) ${signatureReturnType} {
  return ${binding}
}`

                  coercerExists
                    ? temp->Js.Array2.joinWith("\n")
                    : temp->Js.Array2.joinWith("\n") ++ "\n\n" ++ newFunctionDefinition
                })

                let parsed = newScript->Belt.Option.flatMap(newScript =>
                  try {
                    Some(
                      TypeScript.createSourceFile(
                        ~name="main.ts",
                        ~source=newScript,
                        ~target=99,
                        true,
                      ),
                    )
                  } catch {
                  | _ => None
                  }
                )

                let functionObjectLiteralReturn = request->Belt.Option.flatMap(request => {
                  let names = request->Chain.requestScriptNames

                  parsed->Belt.Option.flatMap(parsed =>
                    parsed->TypeScript.findLastReturnObjectPos(
                      ~functionName=names.functionName,
                      ~properyName=binding,
                    )
                  )
                })

                let shouldInsertPropertyInReturn =
                  functionObjectLiteralReturn->Belt.Option.mapWithDefault(false, return =>
                    return.property->Belt.Option.isNone
                  )

                let newScript = newScript->Belt.Option.map(newScript =>
                  functionObjectLiteralReturn->Belt.Option.mapWithDefault(
                    newScript,
                    returnObjectPositions => {
                      shouldInsertPropertyInReturn
                        ? {
                            Debug.assignToWindowForDeveloperDebug(~name="tNewScript", newScript)
                            let head =
                              newScript->Js.String2.slice(
                                ~from=0,
                                ~to_=returnObjectPositions.objectPosition.start + 2,
                              )

                            let tail =
                              newScript->Js.String2.slice(
                                ~from=returnObjectPositions.objectPosition.start + 2,
                                ~to_=newScript->Js.String2.length,
                              )

                            j`${head} ${binding}: ${binding},${tail}`
                          }
                        : newScript
                    },
                  )
                )

                let newChain = {
                  ...oldState.chain,
                  script: newScript->Belt.Option.getWithDefault(oldState.chain.script),
                  requests: newRequests,
                }

                {...oldState, chain: newChain, connectionDrag: Empty}
              })
            }

            <div
              className="absolute"
              style={ReactDOMRe.Style.make(
                ~width="500px",
                ~top=j`${y->string_of_int}px`,
                ~left=j`${x->string_of_int}px`,
                ~maxHeight="200px",
                ~overflowY="scroll",
                (),
              )}>
              <div className="m-2 p-2 bg-gray-600 rounded-sm text-gray-200">
                {"Type mismatch, choose coercer: "->string}
                <ul>
                  <li
                    className="cursor-pointer hover:bg-blue-400 hover:text-white"
                    key="INTERNAL_PASSTHROUGH"
                    onClick={_ => onClick(Some("INTERNAL_PASSTHROUGH"))}>
                    {"Passthrough"->string}
                  </li>
                  {potentialFunctionMatches
                  ->Belt.Array.map((fn: TypeScript.simpleFunctionType) => {
                    <li
                      className="cursor-pointer hover:bg-blue-400 hover:text-white"
                      onClick={_ => onClick(Some(fn.name))}
                      key=fn.name>
                      {fn.name->string}
                    </li>
                  })
                  ->array}
                  <li
                    className="cursor-pointer hover:bg-blue-400 hover:text-white"
                    key="createNew"
                    onClick={_ => onClick(None)}>
                    {"Create new function"->string}
                  </li>
                </ul>
              </div>
            </div>
          | Completed({sourceRequest, target: Script({scriptPosition}), windowPosition: (x, y)}) =>
            let chainFragmentsDoc =
              state.chain.blocks
              ->Belt.Array.keepMap(block => {
                switch block.kind {
                | Fragment => Some(block.body)
                | _ => None
                }
              })
              ->Js.Array2.joinWith("\n\n")

            let parsedOperation = sourceRequest.operation.body->GraphQLJs.parse
            let definition = parsedOperation.definitions->Belt.Array.getExn(0)

            <div
              className="absolute"
              style={ReactDOMRe.Style.make(
                ~width="500px",
                ~top=j`${y->string_of_int}px`,
                ~left=j`${x->string_of_int}px`,
                ~maxHeight="200px",
                ~overflowY="scroll",
                (),
              )}>
              <div className="m-2 p-2 bg-gray-600 rounded-sm text-gray-200">
                <Inspector.GraphQLPreview
                  requestId=sourceRequest.id
                  schema
                  definition
                  fragmentDefinitions={GraphQLJs.Mock.gatherFragmentDefinitions({
                    "operationDoc": chainFragmentsDoc,
                  })}
                  onCopy={payload => {
                    let {path} = payload
                    let dataPath = ["payload"]->Belt.Array.concat(path)
                    let re = Js.Re.fromStringWithFlags(~flags="g", "\\[.+\\]")
                    let binding =
                      dataPath[dataPath->Js.Array2.length - 1]->Js.String2.replaceByRe(re, "")

                    setState(oldState => {
                      let parsed = try {
                        Some(
                          TypeScript.createSourceFile(
                            ~name="main.ts",
                            ~source=oldState.chain.script,
                            ~target=99,
                            true,
                          ),
                        )
                      } catch {
                      | _ => None
                      }

                      let lineNumber = parsed->Belt.Option.map(parsed =>
                        try {
                          let position =
                            parsed->TypeScript.getPositionOfLineAndCharacter(
                              scriptPosition.lineNumber - 1,
                              scriptPosition.column - 1,
                            )

                          let parsedPosition =
                            parsed
                            ->TypeScript.findPositionOfFirstLineOfContainingFunctionForPosition(
                              position,
                            )
                            ->Belt.Option.getExn

                          let lineAndCharacter =
                            parsed->TypeScript.getLineAndCharacterOfPosition(parsedPosition)

                          lineAndCharacter.line + 1
                        } catch {
                        | e =>
                          Js.Console.warn2("Exn trying to find smart position", e)
                          scriptPosition.lineNumber - 1
                        }
                      )

                      let assignmentExpressionRange = parsed->Belt.Option.flatMap(parsed => {
                        let position =
                          parsed->TypeScript.getPositionOfLineAndCharacter(
                            scriptPosition.lineNumber - 1,
                            scriptPosition.column - 1,
                          )
                        parsed->TypeScript.findContainingDeclaration(position)
                      })

                      let newScript = switch (assignmentExpressionRange, lineNumber) {
                      | (Some({name, start, end}), _) =>
                        let newBinding = j`${name} = ${dataPath->Js.Array2.joinWith("?.")}`

                        oldState.chain.script->Utils.replaceRange(
                          ~start=start + 1,
                          ~end,
                          ~by=newBinding,
                        )
                      | (_, Some(lineNumber)) =>
                        let newBinding = j`\tlet ${binding} = ${dataPath->Js.Array2.joinWith("?.")}`

                        let temp = oldState.chain.script->Js.String2.split("\n")

                        let _ =
                          temp->Js.Array2.spliceInPlace(
                            ~pos=lineNumber,
                            ~remove=0,
                            ~add=[newBinding],
                          )
                        temp->Js.Array2.joinWith("\n")
                      | _ => oldState.chain.script
                      }

                      let newChain = {...oldState.chain, script: newScript}

                      {
                        ...oldState,
                        chain: newChain,
                        connectionDrag: Empty,
                      }
                    })
                  }}
                />
              </div>
            </div>
          | Completed({
              sourceRequest,
              sourceDom,
              target: Variable(
                {variableDependency: targetVariableDependency, targetRequest} as variabletarget,
              ),
              windowPosition: (x, y) as windowPosition,
            }) =>
            let chainFragmentsDoc =
              state.chain.blocks
              ->Belt.Array.keepMap(block => {
                switch block.kind {
                | Fragment => Some(block.body)
                | _ => None
                }
              })
              ->Js.Array2.joinWith("\n\n")

            let parsedOperation = sourceRequest.operation.body->GraphQLJs.parse
            let definition = parsedOperation.definitions->Belt.Array.getExn(0)

            let targetParsedOperation = targetRequest.operation.body->GraphQLJs.parse
            let targetDefinition = targetParsedOperation.definitions->Belt.Array.getExn(0)
            let targetVariables = targetDefinition->GraphQLUtils.getOperationVariables

            let targetVariableType =
              targetVariables
              ->Belt.Array.getBy(((variableName, _)) => {
                targetVariableDependency.name == variableName
              })
              ->Belt.Option.map(((_, typ)) => typ)

            <div
              className="absolute"
              style={ReactDOMRe.Style.make(
                ~width="500px",
                ~top=j`${y->string_of_int}px`,
                ~left=j`${x->string_of_int}px`,
                ~zIndex="999",
                (),
              )}>
              <div className="m-2 p-2 bg-gray-600 rounded-sm text-gray-200">
                <Inspector.GraphQLPreview
                  requestId=sourceRequest.id
                  schema
                  definition
                  fragmentDefinitions={GraphQLJs.Mock.gatherFragmentDefinitions({
                    "operationDoc": chainFragmentsDoc,
                  })}
                  targetGqlType=?targetVariableType
                  onCopy={({printedType, path}) => {
                    let dataPath = ["payload"]->Belt.Array.concat(path)

                    let nullableTargetVariableType =
                      targetVariableType->Belt.Option.map(typ =>
                        typ->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("!", ~flags="g"), "")
                      )

                    let nullablePrintedType =
                      printedType->Js.String2.replaceByRe(
                        Js.Re.fromStringWithFlags("!", ~flags="g"),
                        "",
                      )

                    let typesMatch = switch (
                      Some(nullablePrintedType),
                      nullableTargetVariableType,
                    ) {
                    | (Some(a), Some(b)) if a == b => true
                    | (Some("String"), Some("ID"))
                    | (Some("ID"), Some("String")) => true
                    | (Some("Int"), Some("Float"))
                    | (Some("Float"), Some("Int")) => true
                    | (Some("JSON"), _)
                    | (_, Some("JSON")) => true
                    | _ => false
                    }

                    switch typesMatch {
                    | false =>
                      setState(oldState => {
                        let parsed = try {
                          Some(
                            TypeScript.createSourceFile(
                              ~name="main.ts",
                              ~source=oldState.chain.script,
                              ~target=99,
                              true,
                            ),
                          )
                        } catch {
                        | _ => None
                        }

                        let newConnectionDrag = parsed->Belt.Option.map(parsed => {
                          let fnTypes = parsed->TypeScript.findFunctionTypes

                          let existingFnMatches =
                            fnTypes
                            ->Js.Dict.values
                            ->Belt.Array.keep(({firstParamType, returnType}) => {
                              let firstParamMatches = switch (
                                nullablePrintedType->Js.String2.toLocaleLowerCase,
                                firstParamType->Belt.Option.map(Js.String2.toLocaleLowerCase),
                              ) {
                              | (a, Some(b)) if a == b => true
                              | ("int", Some("number"))
                              | ("float", Some("number")) => true
                              | ("id", Some("string")) => true
                              | _ => false
                              }

                              let returnTypeMatches = switch (
                                nullableTargetVariableType->Belt.Option.map(
                                  Js.String2.toLocaleLowerCase,
                                ),
                                returnType->Belt.Option.map(Js.String2.toLocaleLowerCase),
                              ) {
                              | (Some(a), Some(b)) if a == b => true
                              | (Some("int"), Some("number"))
                              | (Some("float"), Some("number")) => true
                              | (Some("id"), Some("string")) => true
                              | _ => false
                              }

                              firstParamMatches && returnTypeMatches
                            })
                            ->Belt.SortArray.stableSortBy((a, b) => String.compare(a.name, b.name))

                          ConnectionContext.CompletedWithTypeMismatch({
                            sourceRequest: sourceRequest,
                            sourceDom: sourceDom,
                            variableTarget: variabletarget,
                            windowPosition: windowPosition,
                            targetVariableType: targetVariableType,
                            sourceType: printedType,
                            potentialFunctionMatches: existingFnMatches,
                            dataPath: dataPath,
                          })
                        })

                        {
                          ...oldState,
                          connectionDrag: newConnectionDrag->Belt.Option.getWithDefault(Empty),
                        }
                      })
                    | true =>
                      setState(oldState => {
                        let potentialProbeDependency = Chain.GraphQLProbe({
                          name: targetVariableDependency.name,
                          ifMissing: #SKIP,
                          ifList: #FIRST,
                          fromRequestId: sourceRequest.id,
                          functionFromScript: "TBD",
                          path: dataPath,
                        })

                        let newRequests = oldState.chain.requests->Belt.Array.map(request => {
                          switch targetRequest.id == request.id {
                          | false => request
                          | true =>
                            let varDeps = request.variableDependencies->Belt.Array.map(varDep => {
                              switch varDep.name == targetVariableDependency.name {
                              | true => {...varDep, dependency: potentialProbeDependency}

                              | false =>
                                let dependency = switch varDep.dependency {
                                | ArgumentDependency(argDep) =>
                                  let newArgDep = {
                                    ...argDep,
                                    fromRequestIds: argDep.fromRequestIds
                                    ->Belt.Array.concat([sourceRequest.id])
                                    ->Utils.distinctStrings,
                                  }

                                  Chain.ArgumentDependency(newArgDep)
                                | other => other
                                }
                                let varDep = {...varDep, dependency: dependency}

                                varDep
                              }
                            })

                            {
                              ...request,
                              variableDependencies: varDeps,
                              dependencyRequestIds: request.dependencyRequestIds
                              ->Belt.Array.concat([sourceRequest.id])
                              ->Utils.distinctStrings,
                            }
                          }
                        })

                        let newChain = {...oldState.chain, requests: newRequests}

                        let diagram = diagramFromChain(newChain)

                        {
                          ...oldState,
                          diagram: diagram,
                          chain: newChain,
                          connectionDrag: Empty,
                        }
                      })
                    }
                  }}
                />
              </div>
            </div>
          | StartedSource(conDrag) =>
            <ConnectorLine
              source=conDrag.sourceDom
              invert={false}
              onDragEnd={() => {
                setState(oldState => {
                  {...oldState, connectionDrag: Empty}
                })
              }}
            />
          | StartedTarget({target: Variable(_), sourceDom}) =>
            <ConnectorLine
              source=sourceDom
              invert={true}
              onDragEnd={() => {
                setState(oldState => {
                  {...oldState, connectionDrag: Empty}
                })
              }}
            />
          | StartedTarget({target: Script(_)}) => // TODO!
            React.null
          }}
        </ConnectionContext.Provider>
      </InspectedContextProvider>
    </div>
  }
}

@react.component
let make = (~schema, ~initialChain: Chain.t, ~config: Config.Studio.t) => {
  let oneGraphAuth = OneGraphAuth.create(
    OneGraphAuth.createOptions(~appId=config.oneGraphAppId, ()),
  )
  oneGraphAuth
  ->Belt.Option.map(oneGraphAuth => {
    <ReactFlow.Provider> <Main schema initialChain config oneGraphAuth /> </ReactFlow.Provider>
  })
  ->Belt.Option.getWithDefault("Loading Chain Editor..."->React.string)
}
