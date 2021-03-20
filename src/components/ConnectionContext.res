type connectionDrag =
  | Empty
  | Started({sourceRequest: Chain.request, sourceDom: Dom.element})
  | Completed({
      sourceRequest: Chain.request,
      sourceDom: Dom.element,
      targetRequest: Chain.request,
      windowPosition: (int, int),
      variableDependency: Chain.variableDependency,
    })

let context = React.createContext(Empty)

module Provider = {
  let provider = React.Context.provider(context)

  @react.component
  let make = (~value, ~children) => {
    React.createElement(provider, {"value": value, "children": children})
  }
}
