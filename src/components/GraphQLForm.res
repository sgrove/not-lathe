@deriving(abstract)
type formInputOptions = {
  @optional
  labelClassname: string,
  @optional
  inputClassName: string,
  @optional
  defaultValue: Js.Json.t,
  @optional
  onMouseUp: ReactEvent.Mouse.t => unit,
}

@module("../GraphQLForm.js")
external formInput: (
  GraphQLJs.schema,
  GraphQLJs.variableDefinition,
  'setFormVariablesFn,
  formInputOptions,
) => React.element = "formInput"
