module ScriptEditorFragment = %relay(`
  fragment ScriptEditor_source on OneGraphSourceFile {
    id
    filename
    language
    concurrentSource
    textualSource
  }`)

module UpdateScriptMutation = %relay(`
  mutation ScriptEditor_OneGraphMutation(
    $input: OneGraphUpdateChainScriptInput!
  ) {
    oneGraph {
      updateChainScript(input: $input) {
        script {
          ...ScriptEditor_source
        }
      }
    }
  }
`)

let filenameWithExtension = (source: ScriptEditor_source_graphql.Types.fragment): string => {
  let extension = switch source.language {
  | #TYPESCRIPT => "ts"
  | future_tag =>
    Js.Console.warn2("Unrecognized language, defaulting to .js file: ", future_tag)
    "js"
  }

  source.filename
}

@react.component
let make = (~schema, ~script, ~functionName as _=?, ~className=?, ~onMount) => {
  let source = ScriptEditorFragment.use(script)
  let (persistScript, isPersistingScript) = UpdateScriptMutation.use()

  let (localContent, setLocalContent) = React.useState(() =>
    source.textualSource->Belt.Option.getWithDefault("")
  )
  let (models: Js.Dict.t<BsReactMonaco.Model.t>, setModels) = React.useState(() => Js.Dict.empty())
  let collaboration = React.useContext(CollaborationContext.context)
  let (contentWidgets, setContentWidgets) = React.useState(() => [])
  let ydocument = React.useRef(None)
  let editor = React.useRef(None)
  let monaco = React.useRef(None)
  let filename = j`file://${filenameWithExtension(source)}`

  let persistScript = (ydocument, ~onCompleted) => {
    let concurrentSource = ydocument->Yjs.encodeStateAsUpdate->CollaborationContext.encodeUint8Array
    let textualSource = ydocument->Yjs.Document.getText("monaco")->Yjs.Document.Text.toString
    Debug.assignToWindowForDeveloperDebug(~name="ydoc", ydocument)

    let r: RescriptRelay.Disposable.t = persistScript(
      ~variables={
        input: {
          id: source.id,
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

  React.useEffect0(() => {
    ()
    Some(
      () => {
        models->Js.Dict.values->Belt.Array.forEach(model => model->BsReactMonaco.Model.dispose)
      },
    )
  })

  let (yjsEditor, setYjsEditor) = React.useState(() => None)

  React.useEffect1(() => {
    switch editor.current {
    | None => ()
    | Some(editor) =>
      let editors = Yjs.makeSet([editor])
      setYjsEditor(_ => Some(editors))
    }
    None
  }, [editor.current])

  let hyperEval = (~script) => {
    let runId = Babel.insight.contents.latestRunId + 1
    Babel.insight := {...Babel.insight.contents, latestRunId: runId}
    let transpiled =
      script->Compiler.babelTranspile(~filename=j`/${filenameWithExtension(source)}`, ~runId)

    setLocalContent(_ => script)

    switch transpiled {
    | Ok(transpiled) =>
      let invocations = "// TODO: Add invocations here"
      let fullTransformed = {
        ...transpiled,
        code: transpiled.code ++ "\n\n" ++ invocations,
      }

      Js.log2("Hypereval: ", fullTransformed)

      Compiler.evalBabelInQuick(
        ~transformResult=fullTransformed,
        ~insight=Babel.insight.contents,
        ~onError=err => Js.Console.warn2("Error hyperevaling: ", err),
        ~onSuccess=(
          ~results: array<Babel.Insight.evaluationRecord>,
          ~store: Babel.Insight.recordStore,
        ) => {
          Babel.insight := {...Babel.insight.contents, store: store, previousRunId: runId - 1}
          Js.log4("Hypereval success: ", results, store, Babel.insight)
        },
      )
    | Error(err) => Js.Console.warn2("Error transpiling: ", err)
    }
  }

  React.useEffect2(() => {
    Js.log2("Setting up observer for ydocument", ydocument->React.Ref.current)
    let unsub = ref(None)

    ydocument
    ->React.Ref.current
    ->Belt.Option.forEach(document => {
      let text = document->Yjs.Document.getText("monaco")
      let observer = (_event, _origin) => {
        Js.log2("Detected change in document: ", source.filename)
        let script = text->Yjs.Document.Text.toString

        hyperEval(~script)
      }
      text->Yjs.Document.Text.observe(observer)
      unsub :=
        Some(
          () => {
            Js.log2("Unsubscribing from observer to ydoc", ydocument)
            text->Yjs.Document.Text.unobserve(observer)
          },
        )
    })

    unsub.contents
  }, (ydocument.current, source.id))

  open React

  useEffect3(() => {
    switch (monaco.current, editor.current, source.concurrentSource, source.textualSource) {
    | (Some(monaco), Some(editor), Some(concurrentSource), Some(textualSource)) =>
      switch collaboration.getSharedChannel(~id=source.id, ~concurrentSource) {
      | None => Js.log(j`Unable to get shared room for source.id: ${source.id}`)
      | Some(collaborationContext) =>
        let text = collaborationContext.document->Yjs.Document.getText("monaco")
        ydocument->Ref.setCurrent(Some(collaborationContext.document))

        let existingModel = switch models->Js.Dict.get(source.id) {
        | Some(model) => model
        | None =>
          Js.log3("Create model: ", filename, text->Yjs.Document.Text.toString)

          let model =
            monaco
            ->BsReactMonaco.Monaco.getEditor
            ->BsReactMonaco.createModel(
              ~value=textualSource,
              ~language=Some("typescript"),
              ~uri=filename,
            )

          setModels(oldModels => {
            oldModels->Js.Dict.set(source.id, model)
            oldModels
          })

          Js.log3("Setting model bindings: ", yjsEditor, text->Yjs.Document.Text.toString)
          let _monacoBinding = yjsEditor->Belt.Option.map(yjsEditor => {
            Yjs.Monaco.createBinding(
              ~yText=text,
              ~model,
              ~editors=yjsEditor,
              ~awareness=collaborationContext.provider->Yjs.Provider.awareness,
            )
          })
          model
        }

        Debug.assignToWindowForDeveloperDebug(~name="allModels", models)

        editor->BsReactMonaco.setModel(existingModel)
      }
    | other => Js.log2("Delaying monaco binding... ", other)
    }

    None
  }, (monaco.current, editor.current, source.id))

  let (_highlights, setHighlights) = useState(() => [])

  // let {dDotTs: types} = Chain.monacoTypelibForChain(schema, deadChain)

  let connectionDrag = useContext(ConnectionContext.context)
  let connectionDragRef = useRef(connectionDrag.value)

  useEffect3(() => {
    switch (editor.current, monaco.current) {
    | (None, _)
    | (_, None) =>
      Js.log4("Ignoring insight effect: ", Babel.insight, editor.current, monaco.current)
      ()
    | (Some(editor), Some(monaco)) =>
      let lines = editor->BsReactMonaco.getValue->Js.String2.split("\n")
      Debug.assignToWindowForDeveloperDebug(~name="MyRecordStore", Babel.insight.contents.store)

      let filePath = filenameWithExtension(source)

      let records =
        Babel.insight.contents.store->Babel.Insight.getGroupedLineDecorations(
          ~runId=Babel.insight.contents.latestRunId,
          ~filePath,
          ~maxRecordLen=Some(1000),
          ~beforePosition=None,
        )

      let newContentWidgets = records->Belt.Array.map(result => {
        let adjustedLineNumber = result.lineNum - 1
        let horizontalOffset = switch lines
        ->Belt.Array.get(adjustedLineNumber)
        ->Belt.Option.mapWithDefault(0, Js.String2.length) {
        | 0 => 0
        | other => other + 2
        }

        let widget = BsReactMonaco.createWidget(
          ~monaco,
          ~lineNum=result.lineNum,
          ~hasError=result.hasError,
          ~horizontalOffset,
          ~content=result.content,
        )

        widget
      })

      contentWidgets->Belt.Array.forEach(contentWidget =>
        editor->BsReactMonaco.removeContentWidget(contentWidget)
      )

      newContentWidgets->Belt.Array.forEach(contentWidget =>
        editor->BsReactMonaco.addContentWidget(contentWidget)
      )

      Js.log3("Rendering insight widgets: ", newContentWidgets, Babel.insight.contents.store)

      setContentWidgets(_ => newContentWidgets)
    }

    None
  }, (localContent, editor.current, monaco.current))

  useEffect1(() => {
    connectionDragRef.current = connectionDrag.value
    switch (editor.current, monaco.current, connectionDrag.value, source.textualSource) {
    | (Some(editor), Some(monaco), StartedSource(_), Some(textualSource)) =>
      TypeScript.VirtualFileSystem.makeWithFileSystem(
        ~mainFile=filenameWithExtension(source),
        ~onCreateFileSystem=(. fsMap) => {
          fsMap->TypeScript.Map.set(
            j`/index.ts`,
            "import * as X from './VariableTest4.ts'\n// Go for it!\nconsole.log(true)",
          )
          fsMap->TypeScript.Map.set(filenameWithExtension(source), textualSource)
        },
      )
      ->Js.Promise.then_(
        ((_env, program, _typeChecker, _fsMap, _system)) => {
          let parsed = source->filenameWithExtension->program["getSourceFile"]
          Js.log4("Parsed/program: ", parsed, program, _fsMap)

          parsed
          ->Belt.Option.forEach(parsed => {
            let variableDeclarations = parsed->TypeScript.findAllVariableDeclarationsInFunctions
            Js.log2("\tVarDecs: ", variableDeclarations)

            let decorations = variableDeclarations->Belt.Array.map(node => {
              open TypeScript
              let start = parsed->getLineAndCharacterOfPosition(Obj.magic(node)["pos"])
              let end = parsed->getLineAndCharacterOfPosition(Obj.magic(node)["end"])

              open BsReactMonaco
              {
                options: {
                  deltaDecorationOptions(
                    ~className="script-drop drag-target",
                    ~inlineClassName="script-drop drag-target",
                    (),
                  )
                },
                range: monaco->makeRange(
                  start.line + 1,
                  start.character + 1,
                  end.line + 1,
                  end.character + 1,
                ),
              }
            })

            Debug.assignToWindowForDeveloperDebug(~name="OtherEditor", editor)
            Debug.assignToWindowForDeveloperDebug(~name="OtherMonaco", monaco)
            Debug.assignToWindowForDeveloperDebug(~name="OtherDecorations", decorations)

            let deltas = editor->BsReactMonaco.deltaDecorations([], decorations)

            setHighlights(_oldHighlights => deltas)
          })
          ->Js.Promise.resolve
        },
        /* * TODO extract type at point
              let position =
                parsed->TypeScript.getPositionOfLineAndCharacter(
                  scriptPosition.lineNumber - 1,
                  scriptPosition.column - 1,
                )

              TypeScript.findTypeOfVariableDeclarationAtPosition(
                ~env,
                ~fileName="main.ts",
                ~position,
              )->Belt.Option.forEach(((node, typeNode)) => {
                let printedType = TypeScript.printType(~typeChecker, ~typeNode, ~node, ())

                Js.log4("Type at position: ", typeNode, position, printedType)
              })
            })
 */

        _,
      )
      ->ignore
    | (Some(editor), _, _, _) =>
      setHighlights(oldHighlights => {
        let _ = editor->BsReactMonaco.deltaDecorations(oldHighlights, [])
        []
      })
    | _ => ()
    }

    None
  }, [connectionDrag.value->ConnectionContext.toSimpleString])

  // useEffect1(() => {
  //   content == localContent
  //     ? ()
  //     : editor.current->Belt.Option.forEach(editor => {
  //         let position = editor->BsReactMonaco.getPosition

  //         let model = editor->BsReactMonaco.getModel(j`file://${source.filename}`)
  //         let fullRange = model->BsReactMonaco.Model.getFullModelRange
  //         let edit = BsReactMonaco.editOperation(~range=fullRange, ~text=content, ())
  //         editor->BsReactMonaco.executeEdits(
  //           Js.Nullable.return("externalContentChange"),
  //           ~edits=[edit],
  //         )
  //         editor->BsReactMonaco.setPosition(position)
  //       })

  //   None
  // }, [content])

  //   useEffect1(() => {
  //     monaco.current->Belt.Option.forEach(monaco => {
  //       let {dDotTs: newTypes, importLine} = Chain.monacoTypelibForChain(schema, deadChain)
  //       let () = BsReactMonaco.TypeScript.addLib(. monaco, newTypes, content)

  //       let newImports = importLine

  //       let hasImport =
  //         deadChain.script
  //         ->Js.String2.match_(Js.Re.fromString("import[\s\S.]+from[\s\S]+'oneGraphStudio';"))
  //         ->Belt.Option.isSome

  //       let newScript = hasImport
  //         ? deadChain.script->Js.String2.replaceByRe(
  //             Js.Re.fromString("import[\s\S.]+from[\s\S]+'oneGraphStudio';"),
  //             newImports,
  //           )
  //         : `${newImports}

  // ${deadChain.script}`

  //       onChange(newScript->Js.String2.trim)
  //     })

  //     None
  //   }, [types])

  useEffect3(() => {
    open BsReactMonaco

    monaco.current->Belt.Option.forEach(monaco => {
      editor.current->Belt.Option.forEach(editor => {
        let keyCode = {
          Key.combine([monaco->Key.mod->Key.ctrlCmd, monaco->Key.code->Key.keyS])
        }

        let _commandId = editor->addCommand(keyCode, () => {
          ydocument
          ->Ref.current
          ->Belt.Option.forEach(ydocument =>
            ydocument->persistScript(~onCompleted=(_, _) => {
              Js.log("Finished persisting document")
            })
          )
        })
      })
    })

    None
  }, (editor.current, monaco.current, source.id))

  let cssForAwareness = (~clientId, ~color) => {
    j`
.${clientId} {
  backgroundColor: ${color};
}

.yRemoteSelection-${clientId} {
  background-color: ${color};
}

.yRemoteSelectionHead-${clientId} {
  position: absolute;
  border-left: ${color} solid 2px;
  border-top: ${color} solid 2px;
  border-bottom: ${color} solid 2px;
  height: 100%;
  box-sizing: border-box;
}
.yRemoteSelectionHead-${clientId}::after {
  position: absolute;
  content: ' ';
  border: 3px solid ${color};
  border-radius: 4px;
  left: -4px;
  top: -5px;
}
`
  }

  let css =
    collaboration.getSharedChannelState(~id=source.id)
    ->Belt.Option.mapWithDefault([], ((_localClientId, states)) => {
      let entries = Obj.magic(states)["entries"](.)->Js.Array.from

      entries->Belt.Array.map(((
        clientId: Yjs.Awareness.clientId,
        presence: CollaborationContext.presence,
      )) => {
        let css = cssForAwareness(~clientId=clientId->Obj.magic, ~color=presence.color)
        css
      })
    })
    ->Js.Array2.joinWith("\n")
  <>
    <style id="collaboration-css" dangerouslySetInnerHTML={"__html": css} />
    <div
      style={ReactDOMStyle.make(
        ~height="calc(100vh - 40px - 384px - 56px)",
        /* TODO: Figure this out: if overflowY is hidden, the page won't scroll, but the tooltips are cut off */
        // ~overflowY="hidden",
        (),
      )}>
      {isPersistingScript ? {"Saving..."->string} : null}
      <BsReactMonaco.Editor
        ?className
        theme="vs-dark"
        language="typescript"
        // defaultValue={content}
        options={
          "minimap": {"enabled": false},
          // "automaticLayout": true,
          // "fixedOverflowWidgets": true,
          "contextmenu": false,
          "contextMenu": false,
        }
        height="100%"
        path="file:///tmp.txt"
        onChange={(newScript, _) => {
          // setLocalContent(_ => newScript)
          // onChange(newScript)
          hyperEval(~script=newScript)
        }}
        onMount={(editorHandle, monacoInstance) => {
          Debug.assignToWindowForDeveloperDebug(~name="myEditor", editorHandle)
          Debug.assignToWindowForDeveloperDebug(~name="myMonaco", monacoInstance)

          let _disposable = editorHandle->BsReactMonaco.onMouseUp(mouseEvent => {
            open ConnectionContext

            switch connectionDragRef.current {
            | Empty
            | Completed(_)
            | CompletedPendingVariable(_)
            | CompletedWithTypeMismatch(_)
            | StartedTarget(_) => ()
            | StartedSource({sourceActionId, sourceDom}) =>
              let position = mouseEvent["target"]["position"]
              let lineNumber = position["lineNumber"]
              let column = position["column"]

              let event = mouseEvent["event"]
              let mousePositionX = event["posx"]
              let mousePositionY = event["posy"]
              let mousePosition = (mousePositionX, mousePositionY)

              connectionDrag.onPotentialScriptSourceConnect(
                ~scriptId=source.id,
                ~sourceActionId,
                ~sourceDom,
                ~scriptPosition={lineNumber: lineNumber, column: column},
                ~mousePosition,
              )
            }
          })

          // let () = BsReactMonaco.TypeScript.addLib(. monacoInstance, types, content)
          let () = BsReactMonaco.registerPrettier(monacoInstance)
          let modelOptions = BsReactMonaco.Model.modelOptions(~tabSize=2, ())

          editorHandle
          ->BsReactMonaco.getModel(filename)
          ->BsReactMonaco.Model.updateOptions(modelOptions)

          editor->React.Ref.setCurrent(Some(editorHandle))
          monaco->React.Ref.setCurrent(Some(monacoInstance))

          Js.log4("Editor/Monaco mount: ", editor, monaco, filename)
          onMount(~editor=editorHandle, ~monaco=monacoInstance)
        }}
      />
    </div>
  </>
}
