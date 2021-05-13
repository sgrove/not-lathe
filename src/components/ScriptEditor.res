@react.component
let make = (
  ~schema,
  ~chain: Chain.t,
  ~functionName as _=?,
  ~onChange,
  ~className=?,
  ~onMount,
  ~onPotentialScriptSourceConnect,
  ~onSaveChain,
  ~insight: result<Babel.Insight.insight, 'a>,
) => {
  let (localContent, setLocalContent) = React.useState(() => chain.script)
  let (_highlights, setHighlights) = React.useState(() => [])
  let (contentWidgets, setContentWidgets) = React.useState(() => [])
  let content = chain.script

  let editor = React.useRef(None)
  let monaco = React.useRef(None)

  let {dDotTs: types} = Chain.monacoTypelibForChain(schema, chain)

  let connectionDrag = React.useContext(ConnectionContext.context)
  let connectionDragRef = React.useRef(connectionDrag)

  let audioStreamContext = React.useContext(AudioStreamContext.context)
  let ((audioStreamPromise, audioStreamResolver), _) = React.useState(() => {
    let resolver = ref(None)
    let handler = (~resolve, ~reject as _) => {
      resolver := Some(resolve)
    }
    let promise = Js.Promise.make(handler)

    (promise, resolver.contents)
  })

  React.useEffect1(() => {
    switch audioStreamContext {
    | Empty => ()
    | Loaded(stream) => audioStreamResolver->Belt.Option.forEach(resolver => resolver(. stream))
    }

    None
  }, [audioStreamContext])

  React.useEffect4(() => {
    switch (insight, editor.current, monaco.current) {
    | (_, None, _)
    | (_, _, None)
    | (Error(_), _, _) => ()
    | (Ok({store, latestRunId}), Some(editor), Some(monaco)) =>
      let lines = content->Js.String2.split("\n")
      Debug.assignToWindowForDeveloperDebug(~name="MyRecordStore", store)
      let records =
        store->Babel.Insight.getGroupedLineDecorations(
          ~runId=latestRunId,
          ~filePath="/index.js",
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

        BsReactMonaco.createWidget(
          ~monaco,
          ~lineNum=result.lineNum,
          ~hasError=result.hasError,
          ~horizontalOffset,
          ~content=result.content,
        )
      })

      contentWidgets->Belt.Array.forEach(contentWidget =>
        editor->BsReactMonaco.removeContentWidget(contentWidget)
      )

      newContentWidgets->Belt.Array.forEach(contentWidget =>
        editor->BsReactMonaco.addContentWidget(contentWidget)
      )

      setContentWidgets(_ => newContentWidgets)
    }

    None
  }, (insight, content, editor.current, monaco.current))

  React.useEffect1(() => {
    connectionDragRef.current = connectionDrag
    switch (editor.current, monaco.current, connectionDrag) {
    | (Some(editor), Some(monaco), StartedSource(_)) =>
      TypeScript.VirtualFileSystem.makeWithFileSystem(~onCreateFileSystem=fsMap => {
        fsMap->TypeScript.Map.set("main.ts", chain.script)
      })
      ->Js.Promise.then_(
        ((_env, program, _typeChecker, _fsMap, _system)) => {
          let parsed = program["getSourceFile"]("main.ts")

          parsed
          ->Belt.Option.forEach(parsed => {
            let variableDeclarations = parsed->TypeScript.findAllVariableDeclarationsInFunctions

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
    | (Some(editor), _, _) =>
      setHighlights(oldHighlights => {
        let _ = editor->BsReactMonaco.deltaDecorations(oldHighlights, [])
        []
      })
    | _ => ()
    }

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
      let {dDotTs: newTypes, importLine} = Chain.monacoTypelibForChain(schema, chain)
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

      onChange(newScript->Js.String2.trim)
    })

    None
  }, [types])

  React.useEffect3(() => {
    open BsReactMonaco
    monaco.current->Belt.Option.forEach(monaco => {
      editor.current->Belt.Option.forEach(editor => {
        let keyCode = {
          Key.combine([monaco->Key.mod->Key.ctrlCmd, monaco->Key.code->Key.keyS])
        }

        let _commandId = editor->addCommand(keyCode, () => {
          onSaveChain(chain)
        })
      })
    })

    None
  }, (editor.current, monaco.current, chain))

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
        // "automaticLayout": true,
        // "fixedOverflowWidgets": true,
        "contextmenu": false,
        "contextMenu": false,
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
        Debug.assignToWindowForDeveloperDebug(~name="myQuickJSGlobalTest2", QuickJsEmscripten.main)

        Debug.assignToWindowForDeveloperDebug(~name="ts", TypeScript.ts)

        let _disposable = editorHandle->BsReactMonaco.onMouseUp(mouseEvent => {
          Debug.assignToWindowForDeveloperDebug(~name="editorMouseEvent", mouseEvent)

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

        let () = BsReactMonaco.TypeScript.addLib(. monacoInstance, types, content)
        let () = BsReactMonaco.registerPrettier(monacoInstance)
        let modelOptions = BsReactMonaco.Model.modelOptions(~tabSize=2, ())

        editor.current = Some(editorHandle)
        monaco.current = Some(monacoInstance)

        let model = editorHandle->BsReactMonaco.getModel(filename)

        model->BsReactMonaco.Model.updateOptions(modelOptions)

        let sharedRoom = SharedRooms.idempotentCreate(
          ~name=chain.name,
          ~yjsScript=chain.yjsScript,
          ~audioStreamPromise,
        )

        let text = sharedRoom.document->Yjs.Document.getText("monaco")
        let rec observer = (textEvent, transaction) => {
          Js.log4("Observed change in text: ", text, textEvent, transaction)
          text->Yjs.Document.Text.unobserve(observer)
        }

        text->Yjs.Document.Text.observe(observer)

        let awareness = sharedRoom.provider->Yjs.Provider.awareness
        let editors = Yjs.makeSet([editorHandle])

        let shouldConnect = sharedRoom.provider->Yjs.Provider.shouldConnect
        Debug.assignToWindowForDeveloperDebug(~name="sharedRoom", sharedRoom)

        Js.log3("Should connect to ", chain.name, shouldConnect)

        if shouldConnect {
          sharedRoom.provider->Yjs.Provider.connect
          sharedRoom.document->Yjs.Document.once("update", (update, origin, doc) => {
            Js.log4("Doc update after connect: ", update, origin, doc)
          })
        }

        let _monacoBinding = Yjs.Monaco.createBinding(
          ~optimisticInitialText=content,
          ~yText=text,
          ~model,
          ~editors,
          ~awareness,
        )

        onMount(~editor=editorHandle, ~monaco=monacoInstance)
      }}
    />
  </div>
}
