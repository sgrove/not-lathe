@react.component
let make = (~channelId) => {
  open React
  let collaborationContext = useContext(CollaborationContext.context)

  let chatVisualizer = collaborationContext.getSharedChannelState(
    ~id=channelId,
  )->Belt.Option.mapWithDefault([], ((_, states)) => {
    let entries = Obj.magic(states)["entries"](.)->Js.Array.from

    entries
    ->Belt.SortArray.stableSortBy((
      (_: Yjs.Awareness.clientId, a: CollaborationContext.presence),
      (_: Yjs.Awareness.clientId, b: CollaborationContext.presence),
    ) => String.compare(a.name, b.name))
    ->Js.Array2.map(((
      clientId: Yjs.Awareness.clientId,
      presence: CollaborationContext.presence,
    )) => {
      let position = switch presence.position->Js.Undefined.toOption {
      | None => " No mouse"
      | Some({x, y}) => j` (${x->int_of_float->string_of_int}, ${y->int_of_float->string_of_int})`
      }

      <div
        key={clientId->Obj.magic}
        style={ReactDOMStyle.make(~color=presence.color, ())}
        className=" font-semibold text-sm font-mono inline-block flex-grow">
        {
          // <Comps.Pre> {presence->Debug.JSON.stringify->string} </Comps.Pre>
          presence.name->string
        }
        {position->string}
        {" "->string}
        <AudioStreamPlayer presence />
      </div>
    })
  })

  <article id={"channel-chat-" ++ channelId} disabled=true className={"m-2 "}>
    <div className={"flex flex-col justify-between cursor-pointer p-1 text-gray-200 "}>
      {chatVisualizer->array}
    </div>
  </article>
}
