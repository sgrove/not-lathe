let draggablePattern = `url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAABaADAAQAAAABAAAABQAAAAB/qhzxAAAAGElEQVQIHWNgwAWmTJnyH4Rh8kwwBnk0AJwCBXmDfKBPAAAAAElFTkSuQmCC) repeat`

@react.component
let make = (~top, ~left, ~width="500px", ~title="", ~children, ~onClose) => {
  ReactHotKeysHook.useHotkeys(
    ~keys="esc",
    ~callback=(_event, _handler) => {
      onClose()
    },
    ~options=ReactHotKeysHook.options(),
    ~deps=None,
  )

  <ReactDraggable>
    <div
      className="absolute graphql-structure-container rounded-sm text-gray-200"
      style={ReactDOMStyle.make(
        ~width,
        ~top=j`${top->string_of_int}px`,
        ~left=j`${left->string_of_int}px`,
        ~maxHeight="200px",
        ~overflowY="scroll",
        ~color=Comps.colors["gray-6"],
        ~zIndex="999",
        (),
      )}>
      <div
        style={ReactDOMStyle.make(
          ~width="100%",
          ~height="15px",
          ~cursor="move",
          ~color=Comps.colors["gray-6"],
          ~display="flex",
          ~justifyContent="space-between",
          (),
        )}>
        <span
          style={ReactDOMStyle.make(~background=draggablePattern, ())}
          className="text-white cursor-move flex-grow flex-1 mr-4 mt mb">
          {title->React.string}
        </span>
        <span className="text-white cursor-pointer" onClick={_ => onClose()}>
          {j`⨂`->React.string}
        </span>
      </div>
      {children}
    </div>
  </ReactDraggable>
}
