module Fragment = %relay(`
  fragment ChainEditor_chain on OneGraphAppPackageChain {
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
      graphqlOperation
      graphqlOperationKind
      privacy
      upstreamActionIds
      services
      script {
        id
        filename
        language
        concurrentSource
        textualSource
        ...ScriptEditor_source
      }
      ...ActionGraphQLEditor_chainAction
    }
    ...ChainCanvas_chain
    ...Inspector_chain
    ...ConnectionVisualizer_chainActions
    ...Compiler_chain
  }`)

module Subscription = %relay(`
  subscription ChainEditorSubscription($chainId: String!) {
    oneGraph {
      studioChainUpdate(input: { chainId: $chainId }) {
        chain {
          ...ChainEditor_chain
        }
      }
    }
  }
`)

module AddActionDependencyIds = %relay(`
  mutation ChainEditor_AddActionDependencyIdsMutation(
    $input: OneGraphAddActionDependencyIdsInput!
  ) {
    oneGraph {
      addActionDependencyIds(input: $input) {
        action {
          ...ActionInspector_oneGraphStudioChainAction
        }
      }
    }
  }
`)

module CreateChainActionMutation = %relay(`
  mutation ChainEditor_createChainActionMutation(
    $input: OneGraphCreateChainActionInput!
  ) {
    oneGraph {
      createChainAction(input: $input) {
        chain {
          id
          ...ChainEditor_chain
        }
      }
    }
  }
`)

module UpdateChainActionMutation = %relay(`
  mutation ChainEditor_updateChainActionMutation(
    $input: OneGraphUpdateChainActionInput!
  ) {
    oneGraph {
      updateChainAction(input: $input) {
        chain {
          id
          ...ChainEditor_chain
        }
      }
    }
  }
`)

let httpRequest = `
type OutgoingHttpResponse {
  body: String
  headers: [[String!]!]
  status: Int!
}`

type actionEditState = Nothing | Create(ActionGraphQLEditor.editableAction) | Edit(string)

type scriptEditor = {
  isOpen: bool,
  editor: option<BsReactMonaco.editor>,
  monaco: option<BsReactMonaco.monaco>,
}

type debuggable =
  | Chain
  | CompiledChain

type minimalSourceEditor = {
  id: string,
  filename: string,
  concurrentSource: option<string>,
}

type state = {
  card: option<Card.block>,
  schema: GraphQLJs.schema,
  chainResult: option<Js.Json.t>,
  chainExecutionResults: option<Js.Json.t>,
  connectionDragState: ConnectionContext.connectionDrag,
  actions: array<Card.block>,
  inspected: Inspector.inspectable,
  actionEditState: actionEditState,
  actionSearchOpen: bool,
  scriptEditor: scriptEditor,
  savedChainId: option<string>,
  requestValueCache: RequestValueCache.t,
  debugUIItems: array<debuggable>,
  subscriptionClient: option<OneGraphSubscriptionClient.t>,
  trace: option<Chain.Trace.t>,
}

module InspectedContextProvider = {
  let context = React.createContext((None: option<Inspector.inspectable>))

  let provider = React.Context.provider(context)

  @react.component
  let make = (~value, ~children) => {
    React.createElement(provider, {"value": value, "children": children})
  }
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

