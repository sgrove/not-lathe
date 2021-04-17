@deriving(abstract)
type bounds = {
  @optional
  left: float,
  @optional
  top: float,
  @optional
  right: float,
  @optional
  bottom: float,
}

@deriving(abstract)
type position = {
  x: float,
  y: float,
}

@module("react-draggable") @react.component
external make: (
  ~allowAnyClick: bool=?,
  ~axis: string=?,
  ~bounds: bounds=?,
  ~cancel: string=?,
  ~defaultClassName: string=?,
  ~defaultClassNameDragging: string=?,
  ~defaultClassNameDragged: string=?,
  ~defaultPosition: position=?,
  ~disabled: bool=?,
  ~grid: (float, float)=?,
  ~handle: string=?,
  // ~offsetParent: HTMLElement=?,
  ~onMouseDown: ReactEvent.Mouse.t => unit=?,
  ~onStart: 'draggableEventHandler=?,
  ~onDrag: 'draggableEventHandler=?,
  ~onStop: 'draggableEventHandler=?,
  // ~nodeRef: React.Ref<typeof React.Component>=?,
  ~position: position=?,
  ~positionOffset: position=?,
  ~scale: float=?,
  ~children: React.element,
) => React.element = "default"
