module Inner = {
  type schemaState =
    | Loading(string)
    | Dead({msg: string, error: Js.Promise.error})
    | Loaded(GraphQLJs.schema)

  type state = {schema: schemaState, oneGraphAuth: option<OneGraphAuth.t>}

  @react.component
  let make = (~oneGraphAppId) => {
    let (state, setState) = React.useState(() => {
      schema: Loading("Loading schema..."),
      oneGraphAuth: None,
    })

    React.useEffect0(() => {
      let oneGraphAuth = OneGraphAuth.create(OneGraphAuth.createOptions(~appId=oneGraphAppId, ()))

      oneGraphAuth->Belt.Option.forEach(oneGraphAuth => {
        let promise = OneGraphRe.fetchOneGraph(
          oneGraphAuth,
          GraphQLJs.getIntrospectionQuery(),
          None,
          None,
        )
        GraphQLJs.install()->ignore
        Js.Promise.then_(result => {
          let basicSchema = GraphQLJs.buildClientSchema(Obj.magic(result)["data"])
          let schema = GraphQLTools.addMocksToSchema(
            {
              "schema": basicSchema,
              "mocks": {"JSON": () => Js.Dict.empty()},
            }->Obj.magic,
          )
          Debug.assignToWindowForDeveloperDebug(~name="mockedSchema", schema)
          setState(oldState => {...oldState, schema: Loaded(schema)})->Js.Promise.resolve
        }, promise)->Js.Promise.catch(error => {
          let msg = j`Error loading schema, check that CORS is allowed on https://onegraph.com/dashboard/app/${oneGraphAuth->OneGraphAuth.appId}`
          setState(_oldState => {
            oneGraphAuth: Some(oneGraphAuth),
            schema: Dead({msg: msg, error: error}),
          })->Js.Promise.resolve
        }, _)->ignore
      })
      None
    })
    let router = Next.Router.useRouter()

    let chainId = router.query->Js.Dict.get("form_id")

    open React
    <div>
      <Next.Head> <title> {"OneGraph Serverless Studio Form"->React.string} </title> </Next.Head>
      {switch state.schema {
      | Loading(msg) => msg->string
      | Dead({msg, error}) => <>
          <h1> {msg->string} </h1>
          <pre> {error->Obj.magic->Js.Json.stringifyWithSpace(2)->string} </pre>
        </>
      | Loaded(schema) => <>
          {switch chainId {
          | None => "No form id found"->React.string
          | Some(chainId) => <Form schema chainId={chainId} appId=oneGraphAppId />
          }}
        </>
      }}
    </div>
  }
}

let default = () => {
  let oneGraphAppId = "4b34d36f-83e5-4789-9cf7-fe1ebe1ce527"
  <Inner oneGraphAppId />
}
