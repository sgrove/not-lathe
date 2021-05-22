module InspectorOverviewFragment = %relay(`
  fragment InspectorOverview_oneGraphAppPackageChain on OneGraphAppPackageChain {
    id
    description
    actions {
      id
      name
      upstreamActionIds
      actionVariables: variables {
        ...VariableInspector_oneGraphStudioChainActionVariable
      }
    }
  }
`)

@react.component
let make = (
  ~fragmentRefs,
  ~onPotentialVariableSourceConnect,
  ~onInspectAction: (~actionId: string) => unit,
  ~onDeleteAction,
) => {
  open Comps

  let chain = InspectorOverviewFragment.use(fragmentRefs)

  open React
  let connectionDrag = useContext(ConnectionContext.context)
  let (potentialConnection, setPotentialConnection) = useState(() => Belt.Set.String.empty)

  let actions = chain.actions->Belt.Array.map(action => {
    let dragClassName =
      switch connectionDrag {
      | ConnectionContext.StartedSource({sourceRequest})
        if sourceRequest.id != action.id => "node-drop drag-target"
      | _ => ""
      } ++ {
        potentialConnection->Belt.Set.String.has(action.id) ? " drop-ready" : ""
      }

    <article
      key={action.id}
      className={"mx-2 " ++ dragClassName}
      onMouseEnter={event => {
        switch connectionDrag {
        | StartedSource(_) => setPotentialConnection(s => s->Belt.Set.String.add(action.id))
        | _ => ()
        }
      }}
      onMouseLeave={event => {
        switch connectionDrag {
        | StartedSource(_) => setPotentialConnection(s => s->Belt.Set.String.remove(action.id))
        | _ => ()
        }
      }}
      onMouseUp={event => {
        let clientX = event->ReactEvent.Mouse.clientX
        let clientY = event->ReactEvent.Mouse.clientY
        let mouseClientPosition = (clientX, clientY)
        setPotentialConnection(s => s->Belt.Set.String.remove(action.id))
        switch connectionDrag {
        | StartedSource({
            sourceRequest,
            sourceDom,
          }) => // let connectionDrag = ConnectionContext.CompletedPendingVariable({
          //   sourceRequest: sourceRequest,
          //   targetRequest: action,
          //   windowPosition: mouseClientPosition,
          //   sourceDom: sourceDom,
          // })

          // onPotentialVariableSourceConnect(~connectionDrag)
          ()
        | _ => ()
        }
      }}>
      <div
        className={"flex justify-between items-center cursor-pointer p-1 rounded-sm " ++
        dragClassName}>
        <span
          className="font-semibold text-sm font-mono pl-2"
          style={ReactDOMStyle.make(~color=Comps.colors["green-4"], ())}
          onClick={_ => onInspectAction(~actionId=action.id)}>
          {action.name->string}
        </span>
        <Comps.Button
          className="og-secodary-button"
          onClick={event => {
            event->ReactEvent.Mouse.stopPropagation
            event->ReactEvent.Mouse.preventDefault
            let confirmation = Utils.confirm(j`Really delete "${action.name}"?`)

            switch confirmation {
            | false => ()
            | true => onDeleteAction(action)
            }
          }}>
          <Icons.Trash color={Comps.colors["gray-4"]} className="inline mr-2" />
          {"Delete Action"->string}
        </Comps.Button>
      </div>
    </article>
  })

  <>
    <CollapsableSection defaultOpen=false title={"Metadata"->React.string}>
      <div className="relative text-lg bg-transparent text-gray-800">
        <div className="flex items-center ml-2 mr-2">
          <textarea
            defaultValue={chain.description->Belt.Option.getWithDefault("")}
            style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-9"], ())}
            className="border-none px-2 leading-tight outline-none text-white form-input"
            type_="text"
            placeholder={"Chain description"}
            onChange={event => {
              ()
              // let value = ReactEvent.Form.target(event)["value"]->Js.String2.trim
              // let description = switch value {
              // | "" => None
              // | other => Some(other)
              // }

              // let newChain = {...chain, description: description}

              //  onChainUpdated(newChain)
            }}
          />
        </div>
      </div>
    </CollapsableSection>
    <CollapsableSection title={"Chain Actions"->React.string}>
      {actions->array}
    </CollapsableSection>
  </>
}
