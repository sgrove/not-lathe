module OneGraphStudioChainActionFragment = %relay(`
  fragment NodeLabel_action on OneGraphStudioChainAction {
    id
    name
    services
  }
`)

@react.component
let make = (~actionRef, ~onEditAction) => {
  let action: OneGraphStudioChainActionFragment.Types.fragment = OneGraphStudioChainActionFragment.use(
    actionRef,
  )

  let services =
    action.services
    ->Belt.Array.keepMap(service => {
      service
      ->Utils.serviceImageUrl
      ->Belt.Option.map(((url, friendlyServiceName)) => {
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
      })
    })
    ->React.array

  open React
  let connectionDrag = useContext(ConnectionContext.context)
  let requestValueCache = useContext(RequestValueCacheProvider.context)
  let (mouseHover, setMouseHover) = useState(() => false)

  let dataState = switch requestValueCache->RequestValueCache.get(~requestId=action.id) {
  | None => #mocked
  | Some(result) =>
    switch result.errors
    ->Js.Undefined.toOption
    ->Belt.Option.mapWithDefault(0, Belt.Array.length) > 0 {
    | true => #error
    | false => #data
    }
  }

  let indicatorClass = switch dataState {
  | #mocked => "mocked-indicator"
  | #error => "error-indicator"
  | #data => "data-indicator"
  }

  let domRef = React.useRef(Js.Nullable.null)

  let className = switch (connectionDrag.value, #query, mouseHover) {
  | (ConnectionContext.StartedSource({sourceActionId}), _, true)
  | (CompletedPendingVariable({sourceActionId}), _, true)
    if sourceActionId != action.id => "node-drop drag-target drop-ready"
  | (ConnectionContext.StartedSource({sourceActionId}), _, _)
  | (CompletedPendingVariable({sourceActionId}), _, _)
    if sourceActionId != action.id => "node-drop drag-target"

  | (ConnectionContext.StartedSource({sourceActionId}), _, _)
  | (Completed({sourceActionId}), _, _)
    if sourceActionId == action.id => "node-drop drag-source no-drop"
  | (ConnectionContext.StartedSource({sourceActionId}), _, _)
  | (CompletedPendingVariable({sourceActionId}), _, _)
    if sourceActionId == action.id => "node-drop drag-source no-drop"

  | (ConnectionContext.StartedTarget(_), #fragment, _) => ""
  | (ConnectionContext.StartedTarget({target: Variable({actionId})}), _, _)
    if actionId == action.id => " node-drop drag-source no-drop"
  | (ConnectionContext.StartedTarget(_), _, true) => " node-drop drag-target drop-ready"
  | (ConnectionContext.StartedTarget(_), _, false) => " node-drop drag-target"
  | _ => ""
  }

  <div
    ref={ReactDOM.Ref.domRef(domRef)}
    className={"flex align-middle items-center min-w-max flex-row items-stretch " ++ className}
    onMouseEnter={_ => {
      setMouseHover(_ => true)
    }}
    onMouseLeave={_ => {
      setMouseHover(_ => false)
    }}
    onMouseDown={event => {
      switch event->ReactEvent.Mouse.altKey {
      | false => ()
      | true =>
        event->ReactEvent.Mouse.preventDefault
        event->ReactEvent.Mouse.stopPropagation
        let newConnectionDrag =
          domRef.current
          ->Js.Nullable.toOption
          ->Belt.Option.mapWithDefault(ConnectionContext.Empty, domRef => StartedSource({
            sourceActionId: action.id,
            sourceDom: domRef,
          }))
        connectionDrag.onDragStart(~connectionDrag=newConnectionDrag)
      }
    }}
    onMouseUp={event => {
      let clientX = event->ReactEvent.Mouse.clientX
      let clientY = event->ReactEvent.Mouse.clientY
      let mouseClientPosition = (clientX, clientY)

      switch connectionDrag.value {
      | StartedSource({sourceActionId} as dragInfo) if sourceActionId != action.id =>
        let newConnectionDrag = ConnectionContext.CompletedPendingVariable({
          sourceActionId: dragInfo.sourceActionId,
          sourceDom: dragInfo.sourceDom,
          windowPosition: mouseClientPosition,
          targetActionId: action.id,
        })
        connectionDrag.onPotentialVariableSourceConnect(~connectionDrag=newConnectionDrag)

      | StartedTarget(dragInfo) =>
        let newConnectionDrag = ConnectionContext.Completed({
          sourceActionId: action.id,
          sourceDom: dragInfo.sourceDom,
          windowPosition: mouseClientPosition,
          target: dragInfo.target,
        })
        connectionDrag.onPotentialVariableSourceConnect(~connectionDrag=newConnectionDrag)
      | _ => ()
      }
    }}
    onContextMenu={event => {
      ()
    }}>
    <div
      className={indicatorClass ++ " pl-2"}
      title="Data for this block is mocked"
      style={ReactDOMStyle.make(~width="4px", ())}
    />
    <div className="flex flex-row items-center justify-end font-mono">
      <div className="m-2"> {services} </div>
      <div className="flex-1 inline-block "> {action.name->string} </div>
      <div
        className="p-2 hover:shadow-lg rounded-md hover:border-gray-300 cursor-pointer m-0"
        onClick={event => {
          ReactEvent.Mouse.preventDefault(event)
          onEditAction(action.id)
        }}>
        <Icons.GraphQL color={Comps.colors["gray-4"]} width="16px" height="16px" />
      </div>
    </div>
  </div>
}
