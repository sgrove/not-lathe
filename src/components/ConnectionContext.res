type scriptPosition = {lineNumber: int, column: int}

type target =
  | Variable({targetRequest: Chain.request, variableDependency: Chain.variableDependency})
  | Script({scriptPosition: scriptPosition})

type connectionDrag =
  | Empty
  | StartedSource({sourceRequest: Chain.request, sourceDom: Dom.element})
  | StartedTarget({target: target, sourceDom: Dom.element})
  | Completed({
      sourceRequest: Chain.request,
      sourceDom: Dom.element,
      target: target,
      windowPosition: (int, int),
    })

let toSimpleString = connectionDrag => {
  switch connectionDrag {
  | Empty => "Empty"
  | StartedSource(_) => "StartedSource"
  | StartedTarget(_) => "StartedTarget"
  | Completed(_) => "Completed"
  }
}

let context = React.createContext(Empty)

module Provider = {
  let provider = React.Context.provider(context)

  @react.component
  let make = (~value, ~children) => {
    React.createElement(provider, {"value": value, "children": children})
  }
}
