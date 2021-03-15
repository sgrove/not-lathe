%%raw(`import dynamic from 'next/dynamic'`)

module type STUDIO_COMPONENT = {
  @react.component
  let make: (~schema: GraphQLJs.schema, ~initialChain: Chain.t) => React.element
}

@val
external loader: @as("./components/Studio.js") _ => Js.Promise.t<module(STUDIO_COMPONENT)> =
  "import"

module Inner = {
  type schemaState = Loading | Loaded(GraphQLJs.schema)

  type state = {schema: schemaState}
  @react.component
  let make = (~mod) => {
    let module(Studio: STUDIO_COMPONENT) = mod
    let (state, setState) = React.useState(() => {schema: Loading})

    React.useEffect0(() => {
      let promise = OneGraphRe.fetchOneGraph(
        OneGraphRe.auth,
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
        setState(_ => {schema: Loaded(schema)})
        Js.Promise.resolve(result)
      }, promise)->ignore
      None
    })

    <div>
      <Next.Head>
        <script src="https://unpkg.com/typescript@latest/lib/typescriptServices.js" />
      </Next.Head>
      {switch state.schema {
      | Loading => "Loading schema..."->React.string
      | Loaded(schema) => <> <Studio schema initialChain={Chain.chain} /> </>
      }}
    </div>
  }
}

type state<'a> = {
  msg: string,
  mod: option<'a>,
}

let default = () => {
  let (state, setState) = React.useState(() => {
    msg: "Loading diagram dependencies...",
    mod: None,
  })

  React.useEffect0(() => {
    loader->Js.Promise.then_((module(Studio: STUDIO)) => {
      setState(_ => {
        msg: "Loaded!",
        mod: Some(module(Studio: STUDIO)),
      })->Js.Promise.resolve
    }, _)->ignore
    None
  })

  switch state {
  | {mod: None} => state.msg->React.string
  | {mod: Some(mod)} => <Inner mod />
  }
}

let _r = Acorn.source
