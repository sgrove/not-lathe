module Fragment = %relay(`
  fragment ChainEditor_oneGraphAppPackageChain on OneGraphAppPackageChain {
    id
    name
    description
    libraryScript {
      id
      filename
      language
      concurrentSource
      textualSource
      ...ScriptEditor_source
    }
    createdAt
    updatedAt
    actions {
      id
      name
      description
      graphQLOperation
      privacy
      script {
        id
        filename
        language
        concurrentSource
        textualSource
        ...ScriptEditor_source
      }
      ...ActionGraphQLEditor_oneGraphStudioChainAction
    }
    ...ChainCanvas_oneGraphAppPackageChain
    ...Inspector_oneGraphAppPackageChain
  }`)

let httpRequest = `
type OutgoingHttpResponse {
  body: String
  headers: [[String!]!]
  status: Int!
}`

type actionEditState = Nothing | Create(Card.block) | Edit(string)

type scriptEditor = {
  isOpen: bool,
  editor: option<BsReactMonaco.editor>,
  monaco: option<BsReactMonaco.monaco>,
}

type debuggable =
  | Chain
  | CompiledChain

type state = {
  card: option<Card.block>,
  schema: GraphQLJs.schema,
  chainResult: option<Js.Json.t>,
  scriptFunctions: array<string>,
  chainExecutionResults: option<Js.Json.t>,
  actions: array<Card.block>,
  inspected: Inspector.inspectable,
  actionEditState: actionEditState,
  actionSearchOpen: bool,
  scriptEditor: scriptEditor,
  savedChainId: option<string>,
  requestValueCache: RequestValueCache.t,
  debugUIItems: array<debuggable>,
  connectionDrag: ConnectionContext.connectionDrag,
  subscriptionClient: option<OneGraphSubscriptionClient.t>,
  trace: option<Chain.Trace.t>,
  insight: Babel.Insight.insight,
}

let namedGraphQLScalarTypeScriptType = typ => {
  switch typ {
  | "ID"
  | "String" => "string"
  | "Int"
  | "Float" => "number"
  | "JSON" => "any"
  | other => other
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

let chainResultToRequestValueCache = (chainExecutionResults): RequestValueCache.t => {
  let requestValueCache = Obj.magic(
    chainExecutionResults,
  )["data"]["oneGraph"]["executeChain"]["results"]->Belt.Array.reduce(Js.Dict.empty(), (
    acc,
    next,
  ) => {
    let reqId = next["request"]["id"]
    let result = next["result"]->Belt.Array.get(0)->Belt.Option.flatMap(Js.Null_undefined.toOption)
    switch result {
    | None => ()
    | Some(result) => acc->Js.Dict.set(reqId, result)
    }
    acc
  })

  requestValueCache
}

let persistChain = (~config: Config.Studio.t, ~schema, ~authToken as _, ~chain, ~onComplete) => {
  let appId = config.oneGraphAppId
  let webhookUrl = Compiler.Exports.webhookUrlForAppId(~appId=config.oneGraphAppId)
  let compiled = chain->Compiler.transformChain(~schema, ~webhookUrl)
  let targetChain = compiled.chains->Belt.Array.getUnsafe(0)
  let freeVariables = targetChain.exposedVariables->Belt.Array.map(exposed => exposed.exposedName)

  OneGraphRe.persistQuery(
    ~appId,
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

          chain->Chain.saveToLocalStorage
          onComplete(docId)
        } catch {
        | ex => Js.Console.error2("Error saving chain locally", ex)
        }
      }
    },
  )
}

