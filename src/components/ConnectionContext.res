type scriptPosition = {lineNumber: int, column: int}

type variableTarget = {targetRequest: Chain.request, variableDependency: Chain.variableDependency}

type target =
  | Variable(variableTarget)
  | Script({scriptPosition: scriptPosition})

type connectionDrag =
  | Empty
  | StartedSource({sourceRequest: Chain.request, sourceDom: Dom.element})
  | StartedTarget({target: target, sourceDom: Dom.element})
  | CompletedPendingVariable({
      sourceRequest: Chain.request,
      sourceDom: Dom.element,
      targetRequest: Chain.request,
      windowPosition: (int, int),
    })
  | Completed({
      sourceRequest: Chain.request,
      sourceDom: Dom.element,
      target: target,
      windowPosition: (int, int),
    })
  | CompletedWithTypeMismatch({
      sourceRequest: Chain.request,
      sourceDom: Dom.element,
      variableTarget: variableTarget,
      sourceType: string,
      targetVariableType: option<string>,
      windowPosition: (int, int),
      potentialFunctionMatches: array<TypeScript.simpleFunctionType>,
      dataPath: array<string>,
    })

let toSimpleString = connectionDrag => {
  switch connectionDrag {
  | Empty => "Empty"
  | StartedSource(_) => "StartedSource"
  | StartedTarget(_) => "StartedTarget"
  | CompletedPendingVariable(_) => "CompletedPendingVariable"
  | Completed(_) => "Completed"
  | CompletedWithTypeMismatch(_) => "CompletedWithTypeMismatch"
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
