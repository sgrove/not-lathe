type scriptPosition = {lineNumber: int, column: int}

type variableTarget = {actionId: string, variableId: string}

type target =
  | Variable(variableTarget)
  | Script({scriptId: string, scriptPosition: scriptPosition})
  | Action({targetActionId: string})
  | Input({inputDom: Dom.element})

type connectionDrag =
  | Empty
  | StartedSource({sourceActionId: string, sourceDom: Dom.element})
  | StartedTarget({target: target, sourceDom: Dom.element})
  | CompletedPendingVariable({
      sourceActionId: string,
      sourceDom: Dom.element,
      targetActionId: string,
      windowPosition: (int, int),
    })
  | Completed({
      sourceActionId: string,
      sourceDom: Dom.element,
      target: target,
      windowPosition: (int, int),
    })
  | CompletedWithTypeMismatch({
      sourceActionId: string,
      sourceDom: Dom.element,
      variableTarget: variableTarget,
      sourceType: string,
      targetVariableType: option<string>,
      windowPosition: (int, int),
      potentialFunctionMatches: array<TypeScript.simpleFunctionType>,
      dataPath: array<string>,
      path: array<string>,
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

type state = {
  onDragStart: (~connectionDrag: connectionDrag) => unit,
  onDragEnd: unit => unit,
  value: connectionDrag,
  onPotentialScriptSourceConnect: (
    ~scriptId: string,
    ~sourceActionId: string,
    ~sourceDom: Dom.element,
    ~scriptPosition: scriptPosition,
    ~mousePosition: (int, int),
  ) => unit,
  onPotentialVariableSourceConnect: (~connectionDrag: connectionDrag) => unit,
  onPotentialActionSourceConnect: (~connectionDrag: connectionDrag) => unit,
}

let context = React.createContext({
  onDragStart: (~connectionDrag as _) => (),
  onDragEnd: () => (),
  onPotentialVariableSourceConnect: (~connectionDrag as _) => (),
  onPotentialScriptSourceConnect: (
    ~scriptId as _: string,
    ~sourceActionId as _,
    ~sourceDom as _,
    ~scriptPosition as _,
    ~mousePosition as _,
  ) => (),
  onPotentialActionSourceConnect: (~connectionDrag as _) => (),
  value: Empty,
})

module Provider = {
  let provider = React.Context.provider(context)

  @react.component
  let make = (~value, ~children) => {
    React.createElement(provider, {"value": value, "children": children})
  }
}
