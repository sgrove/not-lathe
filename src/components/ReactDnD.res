// import { DndProvider } from 'react-dnd'

type backend

module Provider = {
  @react.component @module("react-dnd")
  external make: (~backend: backend, ~children: React.element) => React.element = "DndProvider"
}

// import { HTML5Backend } from 'react-dnd-html5-backend'
module Backend = {
  @module("react-dnd-html5-backend")
  external html: backend = "HTML5Backend"
}

type useDragInstance = unit
type monitor
type dragOptions<'a> = {
  item: 'a,
  end: ('a, monitor) => unit,
}

@module("react-dnd") external useDrag: dragOptions<'item> => useDragInstance = "dirname"
