type state = Empty | Loaded(Yjs.Stream.t)

let context = React.createContext(Empty)

module Provider = {
  let provider = React.Context.provider(context)

  @react.component
  let make = (~value, ~children) => {
    React.createElement(provider, {"value": value, "children": children})
  }
}
