module Fragment = %relay(`
  fragment VariableInspector_oneGraphStudioChainActionVariable on OneGraphStudioChainActionVariable {
    id
    name
    graphqlType
    description
    ifList
    ifMissing
    maxRecur
    computeMethod: method
    probePath
    ...ComputedVariableInspector_chainActionVariable
  }
`)

module UpdateVariableMutation = %relay(`
  mutation VariableInspector_OneGraphMutation(
    $variable: OneGraphUpdateChainActionVariableInput!
  ) {
    oneGraph {
      updateChainActionVariable(input: $variable) {
        variable {
          ...VariableInspector_oneGraphStudioChainActionVariable
        }
      }
    }
  }
`)

@react.component
let make = (~variableRef, ~actionId) => {
  let variable = Fragment.use(variableRef)
  let inputVariable: VariableInspector_OneGraphMutation_graphql.Types.oneGraphUpdateChainActionVariableInput = {
    id: variable.id,
    probePath: variable.probePath,
    maxRecur: variable.maxRecur,
    ifList: variable.ifList->Obj.magic,
    ifMissing: variable.ifMissing->Obj.magic,
    graphqlType: variable.graphqlType,
    method_: variable.computeMethod->Obj.magic,
    description: variable.description,
    name: variable.name,
  }

  let (mutate, isMutating) = UpdateVariableMutation.use()

  open React
  let (potentialConnection, setPotentialConnection) = useState(() => Belt.Set.String.empty)
  let connectionDrag = useContext(ConnectionContext.context)
  let isOpen = true

  let dragClassName = switch connectionDrag.value {
  | ConnectionContext.StartedSource(_) => "drag-target"
  | ConnectionContext.StartedTarget({target: Variable({variableId})})
    if variableId == variable.id => "drag-source"
  | _ => ""
  }

  <article
    key={variable.name}
    id={"inspector-variable-" ++ variable.name}
    disabled=true
    className={"m-2 variable-settings " ++
    dragClassName ++ {
      potentialConnection->Belt.Set.String.has(variable.name) ? " drop-ready" : ""
    }}
    onMouseEnter={event => {
      switch connectionDrag.value {
      | StartedSource(_) => setPotentialConnection(s => s->Belt.Set.String.add(variable.name))
      | _ => ()
      }
    }}
    onMouseLeave={event => {
      switch connectionDrag.value {
      | StartedSource(_)
      | StartedTarget(_) =>
        setPotentialConnection(s => s->Belt.Set.String.remove(variable.name))
      | _ => ()
      }
    }}
    onMouseDown={event => {
      switch event->ReactEvent.Mouse.altKey {
      | false => ()
      | true =>
        event->ReactEvent.Mouse.preventDefault
        event->ReactEvent.Mouse.stopPropagation
        switch connectionDrag.value {
        | Empty =>
          let sourceDom = event->ReactEvent.Mouse.target

          let newConnectionDrag: ConnectionContext.connectionDrag = StartedTarget({
            target: Variable({
              actionId: actionId,
              variableId: variable.id,
            }),
            sourceDom: sourceDom->Obj.magic,
          })

          connectionDrag.onDragStart(~connectionDrag=newConnectionDrag)
        | _ => ()
        }
      }
    }}
    onMouseUp={event => {
      let clientX = event->ReactEvent.Mouse.clientX
      let clientY = event->ReactEvent.Mouse.clientY
      let mouseClientPosition = (clientX, clientY)
      setPotentialConnection(s => s->Belt.Set.String.remove(variable.name))
      switch connectionDrag.value {
      | StartedSource({sourceActionId, sourceDom}) =>
        let newConnectionDrag = ConnectionContext.Completed({
          sourceActionId: sourceActionId,
          target: Variable({
            variableId: variable.id,
            actionId: actionId,
          }),
          windowPosition: mouseClientPosition,
          sourceDom: sourceDom,
        })

        connectionDrag.onPotentialVariableSourceConnect(~connectionDrag=newConnectionDrag)
        ()
      | _ => ()
      }
    }}>
    <div
      className={"flex justify-between items-center cursor-pointer p-1  text-gray-200 " ++
      (isOpen ? "rounded-t-sm" : "rounded-sm") ++ (
        potentialConnection->Belt.Set.String.has(variable.name) ? " border-blue-900" : ""
      )}>
      <div
        style={ReactDOMStyle.make(~color=Comps.colors["green-4"], ())}
        className=" font-semibold text-sm font-mono inline-block flex-grow">
        {j`\\$${variable.name}`->string}
        <span className="font-thin" style={ReactDOMStyle.make(~color=Comps.colors["gray-4"], ())}>
          {j`: ${variable.graphqlType}`->string}
        </span>
      </div>
      <Comps.Select
        style={ReactDOMStyle.make(~paddingRight="40px", ())}
        value={switch variable.computeMethod {
        | #COMPUTED => Some("COMPUTED")
        | #DIRECT => Some("DIRECT")
        | _ => None
        }->Belt.Option.getWithDefault("")}
        onChange={event => {
          let value = ReactEvent.Form.target(event)["value"]
          let newVariable = {...inputVariable, method_: value}
          let _result: RescriptRelay.Disposable.t = mutate(~variables={variable: newVariable}, ())
        }}>
        <option value={"variable"}> {"Variable Input"->string} </option>
        <option value={"COMPUTED"}> {"Computed Value"->string} </option>
        <option disabled=true value={"DIRECT"}> {"Direct Connection"->string} </option>
      </Comps.Select>
    </div>
    <label className="m-0">
      <div className="flex rounded-md">
        <div className="flex-1 flex-grow" />
        <div
          style={ReactDOMStyle.make(
            ~backgroundColor=Comps.colors["brown-1"],
            ~color=Comps.colors["gray-4"],
            (),
          )}
          className="inline-flex justify-end items-center text-right px-3 rounded-l-md text-sm">
          {"ifMissing:"->string}
        </div>
        <Comps.Select
          style={ReactDOMStyle.make(~borderTopLeftRadius="0px", ~borderBottomLeftRadius="0px", ())}
          value={variable.ifMissing->Obj.magic}
          onChange={event => {
            let ifMissing = ReactEvent.Form.target(event)["value"]->Chain.ifMissingOfString
            switch ifMissing {
            | Error(_) => ()
            | Ok(ifMissing) =>
              let newVariable = {...inputVariable, ifMissing: ifMissing->Obj.magic}
              let result: RescriptRelay.Disposable.t = mutate(
                ~variables={variable: newVariable},
                (),
              )
              result->ignore
            }
          }}>
          <option value={#ERROR->Chain.stringOfIfMissing}> {"Error"->string} </option>
          <option value={#ALLOW->Chain.stringOfIfMissing}> {"Allow"->string} </option>
          <option value={#SKIP->Chain.stringOfIfMissing}> {"Skip"->string} </option>
        </Comps.Select>
      </div>
      <div className="flex rounded-md">
        <div className="flex-1 flex-grow" />
        <div
          style={ReactDOMStyle.make(
            ~backgroundColor=Comps.colors["brown-1"],
            ~color=Comps.colors["gray-4"],
            (),
          )}
          className="inline-flex justify-end items-center text-right px-3 rounded-l-md text-sm">
          {"ifList:"->string}
        </div>
        <Comps.Select
          style={ReactDOMStyle.make(~borderTopLeftRadius="0px", ~borderBottomLeftRadius="0px", ())}
          value={variable.ifList->Obj.magic}
          onChange={event => {
            let ifList = ReactEvent.Form.target(event)["value"]
            let newVariable = {...inputVariable, ifList: ifList->Obj.magic}
            let result: RescriptRelay.Disposable.t = mutate(~variables={variable: newVariable}, ())
            result->ignore
          }}>
          <option value={#FIRST->Obj.magic}> {"First item"->string} </option>
          <option value={#LAST->Obj.magic}> {"Last item"->string} </option>
          <option value={#ALL->Obj.magic}> {"All items as an array"->string} </option>
          <option value={#EACH->Obj.magic}> {"Run once for each item"->string} </option>
        </Comps.Select>
      </div>
    </label>
    {switch variable.computeMethod {
    | #COMPUTED => null
    | #DIRECT => variable.probePath->Js.Array2.joinWith("->")->string
    | _ => "Unknown Variable Type"->string
    }}
  </article>
}
