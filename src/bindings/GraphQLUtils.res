type service = {
  friendlyServiceName: string,
  service: string,
  slug: string,
  supportsCustomServiceAuth: bool,
  supportsOauthLogin: bool,
  simpleSlug: string,
}

@module("../GraphQLMockInputType.js")
external gatherAllReferencedServices: (
  ~schema: GraphQLJs.schema,
  GraphQLJs.graphqlAst,
) => array<service> = "gatherAllReferencedServices"

let getOperationVariables = (operation: GraphQLJs.graphqlOperationDefinition): array<(
  string,
  string,
)> => {
  let variables =
    operation.variableDefinitions
    ->Belt.Option.getWithDefault([])
    ->Belt.Array.map(def => (def.variable.name.value, def.typ->Obj.magic->GraphQLJs.printAst))

  variables
}
