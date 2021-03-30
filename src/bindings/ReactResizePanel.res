@module("react-resize-panel") @react.component
external make: (
  ~direction: [#n | #e | #s | #w],
  ~style: ReactDOMStyle.t=?,
  ~handleClass: string=?,
  ~borderClass: string=?,
  ~children: React.element,
) => React.element = "default"
