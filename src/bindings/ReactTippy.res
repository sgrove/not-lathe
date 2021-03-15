@react.component @module("@tippyjs/react")
external make: (
  ~className: string=?,
  ~disabled: bool=?,
  ~visible: bool=?,
  ~reference: React.ref<React.element>=?,
  ~content: React.element,
  ~interactive: bool=?,
  ~interactiveBorder: int=?,
  ~delay: int=?,
  ~children: React.element,
) => React.element = "default"
