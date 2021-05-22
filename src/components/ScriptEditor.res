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

@react.component
let make = (
  ~schema,
  ~script,
  ~functionName as _=?,
  ~onChange,
  ~className=?,
  ~onMount,
  ~onPotentialScriptSourceConnect,
  ~insight: result<Babel.Insight.insight, 'a>,
  ~chainName,
) => {
  let source = ScriptEditorFragment.use(script)
  let (persistScript, isPersistingScript) = UpdateScriptMutation.use()
  let (localContent, setLocalContent) = React.useState(() =>
    source.textualSource->Belt.Option.getWithDefault("")
  )
  let (contentWidgets, setContentWidgets) = React.useState(() => [])
  let ydocument = React.useRef(None)
  let editor = React.useRef(None)
  let monaco = React.useRef(None)
  let filename = j`file://${source.filename}`

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

  React.useEffect3(() => {
    switch (monaco.current, editor.current, source.concurrentSource) {
    | (Some(_monaco), Some(editor), Some(concurrentSource)) =>
      let sharedRoom = SharedRooms.idempotentCreate(
        ~name=chainName,
        ~concurrentSource,
        ~localUser={"name": "sgrove", "color": "#ffb61e"},
        (),
      )
      let text = sharedRoom.document->Yjs.Document.getText("monaco")

      let shouldConnect = sharedRoom.provider->Yjs.Provider.shouldConnect

      if shouldConnect {
        sharedRoom.provider->Yjs.Provider.connect
      }

      ydocument->React.Ref.setCurrent(Some(sharedRoom.document))

      let model = editor->BsReactMonaco.getModel(filename)
      let editors = Yjs.makeSet([editor])
      let _monacoBinding = Yjs.Monaco.createBinding(
        ~optimisticInitialText=text->Yjs.Document.Text.toString,
        ~yText=text,
        ~model,
        ~editors,
        ~awareness=sharedRoom.provider->Yjs.Provider.awareness,
      )
    | other => Js.log2("Delaying monaco binding... ", other)
    }

    None
  }, (monaco.current, editor.current, source.id))

  let (_highlights, setHighlights) = React.useState(() => [])

  // let {dDotTs: types} = Chain.monacoTypelibForChain(schema, deadChain)

  let connectionDrag = React.useContext(ConnectionContext.context)
  let connectionDragRef = React.useRef(connectionDrag)

  let audioStreamContext = React.useContext(AudioStreamContext.context)
  // let ((audioStreamPromise, audioStreamResolver), _) = React.useState(() => {
  //   let resolver = ref(None)
  //   let handler = (~resolve, ~reject as _) => {
  //     resolver := Some(resolve)
  //   }
  //   let promise = Js.Promise.make(handler)

  //   (promise, resolver.contents)
  // })

  // React.useEffect1(() => {
  //   switch audioStreamContext {
  //   | Empty => ()
  //   | Loaded(stream) => audioStreamResolver->Belt.Option.forEach(resolver => resolver(. stream))
  //   }

  //   None
  // }, [audioStreamContext])

  // React.useEffect4(() => {
  //   switch (insight, editor.current, monaco.current) {
  //   | (_, None, _)
  //   | (_, _, None)
  //   | (Error(_), _, _) => ()
  //   | (Ok({store, latestRunId}), Some(editor), Some(monaco)) =>
  //     let lines = content->Js.String2.split("\n")
  //     Debug.assignToWindowForDeveloperDebug(~name="MyRecordStore", store)
  //     let records =
  //       store->Babel.Insight.getGroupedLineDecorations(
  //         ~runId=latestRunId,
  //         ~filePath=source.filename,
  //         ~maxRecordLen=Some(1000),
  //         ~beforePosition=None,
  //       )

  //     let newContentWidgets = records->Belt.Array.map(result => {
  //       let adjustedLineNumber = result.lineNum - 1
  //       let horizontalOffset = switch lines
  //       ->Belt.Array.get(adjustedLineNumber)
  //       ->Belt.Option.mapWithDefault(0, Js.String2.length) {
  //       | 0 => 0
  //       | other => other + 2
  //       }

  //       BsReactMonaco.createWidget(
  //         ~monaco,
  //         ~lineNum=result.lineNum,
  //         ~hasError=result.hasError,
  //         ~horizontalOffset,
  //         ~content=result.content,
  //       )
  //     })

  //     contentWidgets->Belt.Array.forEach(contentWidget =>
  //       editor->BsReactMonaco.removeContentWidget(contentWidget)
  //     )

  //     newContentWidgets->Belt.Array.forEach(contentWidget =>
  //       editor->BsReactMonaco.addContentWidget(contentWidget)
  //     )

  //     setContentWidgets(_ => newContentWidgets)
  //   }

  //   None
  // }, (insight, content, editor.current, monaco.current))

  //   React.useEffect1(() => {
  //     connectionDragRef.current = connectionDrag
  //     switch (editor.current, monaco.current, connectionDrag) {
  //     | (Some(editor), Some(monaco), StartedSource(_)) =>
  //       TypeScript.VirtualFileSystem.makeWithFileSystem(~onCreateFileSystem=fsMap => {
  //         fsMap->TypeScript.Map.set("main.ts", deadChain.script)
  //       })
  //       ->Js.Promise.then_(
  //         ((_env, program, _typeChecker, _fsMap, _system)) => {
  //           let parsed = program["getSourceFile"]("main.ts")

  //           parsed
  //           ->Belt.Option.forEach(parsed => {
  //             let variableDeclarations = parsed->TypeScript.findAllVariableDeclarationsInFunctions

  //             let decorations = variableDeclarations->Belt.Array.map(node => {
  //               open TypeScript
  //               let start = parsed->getLineAndCharacterOfPosition(Obj.magic(node)["pos"])
  //               let end = parsed->getLineAndCharacterOfPosition(Obj.magic(node)["end"])

  //               open BsReactMonaco
  //               {
  //                 options: {
  //                   deltaDecorationOptions(
  //                     ~className="script-drop drag-target",
  //                     ~inlineClassName="script-drop drag-target",
  //                     (),
  //                   )
  //                 },
  //                 range: monaco->makeRange(
  //                   start.line + 1,
  //                   start.character + 1,
  //                   end.line + 1,
  //                   end.character + 1,
  //                 ),
  //               }
  //             })

  //             Debug.assignToWindowForDeveloperDebug(~name="OtherEditor", editor)
  //             Debug.assignToWindowForDeveloperDebug(~name="OtherMonaco", monaco)
  //             Debug.assignToWindowForDeveloperDebug(~name="OtherDecorations", decorations)

  //             let deltas = editor->BsReactMonaco.deltaDecorations([], decorations)

  //             setHighlights(_oldHighlights => deltas)
  //           })
  //           ->Js.Promise.resolve
  //         },
  //         /* * TODO extract type at point
  //             let position =
  //               parsed->TypeScript.getPositionOfLineAndCharacter(
  //                 scriptPosition.lineNumber - 1,
  //                 scriptPosition.column - 1,
  //               )

  //             TypeScript.findTypeOfVariableDeclarationAtPosition(
  //               ~env,
  //               ~fileName="main.ts",
  //               ~position,
  //             )->Belt.Option.forEach(((node, typeNode)) => {
  //               let printedType = TypeScript.printType(~typeChecker, ~typeNode, ~node, ())

  //               Js.log4("Type at position: ", typeNode, position, printedType)
  //             })
  //           })
  //  */

  //         _,
  //       )
  //       ->ignore
  //     | (Some(editor), _, _) =>
  //       setHighlights(oldHighlights => {
  //         let _ = editor->BsReactMonaco.deltaDecorations(oldHighlights, [])
  //         []
  //       })
  //     | _ => ()
  //     }

  //     None
  //   }, [connectionDrag->ConnectionContext.toSimpleString])

  // React.useEffect1(() => {
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

  //   React.useEffect1(() => {
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

  // React.useEffect3(() => {
  //   open BsReactMonaco
  //   monaco.current->Belt.Option.forEach(monaco => {
  //     editor.current->Belt.Option.forEach(editor => {
  //       let keyCode = {
  //         Key.combine([monaco->Key.mod->Key.ctrlCmd, monaco->Key.code->Key.keyS])
  //       }

  //       let _commandId = editor->addCommand(keyCode, () => {
  //         // onSaveChain(chain)

  //         ydocument
  //         ->React.Ref.current
  //         ->Belt.Option.forEach(ydocument =>
  //           ydocument->persistScript(~onCompleted=(_, _) => {
  //             Js.log("Finished persisting document")
  //           })
  //         )
  //       })
  //     })
  //   })

  //   None
  // }, (editor.current, monaco.current, deadChain))

  <div
    style={ReactDOMStyle.make(
      ~height="calc(100vh - 40px - 384px - 56px)",
      /* TODO: Figure this out: if overflowY is hidden, the page won't scroll, but the tooltips are cut off */
      // ~overflowY="hidden",
      (),
    )}>
    {isPersistingScript ? {"Saving..."->React.string} : React.null}
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
      path=filename
      onChange={(newScript, _) => {
        // setLocalContent(_ => newScript)
        // onChange(newScript)
        ()
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

        // let () = BsReactMonaco.TypeScript.addLib(. monacoInstance, types, content)
        let () = BsReactMonaco.registerPrettier(monacoInstance)
        let modelOptions = BsReactMonaco.Model.modelOptions(~tabSize=2, ())

        editorHandle
        ->BsReactMonaco.getModel(filename)
        ->BsReactMonaco.Model.updateOptions(modelOptions)

        editor.current = Some(editorHandle)
        monaco.current = Some(monacoInstance)

        onMount(~editor=editorHandle, ~monaco=monacoInstance)
      }}
    />
  </div>
}
