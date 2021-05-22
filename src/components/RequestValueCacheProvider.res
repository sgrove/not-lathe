let empty: RequestValueCache.t = RequestValueCache.make()
let context = React.createContext(empty)
let provider = React.Context.provider(context)

@react.component
let make = (~value, ~children) => {
  React.createElement(provider, {"value": value, "children": children})
}
