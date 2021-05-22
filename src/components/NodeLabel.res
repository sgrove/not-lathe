module OneGraphStudioChainActionFragment = %relay(`
  fragment NodeLabel_oneGraphStudioChainAction on OneGraphStudioChainAction {
    id
    name
    services
  }
`)

type state = {isOpen: bool}

@react.component
let make = (~actionRef, ~onEditAction, ~onDragStart, ~onPotentialVariableSourceConnect) => {
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

  //   let className = switch (connectionDrag, #query, mouseHover) {
  //   | (ConnectionContext.StartedSource({sourceRequest}), _, true)
  //   | (CompletedPendingVariable({sourceRequest}), _, true)
  //     if Some(sourceRequest) != action => "node-drop drag-target drop-ready"
  //   | (ConnectionContext.StartedSource({sourceRequest}), _, _)
  //   | (CompletedPendingVariable({sourceRequest}), _, _)
  //     if Some(sourceRequest) != action => "node-drop drag-target"

  //   | (ConnectionContext.StartedSource({sourceRequest}), _, _)
  //   | (Completed({sourceRequest}), _, _)
  //     if Some(sourceRequest) == action => "node-drop drag-source no-drop"
  //   | (ConnectionContext.StartedSource({sourceRequest}), _, _)
  //   | (CompletedPendingVariable({sourceRequest}), _, _)
  //     if Some(sourceRequest) == action => "node-drop drag-source no-drop"

  //   | (ConnectionContext.StartedTarget(_), #fragment, _) => ""
  //   | (ConnectionContext.StartedTarget({target: Variable({targetRequest})}), _, _)
  //     if Some(targetRequest) == action => " node-drop drag-source no-drop"
  //   | (ConnectionContext.StartedTarget(_), _, true) => " node-drop drag-target drop-ready"
  //   | (ConnectionContext.StartedTarget(_), _, false) => " node-drop drag-target"
  //   | _ => ""
  //   }
  let className = ""
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
        onDragStart(~event, ~request=action, ~domRef=domRef.current)
      }
    }}
    // onMouseUp={event => {
    //   let clientX = event->ReactEvent.Mouse.clientX
    //   let clientY = event->ReactEvent.Mouse.clientY
    //   let mouseClientPosition = (clientX, clientY)

    //   switch connectionDrag {
    //   | StartedSource({sourceRequest} as dragInfo) if sourceRequest != request =>
    //     let connectionDrag = ConnectionContext.CompletedPendingVariable({
    //       sourceRequest: dragInfo.sourceRequest,
    //       sourceDom: dragInfo.sourceDom,
    //       windowPosition: mouseClientPosition,
    //       targetRequest: request,
    //     })
    //     onPotentialVariableSourceConnect(~connectionDrag)

    //   | StartedTarget(dragInfo) =>
    //     let connectionDrag = ConnectionContext.Completed({
    //       sourceRequest: request,
    //       sourceDom: dragInfo.sourceDom,
    //       windowPosition: mouseClientPosition,
    //       target: dragInfo.target,
    //     })
    //     onPotentialVariableSourceConnect(~connectionDrag)
    //   | _ => ()
    //   }
    // }}
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