  OneGraphRe.persistQuery(.
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
    ~initialChain: ChainEditor_chain_graphql.Types.fragment,
    ~config: Config.Studio.t,
    ~oneGraphAuth: OneGraphAuth.t,
    ~onClose,
    ~trace as initialTrace: option<Chain.Trace.t>,
    ~helpOpen: bool,
  ) => {
    open React
    let (_missingAuthServices, setMissingAuthServices) = useState(() => [])
    let (addDependencyId, isAddingDependencyId) = AddActionDependencyIds.use()
    let collaborationContext = useContext(CollaborationContext.context)

    let (state, setState) = useState(() => {
      let inspected: Inspector.inspectable = Nothing
      // Action((localStorageChain.requests->Belt.Array.get(1)->Belt.Option.getExn).id)
      // Block(Card.blocks[0])

      {
        actionSearchOpen: false,
        card: Some(Card.watchTwitterFollower),
        schema: schema,
        chainResult: None,
        inspected: inspected,
        actionEditState: Nothing,
        actions: Card.blocks,
        scriptEditor: {
          isOpen: true,
          monaco: None,
          editor: None,
        },
        chainExecutionResults: None,
        connectionDragState: Empty,
        savedChainId: None,
        requestValueCache: RequestValueCache.make(),
        debugUIItems: [],
        subscriptionClient: None,
        trace: initialTrace,
      }
    })

    let setDragState = (~connectionDrag) => {
      setState(oldState => {...oldState, connectionDragState: connectionDrag})
    }

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

    let connectSourceToTargetActions = {
      (~sourceActionId, ~targetActionId) => {
        let result: RescriptRelay.Disposable.t = addDependencyId(
          ~variables={
            input: {
              actionId: targetActionId,
              addActionDependencyIds: [sourceActionId],
            },
          },
          (),
        )
        result->ignore
      }
    }

    let compilerChain = Compiler.CompilerFragment.use(initialChain.fragmentRefs)

    Js.log3(
      "TS def for compiler chain: ",
      Compiler.typeScriptDefinition(~schema, compilerChain),
      compilerChain,
    )

    let onPotentialVariableSourceConnect = (~connectionDrag: ConnectionContext.connectionDrag) => {
      Js.log3(
        "onPotentialVariableSourceConnect, old=>new:  ",
        state.connectionDragState,
        connectionDrag,
      )
      setDragState(~connectionDrag)
      // Js.log2("onPotentialVariableSourceConnect", connectionDrag)
      // switch connectionDrag {
      // | ConnectionContext.CompletedPendingVariable({sourceActionId, targetActionId}) =>
      //   Js.log2("Adding source->target dep: ", (sourceActionId, targetActionId))
      // | _ => setDragState(~connectionDrag)
      // }
    }

    let onPotentialActionSourceConnect = (~connectionDrag: ConnectionContext.connectionDrag) => {
      Js.log3(
        "onPotentialActionSourceConnect, old=>new:  ",
        state.connectionDragState,
        connectionDrag,
      )
      let newConnectionDrag = switch connectionDrag {
      | Completed({sourceActionId, target: Action({targetActionId})}) =>
        connectSourceToTargetActions(~sourceActionId, ~targetActionId)
        ConnectionContext.Empty
      | _ => Empty
      }
      setDragState(~connectionDrag=newConnectionDrag)
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

    let onExecuteAction = (~actionId: string, ~variables, ~authToken) => {
      Js.log4("onExecuteAction: ", actionId, variables, authToken)
      let action = initialChain.actions->Belt.Array.getBy(action => action.id == actionId)

      action->Belt.Option.forEach(action => {
        let ast = action.graphqlOperation->GraphQLJs.parse
        let operationName = ast.definitions[0].name.value

        // TODO: Optimize to only send referenced fragments
        let chainFragments =
          initialChain.actions
          ->Belt.Array.keepMap(action =>
            switch action.graphqlOperationKind {
            | #FRAGMENT => Some(action.graphqlOperation)
            | _ => None
            }
          )
          ->Js.Array2.joinWith("\n\n")

        let fullDoc = j`${action.graphqlOperation}

${chainFragments}`->Js.String2.trim

        Js.log2("Config oneGraphAuth: ", oneGraphAuth)
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

        Js.log2("Used oneGraphAuth: ", oneGraphAuth)

        let promise = OneGraphRe.fetchOneGraph(.
          oneGraphAuth,
          fullDoc,
          Some(operationName),
          Some(variables->Obj.magic),
        )

        promise->Js.Promise.then_(result => {
          setState(oldState => {
            oldState.requestValueCache->RequestValueCache.set(
              ~requestId=actionId,
              ~value=result->Obj.magic,
            )
            let newOne = oldState.requestValueCache->RequestValueCache.copy

            {
              ...oldState,
              requestValueCache: newOne,
            }
          })->Js.Promise.resolve
        }, _)->ignore
      })
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

      let inspected: Inspector.inspectable =
        inspectedReq.contents
        ->Belt.Option.map(actionId => Inspector.Action(actionId))
        ->Belt.Option.getWithDefault(state.inspected)

      setState(oldState => {
        ...oldState,
        inspected: inspected,
      })
    }

    let removeRequest = (oldChain: Chain.t, targetActionId: Chain.request) => {
      let newRequests = oldChain.requests->Belt.Array.keepMap(request => {
        switch request.id == targetActionId.id {
        | true => None
        | false =>
          let varDeps = request.variableDependencies->Belt.Array.map(varDep => {
            let dependency = switch varDep.dependency {
            | ArgumentDependency(argDep) =>
              Chain.ArgumentDependency({
                ...argDep,
                fromRequestIds: argDep.fromRequestIds->Belt.Array.keep(id =>
                  id != targetActionId.id
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
              id != targetActionId.id
            ),
          }

          Some(newRequest)
        }
      })

      let newScript =
        Compiler.ScriptHelpers.deleteRequestFunctionIfEmpty(
          ~script=oldChain.script,
          ~request=targetActionId,
          (),
        )
        ->Belt.Result.getWithDefault(oldChain.script)
        ->Js.String2.trim

      let newChain = {
        ...oldChain,
        script: newScript,
        requests: newRequests,
        blocks: oldChain.blocks->Belt.Array.keep(oldBlock => oldBlock != targetActionId.operation),
      }

      newChain
    }

    let removeEdge = (oldChain: Chain.t, ~dependencyId, ~targetActionIdId) => {
      let newRequests = oldChain.requests->Belt.Array.map(request => {
        switch request.id == targetActionIdId {
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

    let (createChainAction, isCreatingChainAction) = CreateChainActionMutation.use()
    let (updateChainAction, isUpdatingChainAction) = UpdateChainActionMutation.use()

    let (editingSource, editingSourceFragmentRefs) = {
      let default = (
        {
          id: initialChain.libraryScript.id,
          filename: initialChain.libraryScript.filename,
          concurrentSource: initialChain.libraryScript.concurrentSource,
        },
        initialChain.libraryScript.fragmentRefs,
      )
      switch state.inspected {
      | Action(actionId) =>
        initialChain.actions
        ->Belt.Array.getBy(action => action.id == actionId)
        ->Belt.Option.mapWithDefault(default, action => {
          (
            {
              id: action.script.id,
              filename: action.script.filename,
              concurrentSource: action.script.concurrentSource,
            },
            action.script.fragmentRefs,
          )
        })
      | Nothing
      | _ => default
      }
    }

    React.useEffect1(() => {
      switch editingSource {
      | {filename, concurrentSource: Some(_)} =>
        Js.log2(j`Script source already bootstrapped for ${filename}`, editingSource)
      | {id} =>
        Js.log("Should initialize empty source")
        // This is a temporary document we create just to populate the fields on the server
        let ydocument = Yjs.createDocument()
        let ytext = ydocument->Yjs.Document.getText("monaco")
        ytext->Yjs.Document.Text.insert(0, j`// Let's get started!`)

        let persistScript = (ydocument, ~onCompleted) => {
          let concurrentSource =
            ydocument->Yjs.encodeStateAsUpdate->CollaborationContext.encodeUint8Array
          let textualSource = ydocument->Yjs.Document.getText("monaco")->Yjs.Document.Text.toString
          Debug.assignToWindowForDeveloperDebug(~name="ydoc", ydocument)

          let r: RescriptRelay.Disposable.t = persistScript(
            ~variables={
              input: {
                id: id,
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
          Js.log(j`Bootstrapped contents for file`)
        })
      }

      None
    }, [editingSource.id])

    useEffect2(() => {
      switch editingSource.concurrentSource {
      | None =>
        Js.log2(
          "Unable to get shared channel for chain with empty concurrent source",
          initialChain.id,
        )
      | Some(concurrentSource) =>
        let channel = collaborationContext.getSharedChannel(~id=initialChain.id, ~concurrentSource)
        switch channel {
        | None => Js.log2("No shared channel for ", initialChain.id)
        | Some(_) => Js.log2("Got shared channel for chain: ", initialChain.id)
        }
      }

      None
    }, (editingSource.id, editingSource.concurrentSource))

    let scriptEditor =
      <ScriptEditor
        schema={state.schema}
        script={editingSourceFragmentRefs}
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
      />

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
            actionEditState: Create(ActionGraphQLEditor.makeBlankAction(kind)),
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
        onExecuteAction
        schema={state.schema}
        onInspectAction
        oneGraphAuth
        onPotentialVariableSourceConnect
        requestValueCache={state.requestValueCache}
        onReset={() => {
          setState(oldState => {
            ...oldState,
            inspected: Nothing,
          })
        }}
        onInspectActionCode={(~actionId) => {
          Js.log2("Should load up code for action: ", actionId)
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
          <ConnectionContext.Provider
            value={{
              ConnectionContext.onDragStart: (~connectionDrag) => {
                switch connectionDrag {
                | StartedSource({sourceActionId}) =>
                  collaborationContext.updateConnectSourceActionId(
                    ~channelId=initialChain.id,
                    ~sourceActionId=Some(sourceActionId),
                  )
                | _ => ()
                }
                setDragState(~connectionDrag)
              },
              onPotentialScriptSourceConnect: (
                ~scriptId,
                ~sourceActionId,
                ~sourceDom,
                ~scriptPosition: ConnectionContext.scriptPosition,
                ~mousePosition as (x, y): (int, int),
              ) => {
                let connectionDrag = ConnectionContext.Completed({
                  sourceActionId: sourceActionId,
                  target: Script({scriptId: scriptId, scriptPosition: scriptPosition}),
                  windowPosition: (x, y),
                  sourceDom: sourceDom,
                })

                setDragState(~connectionDrag)
              },
              onPotentialVariableSourceConnect: onPotentialVariableSourceConnect,
              onPotentialActionSourceConnect: onPotentialActionSourceConnect,
              value: state.connectionDragState,
              onDragEnd: () => {
                collaborationContext.updateConnectSourceActionId(
                  ~channelId=initialChain.id,
                  ~sourceActionId=None,
                )
                setState(oldState => {
                  ...oldState,
                  connectionDragState: switch oldState.connectionDragState {
                  | CompletedPendingVariable(_)
                  | Completed(_) =>
                    oldState.connectionDragState
                  | _ => Empty
                  },
                })
              },
            }}>
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
                    onConnect=connectSourceToTargetActions
                    onActionInspected={actionId => {
                      setState(oldState => {...oldState, inspected: Action(actionId)})
                    }}
                    onSelectionCleared={() => {
                      setState(oldState => {...oldState, inspected: Nothing})
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
                        {j`Chain JavaScript (${editingSource.filename})`->string}
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
            | Create(action) =>
              let editor =
                <ActionGraphQLEditor.Creator
                  schema={state.schema}
                  availableFragments={[]}
                  onClose={() => {
                    setState(oldState => {...oldState, actionEditState: Nothing})
                  }}
                  onSave={(
                    ~initial as _: ActionGraphQLEditor.editableAction,
                    ~modified: ActionGraphQLEditor.editableAction,
                  ) => {
                    try {
                      let opDoc = modified.graphqlOperation->GraphQLJs.parse

                      let variables =
                        opDoc.definitions
                        ->Belt.Array.getExn(0)
                        ->GraphQLUtils.getOperationVariables
                        ->Belt.Array.map(((
                          name,
                          typ,
                        )): ChainEditor_createChainActionMutation_graphql.Types.oneGraphCreateChainActionSubVariableInput => {
                          {
                            probePath: [],
                            method_: #COMPUTED,
                            maxRecur: 0,
                            ifList: #FIRST,
                            ifMissing: #ERROR,
                            graphqlType: typ,
                            description: None,
                            name: name,
                          }
                        })

                      let result: RescriptRelay.Disposable.t = createChainAction(
                        ~variables={
                          input: {
                            chainId: initialChain.id,
                            services: [],
                            graphqlOperationKind: modified.kind,
                            graphqlOperation: modified.graphqlOperation,
                            description: None,
                            name: modified.name,
                            variables: variables,
                          },
                        },
                        ~onCompleted=(_, _) => {
                          setState(oldState => {...oldState, actionEditState: Nothing})
                        },
                        (),
                      )
                      result->ignore
                    } catch {
                    | exn => Js.Console.warn2("Exception trying to create action", exn)
                    }
                  }}
                />

              <Comps.Modal> {editor} </Comps.Modal>

            | Edit(actionId) =>
              initialChain.actions
              ->Belt.Array.getBy(action => action.id == actionId)
              ->Belt.Option.mapWithDefault(null, action => {
                let editor =
                  <ActionGraphQLEditor
                    schema={state.schema}
                    actionRef={action.fragmentRefs}
                    availableFragments={[]}
                    onClose={() => {
                      setState(oldState => {...oldState, actionEditState: Nothing})
                    }}
                    onSave={(
                      ~initial as _: ActionGraphQLEditor.editableAction,
                      ~modified: ActionGraphQLEditor.editableAction,
                    ) => {
                      try {
                        let opDoc = modified.graphqlOperation->GraphQLJs.parse
                        let name =
                          opDoc
                          ->GraphQLJs.operationNames
                          ->Belt.Array.get(0)
                          ->Belt.Option.getWithDefault("Untitled")

                        let services =
                          opDoc.definitions
                          ->Belt.Array.map(definition =>
                            definition
                            ->Obj.magic
                            ->GraphQLUtils.gatherAllReferencedServices(~schema)
                            ->Belt.Array.map(service => service.slug)
                          )
                          ->Belt.Array.concatMany

                        let result: RescriptRelay.Disposable.t = updateChainAction(
                          ~variables={
                            input: {
                              id: actionId,
                              upstreamActionIds: action.upstreamActionIds,
                              services: services,
                              graphqlOperation: modified.graphqlOperation,
                              description: action.description,
                              name: name,
                            },
                          },
                          ~onCompleted=(_, _) => {
                            setState(oldState => {...oldState, actionEditState: Nothing})
                          },
                          (),
                        )

                        result->ignore
                      } catch {
                      | exn => Js.Console.warn2("Error updating action: ", exn)
                      }
                    }}
                  />

                <Comps.Modal> {editor} </Comps.Modal>
              })
            }}
            <ConnectionVisualizer chainRef={initialChain.fragmentRefs} />
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
    </div>
  }
}

@react.component
let make = (
  ~schema,
  ~chainRefs,
  ~config: Config.Studio.t,
  ~onClose,
  ~trace: option<Chain.Trace.t>,
  ~helpOpen: bool,
) => {
  let environment = RescriptRelay.useEnvironmentFromContext()

  let initialChain = Fragment.use(chainRefs)

  React.useEffect0(() => {
    let subscription = Subscription.subscribe(
      ~environment,
      ~variables={chainId: initialChain.id},
      ~onNext=_data => {
        ()
      },
      (),
    )

    Some(
      () => {
        Js.log("Tearing down subscription...")
        RescriptRelay.Disposable.dispose(subscription)
      },
    )
  })

  let (oneGraphAuth, _) = React.useState(() => {
    OneGraphAuth.create(
      OneGraphAuth.createOptions(
        ~appId=RelayEnv.appId,
        ~oneGraphOrigin=?Config.isDev ? Some("https://serve.onegraph.io") : None,
        (),
      ),
    )
  })

  oneGraphAuth
  ->Belt.Option.map(oneGraphAuth => {
    <ReactFlow.Provider>
      <Main schema initialChain config oneGraphAuth onClose trace helpOpen />
    </ReactFlow.Provider>
  })
  ->Belt.Option.getWithDefault("Loading Chain Editor..."->React.string)
}