module Main = {
  @react.component
  let make = (
    ~schema,
    ~initialChain: ChainEditor_oneGraphAppPackageChain_graphql.Types.fragment,
    ~localStorageChain: Chain.t,
    ~config: Config.Studio.t,
    ~oneGraphAuth: OneGraphAuth.t,
    ~onSaveChain,
    ~onClose,
    ~onSaveAndClose as _,
    ~trace as initialTrace: option<Chain.Trace.t>,
    ~helpOpen: bool,
  ) => {
    open React
    let (_missingAuthServices, setMissingAuthServices) = useState(() => [])

    let (state, setState) = useState(() => {
      let scriptFunctions = try {
        let parsedScript = Acorn.parse(
          localStorageChain.script,
          Acorn.parseOptions(~ecmaVersion=2020, ~sourceType=#"module", ()),
        )

        let functionNames = Acorn.collectExportedFunctionNames(parsedScript)
        functionNames
      } catch {
      | _ => []
      }

      let inspected: Inspector.inspectable = Nothing
      // Action((localStorageChain.requests->Belt.Array.get(1)->Belt.Option.getExn).id)
      // Block(Card.blocks[0])

      {
        actionSearchOpen: false,
        card: Some(Card.watchTwitterFollower),
        schema: schema,
        chainResult: None,
        scriptFunctions: scriptFunctions,
        inspected: inspected,
        actionEditState: Nothing,
        actions: Card.blocks,
        scriptEditor: {
          isOpen: true,
          monaco: None,
          editor: None,
        },
        chainExecutionResults: None,
        savedChainId: None,
        requestValueCache: RequestValueCache.make(),
        debugUIItems: [],
        connectionDrag: Empty,
        subscriptionClient: None,
        insight: {
          store: Babel.Insight.createRecordStore(),
          latestRunId: 0,
          previousRunId: -1,
        },
        trace: initialTrace,
      }
    })

    useEffect0(() => {
      let _options = OneGraphSubscriptionClient.clientOptions(~oneGraphAuth, ())
      // Uncomment when OG supports chain subscriptions over websockets
      // let client = OneGraphSubscriptionClient.makeClient(
      //   ~appId=config.oneGraphAppId,
      //   ~options,
      //   ~webSocketImpl=None,
      // )

      // setState(oldState => {...oldState, subscriptionClient: Some(client)})

      Some(
        () => {
          ()
          // client->OneGraphSubscriptionClient.unsubscribeAll
        },
      )
    })

    let selectRequestFunctionScript = (~actionId) => {
      let request = initialChain.actions->Belt.Array.getBy(action => {
        actionId == action.id
      })

      request->Belt.Option.forEach(request => {
        let names = request.name->Chain.requestScriptNames
        let functionName = names.functionName

        let source = initialChain.libraryScript->Belt.Option.flatMap(script => script.textualSource)

        source->Belt.Option.forEach(source => {
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

    let {fitView} = ReactFlow.useZoomPanHelper()

    let onInspectAction = (~actionId) => {
      let inspected: Inspector.inspectable = Inspector.Action(actionId)

      setState(oldState => {...oldState, inspected: inspected})
    }

    useEffect1(() => {
      initialChain.actions->Belt.Array.length > 3
        ? fitView({
            padding: 0.2,
            includeHiddenNodes: false,
          })
        : ()
      None
    }, [initialChain.actions->Belt.Array.length])

    let definitionResultData = switch state.trace {
    | None => state.requestValueCache
    | Some(trace) =>
      let transformed = trace.trace->chainResultToRequestValueCache
      transformed
    }

    let onExecuteAction = (~request: Chain.request, ~variables, ~authToken) => {
      let ast = request.operation.body->GraphQLJs.parse
      let operationName = ast.definitions[0].name.value

      // TODO: Optimize to only send referenced fragments
      let chainFragments = ""

      let fullDoc = j`${request.operation.body}

${chainFragments}`->Js.String2.trim

      let oneGraphAuth =
        authToken
        ->Belt.Option.flatMap(authToken => {
          let tempAuth = OneGraphAuth.create(
            OneGraphAuth.createOptions(~saveAuthToStorage=false, ~appId=config.oneGraphAppId, ()),
          )
          tempAuth->Belt.Option.forEach(tempAuth => {
            let accessToken = {"accessToken": authToken}
            tempAuth->OneGraphAuth.setToken(Some(accessToken->Obj.magic))
          })
          tempAuth
        })
        ->Belt.Option.getWithDefault(oneGraphAuth)

      let promise = OneGraphRe.fetchOneGraph(
        oneGraphAuth,
        fullDoc,
        Some(operationName),
        Some(variables->Obj.magic),
      )

      promise->Js.Promise.then_(result => {
        setState(oldState => {
          oldState.requestValueCache->RequestValueCache.set(
            ~requestId=request.id,
            ~value=result->Obj.magic,
          )
          let newOne = oldState.requestValueCache->RequestValueCache.copy

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

        let blank = Card.makeBlankBlock(#query)

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

      let inspected =
        inspectedReq.contents
        ->Belt.Option.map(request => Inspector.Action(request.id))
        ->Belt.Option.getWithDefault(state.inspected)

      setState(oldState => {
        ...oldState,
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

      let newScript =
        Compiler.ScriptHelpers.deleteRequestFunctionIfEmpty(
          ~script=oldChain.script,
          ~request=targetRequest,
          (),
        )
        ->Belt.Result.getWithDefault(oldChain.script)
        ->Js.String2.trim

      let newChain = {
        ...oldChain,
        script: newScript,
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

    let (persistScript, isPersistingScript) = ScriptEditor.UpdateScriptMutation.use()

    React.useEffect1(() => {
      switch initialChain.libraryScript {
      | Some({filename, concurrentSource: Some(_)}) =>
        Js.log(j`Script source already bootstrapped for ${filename}`)
      | _ =>
        Js.log("Should initialize empty source")
        // This is a temporary document we create just to populate the fields on the server
        let ydocument = Yjs.createDocument()
        let ytext = ydocument->Yjs.Document.getText("monaco")
        ytext->Yjs.Document.Text.insert(0, j`// Let's get started!`)
        let b64 = ydocument->Yjs.encodeStateAsUpdate->SharedRooms.encodeUint8Array

        let persistScript = (ydocument, ~onCompleted) => {
          let concurrentSource = ydocument->Yjs.encodeStateAsUpdate->SharedRooms.encodeUint8Array
          let textualSource = ydocument->Yjs.Document.getText("monaco")->Yjs.Document.Text.toString
          Debug.assignToWindowForDeveloperDebug(~name="ydoc", ydocument)

          let r: RescriptRelay.Disposable.t = persistScript(
            ~variables={
              input: {
                id: "ee423369-0e69-443b-91c2-0b0112da8943",
                source: {
                  textualSource: textualSource,
                  concurrentSource: concurrentSource,
                },
              },
            },
            ~onCompleted,
            (),
          )

          r->ignore
        }
        ydocument->persistScript(~onCompleted=(_, _) => {
          Js.log(j`Bootsrapped contents for file`)
        })
      }

      None
    }, [initialChain.libraryScript->Belt.Option.map(script => script.id)])

    let scriptEditor = initialChain.libraryScript->Belt.Option.mapWithDefault(
      {"Loading script..."->string},
      script =>
        <ScriptEditor
          schema={state.schema}
          script={script.fragmentRefs}
          insight={Ok(state.insight)}
          chainName={initialChain.name}
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
            ()
          }}
        />,
    )

    let actionSearch =
      <ActionSearch
        onInspect={_ => {
          ()
          //   block => {
          //   setState(oldState => {...oldState, inspected: Block(block)})
          // }
        }}
        onAdd={_ => ()}
        // addBlock

        onCreate={kind => {
          setState(oldState => {
            ...oldState,
            actionEditState: Create(Card.makeBlankBlock(kind)),
          })
        }}
        onClose={() => {
          setState(oldState => {
            ...oldState,
            actionSearchOpen: false,
          })
        }}
      />

    let sidebar = {
      <Inspector
        fragmentRefs={initialChain.fragmentRefs}
        inspected={state.inspected}
        onClose
        schema={state.schema}
        onInspectAction
        oneGraphAuth
        onDeleteEdge={(~targetRequestId, ~dependencyId) => {
          ()
        }}
        onPotentialVariableSourceConnect
        requestValueCache={state.requestValueCache}
        onReset={() => {
          setState(oldState => {
            ...oldState,
            inspected: Nothing,
          })
        }}
        onInspectActionCode={(~actionId) => {
          selectRequestFunctionScript(~actionId)
        }}
        chainExecutionResults={state.chainExecutionResults}
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
      />
    }

    <div style={ReactDOMStyle.make(~height="calc(100vh - 56px)", ())}>
      <RequestValueCacheProvider value={definitionResultData}>
        <InspectedContextProvider value={Some(state.inspected)}>
          <ConnectionContext.Provider value={state.connectionDrag}>
            <div className="flex flex-row flex-nowrap">
              {state.actionSearchOpen
                ? <ReactResizePanel
                    direction=#e
                    style={ReactDOMStyle.make(~width="400px", ())}
                    handleClass="ResizeHandleHorizontal">
                    <div
                      className="w-full"
                      style={ReactDOMStyle.make(
                        ~backgroundColor=Comps.colors["gray-9"],
                        ~height="calc(100vh - 56px)",
                        (),
                      )}>
                      {actionSearch}
                    </div>
                  </ReactResizePanel>
                : <div
                    className="cursor-pointer"
                    style={ReactDOMStyle.make(~width="25px", ~color="white", ())}
                    onClick={_ =>
                      setState(oldState => {
                        ...oldState,
                        actionSearchOpen: true,
                      })}>
                    {j`▹`->string}
                  </div>}
              <div className="flex-1 overflow-x-hidden">
                <div
                  style={ReactDOMStyle.make(~height="calc(50vh - 28px)", ())}
                  onDragEnter={event => {
                    event->ReactEvent.Mouse.stopPropagation
                    event->ReactEvent.Mouse.preventDefault

                    let dataTransfer = Obj.magic(event)["dataTransfer"]
                    dataTransfer["dropEffect"] = "copy"
                  }}
                  onDragOver={event => {
                    event->ReactEvent.Mouse.stopPropagation
                    event->ReactEvent.Mouse.preventDefault
                    let dataTransfer = Obj.magic(event)["dataTransfer"]
                    dataTransfer["dropEffect"] = "copy"
                  }}
                  onDrop={event => {
                    event->ReactEvent.Mouse.stopPropagation
                    let dataTransfer = Obj.magic(event)["dataTransfer"]
                    dataTransfer["dropEffect"] = "copy"
                    let blockId: string = dataTransfer["getData"]("text")

                    state.actions
                    ->Belt.Array.getBy(block => block.id->Uuid.toString == blockId)
                    ->Belt.Option.forEach(block => {
                      addBlock(block)
                    })
                  }}>
                  <ChainCanvas
                    chainRef={initialChain.fragmentRefs}
                    removeEdge
                    removeRequest
                    trace=state.trace
                    onActionInspected={actionId => {
                      setState(oldState => {...oldState, inspected: Action(actionId)})
                    }}
                    onEditAction={actionId => {
                      setState(oldState => {...oldState, actionEditState: Edit(actionId)})
                    }}
                  />
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
                      <div className="flex-grow">
                        {
                          let libraryScript: option<
                            ChainEditor_oneGraphAppPackageChain_graphql.Types.fragment_libraryScript,
                          > = initialChain.libraryScript

                          let filename: string = switch libraryScript {
                          | None => "Loading script..."
                          | Some(libraryScript) => libraryScript.filename
                          }

                          ("Chain JavaScript" ++ j`(${filename})`)->string
                        }
                      </div>
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
                            })
                          }}
                          title="Format code">
                          <Icons.Prettier.Dark height="16px" width="16px" />
                        </button>
                      </div>
                    </Comps.Header>
                  </div>
                  {scriptEditor}
                </div>
              </div>
              <ReactResizePanel
                direction=#w
                style={ReactDOMStyle.make(~width="400px", ())}
                handleClass="ResizeHandleHorizontal">
                <div
                  className="w-full"
                  style={ReactDOMStyle.make(
                    ~backgroundColor=Comps.colors["gray-9"],
                    ~height="calc(100vh - 56px)",
                    (),
                  )}>
                  {sidebar}
                </div>
              </ReactResizePanel>
            </div>
            {switch state.actionEditState {
            | Nothing => null
            | action =>
              let action = switch action {
              | Nothing
              | Create(_) =>
                None
              | Edit(actionId) =>
                initialChain.actions->Belt.Array.getBy(action => action.id == actionId)
              }

              let editor =
                <ActionGraphQLEditor
                  schema={state.schema}
                  actionRef={action->Belt.Option.map(action => action.fragmentRefs)}
                  availableFragments={[]}
                  onClose={() => {
                    setState(oldState => {...oldState, actionEditState: Nothing})
                  }}
                  onSave={(
                    ~initial: ActionGraphQLEditor.editableAction,
                    ~modified as superBlock: ActionGraphQLEditor.editableAction,
                  ) => {
                    //                     let ast = superBlock.body->GraphQLJs.parse
                    //                     let initialAst = (initial.body->GraphQLJs.parse).definitions[0]

                    //                     let newOperationDefinitionCount =
                    //                       ast.definitions
                    //                       ->Belt.Array.keep(definition => {
                    //                         switch Obj.magic(definition)["kind"] {
                    //                         | "FragmentDefinition"
                    //                         | "ObjectTypeDefinition" => false
                    //                         | _ => true
                    //                         }
                    //                       })
                    //                       ->Belt.Array.length

                    //                     let guessedInitialBlock = ref(None)

                    //                     let blocks = ast.definitions->Belt.Array.mapWithIndex((_idx, definition) => {
                    //                       let kind = switch Obj.magic(definition)["kind"] {
                    //                       | "FragmentDefinition" => #fragment
                    //                       | "ObjectTypeDefinition" => #objectType
                    //                       | _ => definition.operation
                    //                       }

                    //                       let definition = switch kind {
                    //                       | #objectType =>
                    //                         let compiled = definition->GraphQLJs.Mock.compileComputeToIdentityQuery
                    //                         Debug.assignToWindowForDeveloperDebug(
                    //                           ~name="computedCompiled",
                    //                           [definition->Obj.magic, compiled],
                    //                         )
                    //                         compiled
                    //                       | _ => definition
                    //                       }

                    //                       let sameNameAsInitial = initialAst.name.value == definition.name.value
                    //                       let sameOperationKindChanged = switch (
                    //                         newOperationDefinitionCount,
                    //                         initial.kind,
                    //                         kind,
                    //                       ) {
                    //                       | (0, Fragment, #fragment) => true
                    //                       | (1, _, #fragment) => false
                    //                       | (1, _, _) => true
                    //                       | _ => false
                    //                       }

                    //                       let sameOperationAsInitial = switch (
                    //                         sameNameAsInitial,
                    //                         sameOperationKindChanged,
                    //                       ) {
                    //                       | (false, false) => false
                    //                       | (true, _)
                    //                       | (_, true) => true
                    //                       }

                    //                       let services =
                    //                         definition
                    //                         ->Obj.magic
                    //                         ->GraphQLUtils.gatherAllReferencedServices(~schema)
                    //                         ->Belt.Array.map(service => service.slug)

                    //                       let blank = Card.makeBlankBlock(#query)

                    //                       let title =
                    //                         definition.name.value->Obj.magic->Belt.Option.getWithDefault("Untitled")

                    //                       let block = {
                    //                         ...blank,
                    //                         id: sameOperationAsInitial ? initial.id : Uuid.v4(),
                    //                         title: title,
                    //                         services: services,
                    //                         body: GraphQLJs.printAst(definition->Obj.magic),
                    //                         kind: switch kind {
                    //                         | #fragment => Fragment
                    //                         | #query => Query
                    //                         | #mutation => Mutation
                    //                         | #subscription => Subscription
                    //                         | #objectType => Compute
                    //                         },
                    //                       }

                    //                       switch (sameNameAsInitial, sameOperationKindChanged) {
                    //                       | (true, _) | (_, true) => guessedInitialBlock := Some(block)
                    //                       | _ => ()
                    //                       }

                    //                       block
                    //                     })

                    //                     try {
                    //                       setState(oldState => {
                    //                         let newChain = blocks->Belt.Array.reduce(oldState.chain, (
                    //                           newChain,
                    //                           block,
                    //                         ) => {
                    //                           switch block.kind {
                    //                           | Fragment => {
                    //                               ...newChain,
                    //                               blocks: newChain.blocks
                    //                               ->Belt.Array.keep(existingBlock => existingBlock.id != block.id)
                    //                               ->Belt.Array.concat([block]),
                    //                             }
                    //                           | _ =>
                    //                             let isLikelyInitialBlock = Some(block) == guessedInitialBlock.contents

                    //                             let initialReq = isLikelyInitialBlock
                    //                               ? newChain.requests->Belt.Array.getBy(request => {
                    //                                   request.operation.id == initial.id
                    //                                 })
                    //                               : None

                    //                             let doc = block.body->GraphQLJs.parse
                    //                             let definition = doc.definitions[0]
                    //                             let variableNames = definition->GraphQLUtils.getOperationVariables

                    //                             let variableDependencies = variableNames->Belt.Array.map(((
                    //                               variableName,
                    //                               _variableType,
                    //                             )) => {
                    //                               let existingVarDep = initialReq->Belt.Option.flatMap(request =>
                    //                                 request.variableDependencies->Belt.Array.getBy(
                    //                                   existingVariableDependency => {
                    //                                     existingVariableDependency.name == variableName
                    //                                   },
                    //                                 )
                    //                               )

                    //                               let variableDep: Chain.variableDependencyKind = Direct({
                    //                                 {name: variableName, value: Variable(variableName)}
                    //                               })

                    //                               let varDep: Chain.variableDependency =
                    //                                 existingVarDep->Belt.Option.getWithDefault({
                    //                                   name: variableName,
                    //                                   dependency: variableDep,
                    //                                 })

                    //                               varDep
                    //                             })

                    //                             let newReq: Chain.request = {
                    //                               id: block.title,
                    //                               operation: block,
                    //                               variableDependencies: variableDependencies,
                    //                               dependencyRequestIds: initialReq->Belt.Option.mapWithDefault(
                    //                                 [],
                    //                                 req => req.dependencyRequestIds,
                    //                               ),
                    //                             }

                    //                             let returnProperties =
                    //                               newReq.variableDependencies->Belt.Array.keepMap(varDep => {
                    //                                 switch varDep.dependency {
                    //                                 | ArgumentDependency(_) => Some((varDep.name, varDep.name))
                    //                                 | _ => None
                    //                                 }
                    //                               })

                    //                             let newScript: string = Inspector.ensureRequestFunctionExists(
                    //                               ~returnProperties,
                    //                               ~script=newChain.script,
                    //                               ~request=newReq,
                    //                               (),
                    //                             )

                    //                             let newChain: Chain.t = {
                    //                               ...newChain,
                    //                               name: newChain.name,
                    //                               id: newChain.id,
                    //                               description: newChain.description,
                    //                               scriptDependencies: newChain.scriptDependencies,
                    //                               blocks: newChain.blocks
                    //                               ->Belt.Array.keep(existingBlock => existingBlock.id != block.id)
                    //                               ->Belt.Array.concat([block]),
                    //                               requests: newChain.requests
                    //                               ->Belt.Array.keep(existingRequest =>
                    //                                 initialReq->Belt.Option.mapWithDefault(true, initialReq =>
                    //                                   existingRequest.id != initialReq.id
                    //                                 )
                    //                               )
                    //                               ->Belt.Array.concat([newReq]),
                    //                               script: newScript,
                    //                             }

                    //                             let newScript = {
                    //                               let {dDotTs: _newTypes, importLine} = Chain.monacoTypelibForChain(
                    //                                 schema,
                    //                                 newChain,
                    //                               )

                    //                               let newImports = importLine

                    //                               let hasImport =
                    //                                 newScript
                    //                                 ->Js.String2.match_(
                    //                                   Js.Re.fromString("import[\s\S.]+from[\s\S]+'oneGraphStudio';"),
                    //                                 )
                    //                                 ->Belt.Option.isSome

                    //                               switch hasImport {
                    //                               | false =>
                    //                                 `${newImports}

                    // ${newScript}`
                    //                               | true =>
                    //                                 newScript->Js.String2.replaceByRe(
                    //                                   Js.Re.fromString("import[\s\S.]+from[\s\S]+'oneGraphStudio';"),
                    //                                   newImports,
                    //                                 )
                    //                               }
                    //                             }

                    //                             let newChain: Chain.t = {
                    //                               ...newChain,
                    //                               script: newScript,
                    //                             }

                    //                             newChain
                    //                           }
                    //                         })

                    //                         let newInitialBlock =
                    //                           newChain.blocks
                    //                           ->Belt.Array.getBy(block => block.id == initial.id)
                    //                           ->Belt.Option.getWithDefault(blocks[0])

                    //                         let newBlocks = blocks

                    //                         let allBlocks = switch oldState.actionEditState {
                    //                         | _ => oldState.actions->Belt.Array.concat(newBlocks)
                    //                         // | _ =>
                    //                         //   oldState.blocks->Belt.Array.keepMap(existingBlock => {
                    //                         //     Some(existingBlock.id == newBlock.id ? newBlock : existingBlock)
                    //                         //   })
                    //                         }

                    //                         let diagram = diagramFromChain(newChain)

                    //                         {
                    //                           ...oldState,
                    //                           chain: newChain,
                    //                           actionEditState: Nothing,
                    //                           diagram: diagram,
                    //                           actions: allBlocks,
                    //                         }
                    //                       })
                    //                     } catch {
                    //                     | _ => ()
                    //                     }

                    ()
                  }}
                />

              <Comps.Modal> {editor} </Comps.Modal>
            }}
          </ConnectionContext.Provider>
        </InspectedContextProvider>
      </RequestValueCacheProvider>
      {helpOpen
        ? <Comps.Modal>
            <div className="w-full h-full m-2 bg-gray-900">
              <h1 style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
                {"Draw connections with drag and drop:"->string}
              </h1>
              <ul style={ReactDOMStyle.make(~color=Comps.colors["gray-4"], ())}>
                {
                  let connectionsHelp =
                    Help.videoTutorials->Belt.Array.keep((video: Help.videoTutorialLink) =>
                      video.category == Connections
                    )

                  connectionsHelp
                  ->Belt.Array.map(video => {
                    <li key=video.title>
                      {video.oneLineDescription->string}
                      <a
                        href=video.link
                        target="_blank"
                        style={ReactDOMStyle.make(~color=Comps.colors["blue-1"], ())}>
                        {"[Tutorial video]"->string}
                      </a>
                    </li>
                  })
                  ->array
                }
              </ul>
            </div>
          </Comps.Modal>
        : null}
      <audio autoPlay=true id="test-audio-tag" />
    </div>
  }
}

@react.component
let make = (
  ~schema,
  ~chainRefs,
  ~localStorageChain: Chain.t,
  ~config: Config.Studio.t,
  ~onSaveChain,
  ~onClose,
  ~onSaveAndClose,
  ~trace: option<Chain.Trace.t>,
  ~helpOpen: bool,
) => {
  let oneGraphAuth = OneGraphAuth.create(
    OneGraphAuth.createOptions(
      ~appId=config.oneGraphAppId,
      ~oneGraphOrigin=?Config.isDev ? Some("https://serve.onegraph.io") : None,
      (),
    ),
  )

  let initialChain = Fragment.use(chainRefs)

  oneGraphAuth
  ->Belt.Option.map(oneGraphAuth => {
    <ReactFlow.Provider>
      <Main
        schema
        initialChain
        localStorageChain
        config
        oneGraphAuth
        onSaveChain
        onClose
        onSaveAndClose
        trace
        helpOpen
      />
    </ReactFlow.Provider>
  })
  ->Belt.Option.getWithDefault("Loading Chain Editor..."->React.string)
}
