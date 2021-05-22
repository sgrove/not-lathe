type previewCopyPayload = {
  gqlType: GraphQLJs.graphqlType,
  printedType: string,
  path: array<string>,
  simplePath: array<string>,
  displayedData: Js.Json.t,
}

@react.component @module("../GraphQLMockInputType.js")
external make: (
  ~requestId: string,
  ~schema: GraphQLJs.schema,
  ~definition: GraphQLJs.graphqlOperationDefinition,
  ~fragmentDefinitions: Js.Dict.t<GraphQLJs.graphqlOperationDefinition>,
  ~targetGqlType: string=?,
  ~onCopy: previewCopyPayload => unit,
  ~onClose: unit => unit=?,
  ~definitionResultData: RequestValueCache.t=?,
) => React.element = "GraphQLPreview"
