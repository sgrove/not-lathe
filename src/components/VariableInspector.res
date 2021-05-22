module OneGraphStudioChainActionVariableFragment = %relay(`
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
    ...ComputedVariableInspector_oneGraphAppPackageChainActionVariable
  }
`)

@react.component
let make = (~variableRef) => {
  let variable = OneGraphStudioChainActionVariableFragment.use(variableRef)

  open React
  let (potentialConnection, setPotentialConnection) = useState(() => Belt.Set.String.empty)
  let connectionDrag = useContext(ConnectionContext.context)
  let isOpen = true

  let dragClassName = ""

  <article
    key={variable.name}
    id={"inspector-variable-" ++ variable.name}
    className={"m-2 variable-settings " ++
    dragClassName ++ {
      potentialConnection->Belt.Set.String.has(variable.name) ? " drop-ready" : ""
    }}
    onMouseEnter={event => {
      switch connectionDrag {
      | StartedSource(_) => setPotentialConnection(s => s->Belt.Set.String.add(variable.name))
      | _ => ()
      }
    }}
    onMouseLeave={event => {
      switch connectionDrag {
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
        switch connectionDrag {
        | Empty =>
          let sourceDom = event->ReactEvent.Mouse.target

          //   let connectionDrag: ConnectionContext.connectionDrag = StartedTarget({
          //     target: Variable({
          //       targetRequest: request,
          //       variableDependency: varDep,
          //     }),
          //     sourceDom: sourceDom->Obj.magic,
          //   })

          //   onDragStart(~connectionDrag)
          setPotentialConnection(s => s->Belt.Set.String.add(variable.name))

        | _ => ()
        }
      }
    }}
    onMouseUp={event => {
      let clientX = event->ReactEvent.Mouse.clientX
      let clientY = event->ReactEvent.Mouse.clientY
      let mouseClientPosition = (clientX, clientY)
      setPotentialConnection(s => s->Belt.Set.String.remove(variable.name))
      switch connectionDrag {
      | StartedSource({
          sourceRequest,
          sourceDom,
        }) => // let connectionDrag = ConnectionContext.Completed({
        //   sourceRequest: sourceRequest,
        //   target: Variable({
        //     variableDependency: varDep,
        //     targetRequest: request,
        //   }),
        //   windowPosition: mouseClientPosition,
        //   sourceDom: sourceDom,
        // })

        // onPotentialVariableSourceConnect(~connectionDrag)
        ()
      | _ => ()
      }
    }}>
    <div
      className={"flex justify-between items-center cursor-pointer p-1  text-gray-200 " ++
      (isOpen ? "rounded-t-sm" : "rounded-sm") ++ (
        potentialConnection->Belt.Set.String.has(variable.name) ? " border-blue-900" : ""
      )}
      onClick={_ => {
        // setOpenedTabs(oldOpenedTabs =>
        //   isOpen
        //     ? oldOpenedTabs->Belt.Set.String.remove(varDep.name)
        //     : oldOpenedTabs->Belt.Set.String.add(varDep.name)
        // )
        ()
      }}>
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
        | #COMPUTED => Some("compute")
        | #DIRECT => Some("direct")
        | _ => None
        }->Belt.Option.getWithDefault("")}>
        <option value={"variable"}> {"Variable Input"->string} </option>
        <option value={"computed"}> {"Computed Value"->string} </option>
        <option disabled=true value={"direct"}> {"Direct Connection"->string} </option>
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
            | Ok(ifMissing) => // setArgDep(oldArgDep => {
              //   let newArgDep = {
              //     ...oldArgDep,
              //     ifMissing: ifMissing,
              //   }
              //   newArgDep
              // })
              ()
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
            let ifList = ReactEvent.Form.target(event)["value"]->Chain.ifListOfString
            switch ifList {
            | Error(_) => ()
            | Ok(ifList) => // setArgDep(oldArgDep => {
              //   let newArgDep = {
              //     ...oldArgDep,
              //     ifMissing: ifMissing,
              //   }
              //   newArgDep
              // })
              ()
            }
          }}>
          <option value={#FIRST->Chain.stringOfIfList}> {"First item"->string} </option>
          <option value={#LAST->Chain.stringOfIfList}> {"Last item"->string} </option>
          <option value={#ALL->Chain.stringOfIfList}> {"All items as an array"->string} </option>
          <option value={#EACH->Chain.stringOfIfList}> {"Run once for each item"->string} </option>
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
