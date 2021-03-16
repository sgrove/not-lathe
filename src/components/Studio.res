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

type studioConfig = {
  oneGraphAppId: string,
  persistQueryToken: string,
  chainAccessToken: option<string>,
}

type debuggable =
  | Chain
  | CompiledChain

type state = {
  diagram: diagram,
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
}

let makeBlankBlock = (): Card.block => {
  {
    title: "Untitled",
    id: Uuid.v4(),
    services: [],
    body: "query Untitled { __typename }",
    description: "TODO",
    contributedBy: None,
    kind: Query,
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

    <div className="flex w-full m-0 max-h-full block bg-gray-900">
      <div className="w-full max-h-full">
        <Comps.Header> {"Block Library"->React.string} </Comps.Header>
        <div className="shadow-md rounded-lg px-3 py-2 h-full overflow-y-hidden">
          <div className="flex items-center bg-gray-200 rounded-md inline-block">
            <div className="pl-2">
              <svg className="fill-current text-gray-500 w-6 h-6" viewBox="0 0 24 24">
                <path
                  d="M16.32 14.9l5.39 5.4a1 1 0 0 1-1.42 1.4l-5.38-5.38a8 8 0 1 1 1.41-1.41zM10 16a6 6 0 1 0 0-12 6 6 0 0 0 0 12z"
                />
              </svg>
            </div>
            <input
              className="w-full rounded-md bg-gray-200 text-gray-700 leading-tight focus:outline-none py-2 px-2 border-0"
              id="search"
              type_="text"
              placeholder="Search for GraphQL blocks"
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
            <div className="flex items-center bg-gray-200 rounded-md inline ">
              <button className="p-2 hover:bg-blue-200 rounded-md" onClick={_ => onCreate()}>
                {"+"->React.string}
              </button>
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
                className="flex justify-start cursor-grab text-gray-700 hover:text-blue-400 hover:bg-blue-200 bg-blue-100 rounded-md px-2 py-2 mt-2 mb-2"
                onDoubleClick={_ => onAdd(block)}
                onClick={_ => onInspect(block)}>
                <span
                  className={switch block.kind {
                  | Query => "bg-green-400"
                  | Mutation => "bg-red-400"
                  | Subscription => "bg-yellow-400"
                  | Fragment => "bg-gray-400"
                  } ++ " h-2 w-2 m-2 rounded-full"}
                />
                <div className="flex-grow font-medium px-2 truncate"> {block.title->string} </div>
                {block.services
                ->Belt.Array.keepMap(service =>
                  service
                  ->Utils.serviceImageUrl
                  ->Belt.Option.map(((url, friendlyServiceName)) =>
                    <img
                      alt=friendlyServiceName
                      title=friendlyServiceName
                      style={ReactDOMStyle.make(~pointerEvents="none", ())}
                      src=url
                      className="rounded-full"
                    />
                  )
                )
                ->array}
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

module NodeLabel = {
  type state = {isOpen: bool}

  @react.component
  let make = (~onInspectBlock, ~block: Card.block, ~onEditBlock, ~schema) => {
    let (state, setState) = React.useState(() => {
      isOpen: false,
    })

    let parsedOperation = block.body->GraphQLJs.parse
    let definition = parsedOperation.definitions->Belt.Array.getExn(0)

    let services =
      block.services
      ->Belt.Array.keepMap(service =>
        service
        ->Utils.serviceImageUrl
        ->Belt.Option.map(((url, friendlyServiceName)) =>
          <img
            className="shadow-lg rounded-full"
            alt=friendlyServiceName
            title=friendlyServiceName
            style={ReactDOMStyle.make(~pointerEvents="none", ())}
            src=url
          />
        )
      )
      ->React.array

    open React

    <div
      onContextMenu={event => {
        ReactEvent.Mouse.preventDefault(event)
        onInspectBlock->Belt.Option.forEach(fn => fn(block))
      }}
      className="flex align-middle items-center min-w-max flex-col">
      <div className="flex flex-row items-center justify-end">
        <div
          className="p-2 hover:shadow-lg rounded-md border hover:border-gray-300 cursor-pointer m-2"
          onClick={event => {
            event->ReactEvent.Mouse.stopPropagation
            event->ReactEvent.Mouse.preventDefault
            setState(oldState => {isOpen: !oldState.isOpen})
          }}>
          <Icons.Inspect color="black" />
        </div>
        <div className="m-2"> {services} </div>
        <div className="flex-1 inline-block"> {block.title->string} </div>
        <div
          className="p-2 hover:shadow-lg rounded-md border hover:border-gray-300 cursor-pointer m-0"
          onClick={event => {
            ReactEvent.Mouse.preventDefault(event)
            onEditBlock(block)
          }}>
          <Icons.GraphQL color="black" />
        </div>
      </div>
      <div>
        <div
          className={"m-2 p-2 bg-gray-600 rounded-sm text-gray-200 " ++ (
            state.isOpen ? "" : "hidden"
          )}>
          <Inspector.GraphQLPreview
            requestId=block.title
            schema
            definition
            onCopy={path => {
              let dataPath = path->Js.Array2.joinWith("?.")
              let fullPath = "payload." ++ dataPath

              fullPath->Inspector.Clipboard.copy
            }}
          />
        </div>
      </div>
    </div>
  }
}

let diagramFromChain = (chain: Chain.t, ~onEditBlock, ~onInspectBlock=?, ~schema, ()): diagram => {
  open ReactFlow

  let nodes = chain.blocks->Belt.Array.map(block => {
    let variables = block->Card.getFirstVariables
    let hasVariables = variables->Belt.Array.length > 0

    let typ = switch (block.kind, hasVariables) {
    | (Fragment, _) => #fragment
    | (_, true) => #default
    | (_, false) => #input
    }

    let node = Node.t(
      ~typ,
      ~id=block.id->Uuid.toString,
      ~data={
        label: <NodeLabel onEditBlock onInspectBlock block schema />,
      },
      ~position={x: 0., y: 0.},
      ~draggable=true,
      ~connectable=switch typ {
      | #fragment => false
      | _ => true
      },
      ~onClick={_ => Debug.alert("Clicked")},
      ~style=ReactDOMStyle.make(~width="unset", ()),
      (),
    )
    node
  })

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
    let edge = Edge.t(~id, ~source, ~target, ~animated=true, ~typ=#step, ())
    edge
  })

  let layoutedElements = Dagre.getLayoutedElements(~nodes, ~edges, ~nodeWidth=10., ~nodeHeight=50.)

  {nodes: nodes, edges: edges, elements: layoutedElements}
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
          let tsSignature = GraphQLJs.Mock.typeScriptForOperation(schema, dependencyRequest)
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
  | "{}" => "null"
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
  ) => {
    let content = chain.script

    let editor = React.useRef(None)
    let monaco = React.useRef(None)

    let {dDotTs: types} = monacoTypelibForChain(schema, chain)

    React.useEffect1(() => {
      editor.current->Belt.Option.forEach(editor => {
        let position = editor->BsReactMonaco.getPosition
        editor->BsReactMonaco.setValue(content)
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

    let editor =
      <BsReactMonaco.Editor
        ?className
        theme="vs-dark"
        language="typescript"
        defaultValue={content}
        options={
          "minimap": {"enabled": false},
        }
        path=filename
        onChange={(newScript, _) => {
          onChange(newScript)
        }}
        onMount={(editorHandle, monacoInstance) => {
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

    <> {editor} </>
  }
}

module Modal = {
  @react.component
  let make = (~children) => {
    <div
      style={ReactDOMStyle.make(~zIndex="9999", ())}
      className="flex items-center justify-center fixed left-0 bottom-0 w-full h-full bg-gray-800 bg-opacity-60">
      <div className="bg-white rounded-lg w-4/5 h-4/5">
        <div className="flex flex-col p-1 h-full">
          <div className="flex h-full"> {children} </div>
        </div>
      </div>
    </div>
  }
}

module Main = {
  @react.component
  let make = (~schema, ~initialChain: Chain.t, ~config: studioConfig) => {
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

      let diagram = diagramFromChain(
        initialChain,
        ~schema,
        ~onEditBlock=_block => {
          ()
        },
        ~onInspectBlock=_block => {
          ()
        },
        (),
      )

      let inspected: Inspector.inspectable = Nothing(initialChain)
      // Request({
      //   chain: initialChain,
      //   request: initialChain.requests->Belt.Array.get(1)->Belt.Option.getExn,
      // })
      // Block(Card.blocks[0])

      {
        diagram: diagram,
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
      }
    })

    let selectRequestFunctionScript = (request: Chain.request) => {
      let names = request->Chain.requestScriptNames
      let functionName = names.functionName

      let source = state.chain.script

      let sourceFile = TypeScript.createSourceFile(~name="main.ts", ~source, ~target=99, true)
      let pos = TypeScript.findFnPos(sourceFile, functionName)

      pos->Belt.Option.forEach(((start, end)) => {
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

    let diagramFromChain = chain =>
      diagramFromChain(
        chain,
        ~schema,
        ~onEditBlock=block => {
          setState(oldState => {...oldState, blockEdit: Edit(block)})
        },
        (),
      )

    let {fitView} = ReactFlow.useZoomPanHelper()

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

      let promise = OneGraphRe.fetchOneGraph(
        OneGraphRe.auth,
        request.operation.body,
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

        let blank = makeBlankBlock()

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

      Js.log3("Adding Blocks: ", blocks, blocks->Belt.Array.length)

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
            blocks: newChain.blocks->Belt.Array.concat([block]),
            requests: newChain.requests->Belt.Array.concat([newReq]),
            script: newScript,
          }

          Js.log3(
            "\tNew req/block count: ",
            newChain.blocks->Belt.Array.length,
            newChain.requests->Belt.Array.length,
          )

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
          Js.log4("Removed edge for request: ", request, newRequest, dependencyId)
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
        onCreate={() => {
          setState(oldState => {
            ...oldState,
            blockEdit: Create(makeBlankBlock()),
          })
        }}
      />

    let sidebar = {
      <Inspector
        inspected={state.inspected}
        chain={state.chain}
        onAddBlock={addBlock}
        schema={state.schema}
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
            Js.log3("Remove id from", dependencyId, targetRequestId)
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
                | ex => Js.log2("Error saving chain locally", ex)
                }
              }
            },
          )
        }}
        chainExecutionResults={state.chainExecutionResults}
        transformAndExecuteChain={(~variables) => {
          state.chain->Inspector.transformAndExecuteChain(~variables)->Js.Promise.then_(result => {
            let json = result->Obj.magic
            setState(oldState => {...oldState, chainExecutionResults: json})->Js.Promise.resolve
          }, _)->ignore
        }}
        onLogin={service => {
          let auth = OneGraphRe.auth
          auth->OneGraphAuth.login(service)->Js.Promise.then_(_ => {
            auth->OneGraphAuth.isLoggedIn(service)->Js.Promise.then_(isLoggedIn => {
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

    <div>
      <div className="flex">
        <div className="w-1/6 h-screen 2xl:w-1/6 bg-gray-800"> {blockSearch} </div>
        <div className="w-1/2">
          <div className="h-1/2">
            <ReactFlow
              nodeTypes={
                "fragment": FragmentNodeComponent.make,
              }
              onElementsRemove={elements => {
                setState(oldState => {
                  let newChain = elements->Belt.Array.reduce(oldState.chain, (
                    accChain,
                    element,
                  ) => {
                    let typ = switch (
                      Obj.magic(element)["source"]->Js.Undefined.toOption,
                      Obj.magic(element)["target"]->Js.Undefined.toOption,
                    ) {
                    | (Some(source), Some(target)) => #edge(source, target)
                    | _ => #node(Obj.magic(element)["id"])
                    }

                    let newChain = switch typ {
                    | #edge(source, targetRequestId) =>
                      Js.log3("Removing edge: ", source, targetRequestId)
                      let newChain = removeEdge(accChain, ~dependencyId=source, ~targetRequestId)
                      newChain
                    | #node(source) =>
                      let targetRequest = accChain.requests->Belt.Array.getBy(request => {
                        Js.log3("Removing node:  ", source, request.id)
                        request.operation.id == source
                      })

                      let newChain =
                        targetRequest
                        ->Belt.Option.map(targetRequest => removeRequest(accChain, targetRequest))
                        ->Belt.Option.getWithDefault(accChain)
                      newChain
                    }

                    Js.log3(
                      "New chain req count: ",
                      accChain.requests->Belt.Array.length,
                      newChain.requests->Belt.Array.length,
                    )

                    newChain
                  })

                  let diagram = diagramFromChain(newChain)

                  Js.log2("New chain: ", newChain)

                  {...oldState, chain: newChain, diagram: diagram}
                })
              }}
              elements=state.diagram.elements
              zoomOnScroll=false
              onPaneClick={_ => {
                setState(oldState => {...oldState, inspected: Nothing(oldState.chain)})
              }}
              onPaneContextMenu={event => {
                ReactEvent.Mouse.preventDefault(event)
              }}
              onNodeContextMenu={(event, node) => {
                ReactEvent.Mouse.preventDefault(event)

                let block =
                  state.blocks->Belt.Array.getBy(block =>
                    block.id == node->ReactFlow.Node.idGet->Uuid.parseExn
                  )

                block->Belt.Option.forEach(block => {
                  let request = state.chain.requests->Belt.Array.getBy(req => {
                    req.id == block.title
                  })
                  request->Belt.Option.forEach(selectRequestFunctionScript)
                })
              }}
              panOnScroll=true
              onConnect={info => {
                let source = info["source"]
                let target = info["target"]

                let sourceRequest = state.chain.requests->Belt.Array.getBy(request => {
                  request.operation.id->Uuid.toString == source
                })

                let targetRequest = state.chain.requests->Belt.Array.getBy(request => {
                  request.operation.id->Uuid.toString == target
                })

                switch (sourceRequest, targetRequest) {
                | (None, _)
                | (_, None) =>
                  Js.log("Couldn't find source or target request to connect")
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

                    let newChain = {...oldState.chain, requests: newRequests}

                    let diagram = diagramFromChain(newChain)

                    {...oldState, chain: newChain, diagram: diagram}
                  })
                }
              }}
              onElementClick={(_, node) => {
                let id = node->ReactFlow.Node.idGet

                let request: option<Inspector.inspectable> =
                  state.chain.requests
                  ->Belt.Array.getBy(req => {
                    req.operation.id->Uuid.toString == id
                  })
                  ->Belt.Option.map(req => {
                    let inspected: Inspector.inspectable = Request({
                      chain: state.chain,
                      request: req,
                    })
                    inspected
                  })

                let inspected = switch request {
                | Some(inspected) => Some(inspected)
                | None =>
                  let block =
                    state.chain.blocks->Belt.Array.getBy(block => block.id->Uuid.toString == id)
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
                color="#666666"
                style={ReactDOMStyle.make(~backgroundColor="rgb(60, 60, 60)", ())}
              />
            </ReactFlow>
          </div>
          <div className="h-1/2">
            <div
              className="border-t border-gray-500 bg-gray-900"
              onClick={_ => {
                setState(oldState => {
                  ...oldState,
                  scriptEditor: {
                    ...oldState.scriptEditor,
                    isOpen: !oldState.scriptEditor.isOpen,
                  },
                })
              }}>
              <nav>
                <Comps.Header>
                  {"Chain JavaScript"->React.string}
                  <button
                    className="ml-2 mr-2"
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
                    <Icons.PureScript />
                  </button>
                </Comps.Header>
              </nav>
            </div>
            <Script
              schema={state.schema}
              chain={state.chain}
              className=?{switch state.scriptEditor.isOpen {
              | false => Some("none")
              | true => None
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

                  setState(oldState => {
                    {
                      ...oldState,
                      scriptFunctions: functionNames,
                      chain: newChain,
                      inspected: inspected,
                    }
                  })
                } catch {
                | err => Js.log2("Error updating script from editor: ", err)
                }
              }}
            />
          </div>
        </div>
        <div className="w-1/3"> {sidebar} </div>
      </div>
      {switch state.blockEdit {
      | Nothing => React.null
      | Create(block) | Edit(block) =>
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
                  | "FragmentDefinition" => false
                  | _ => true
                  }
                })
                ->Belt.Array.length

              Js.log3("Initial block: ", initialAst.name.value, initial.id)

              let blocks = ast.definitions->Belt.Array.mapWithIndex((_idx, definition) => {
                let kind = switch Obj.magic(definition)["kind"] {
                | "FragmentDefinition" => #fragment
                | _ => definition.operation
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

                let sameOperationAsInitial = switch (sameNameAsInitial, sameOperationKindChanged) {
                | (false, false) => false
                | (true, _)
                | (_, true) => true
                }

                Js.log4(
                  "sameOperationAsInitial",
                  sameNameAsInitial,
                  sameOperationKindChanged,
                  definition.name.value,
                )

                let services =
                  definition
                  ->Obj.magic
                  ->GraphQLUtils.gatherAllReferencedServices(~schema)
                  ->Belt.Array.map(service => service.slug)

                let blank = makeBlankBlock()

                let title = definition.name.value->Obj.magic->Belt.Option.getWithDefault("Untitled")

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
                  },
                }

                block
              })

              try {
                setState(oldState => {
                  let newChain = blocks->Belt.Array.reduce(oldState.chain, (newChain, block) => {
                    switch block.kind {
                    | Fragment => {
                        ...newChain,
                        blocks: newChain.blocks
                        ->Belt.Array.keep(existingBlock => existingBlock.id != block.id)
                        ->Belt.Array.concat([block]),
                      }
                    | _ =>
                      let doc = block.body->GraphQLJs.parse
                      let definition = doc
                      let variableNames = doc.definitions[0]->GraphQLUtils.getOperationVariables

                      let variableDependencies = variableNames->Belt.Array.map(((
                        variableName,
                        _variableType,
                      )) => {
                        let argDep: Chain.variableDependencyKind = ArgumentDependency({
                          fromRequestIds: [],
                          maxRecur: None,
                          ifMissing: #SKIP,
                          ifList: #FIRST,
                          functionFromScript: "",
                          name: variableName,
                        })

                        let variableDep: Chain.variableDependencyKind = Direct({
                          {name: variableName, value: Variable(variableName)}
                        })

                        let defaultNewDependency = switch true {
                        | false => argDep
                        | true => variableDep
                        }

                        let varDep: Chain.variableDependency = {
                          name: variableName,
                          dependency: defaultNewDependency,
                        }

                        varDep
                      })

                      let newReq: Chain.request = {
                        id: block.title,
                        operation: block,
                        variableDependencies: variableDependencies,
                        dependencyRequestIds: [],
                      }

                      Js.log4(
                        "NewReq VarDeps: ",
                        definition,
                        variableNames,
                        newReq.variableDependencies,
                      )

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

                  let inspected: Inspector.inspectable = switch oldState.inspected {
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
    </div>
  }
}

@react.component
let make = (~schema, ~initialChain: Chain.t, ~config) => {
  <ReactFlow.Provider> <Main schema initialChain config /> </ReactFlow.Provider>
}
