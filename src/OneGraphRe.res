@module("./OneGraph.js")
external fetchOneGraph: (
  OneGraphAuth.t,
  string,
  option<string>,
  option<Js.Json.t>,
) => Js.Promise.t<GraphQLJs.introspectionQueryResult> = "fetchOneGraph"

@module("./OneGraph.js")
external persistQuery: (
  ~appId: string,
  ~persistQueryToken: string,
  ~queryToPersist: string,
  ~freeVariables: array<string>,
  ~accessToken: option<string>,
  ~fixedVariables: option<Js.Json.t>,
  ~onComplete: Js.Json.t => unit,
) => unit = "persistQuery"

@module("./OneGraph.js")
external basicFetchOneGraphPersistedQuery: (
  ~appId: string,
  ~accessToken: option<OneGraphAuth.t>,
  ~docId: string,
  ~variables: option<Js.Json.t>,
  ~operationName: option<string>,
) => Js.Promise.t<Js.Json.t> = "basicFetchOneGraphPersistedQuery"

@module("./OneGraph.js")
external fetchOneGraphPersistedQuery: (
  option<OneGraphAuth.t>,
  string,
  option<string>,
  option<Js.Json.t>,
) => Js.Promise.t<Js.Json.t> = "fetchOneGraphPersistedQuery"
