%%raw(`import dynamic from 'next/dynamic'`)

@module("graphql") external getIntrospectionQuery: unit => string = "getIntrospectionQuery"

// module ReactDiagramsTest = {
//   type engine
//   external createEngine: unit => engine = "createEngine"
// }

// module Dynamic = {
//   @deriving(abstract)
//   type options = {
//     @optional
//     ssr: bool,
//     @optional
//     loading: unit => React.element,
//   }

//   /* * Test * */
//   @module("next/dynamic")
//   external dynamic: (unit => Js.Promise.t<'a>, options) => 'a = "default"

//   @val external import_: string => Js.Promise.t<'a> = "import"
// }

// module ReactDiagramsDyn = unpack(
//   Dynamic.dynamic(
//     () => Dynamic.import_("@projectstorm/react-diagrams"),
//     Dynamic.options(~ssr=false, ()),
//   ): ReactDiagramsTest
// )

// let dynamicFuse = Dynamic.import_("fuse.js")->Js.Promise.then_((module Fuse: FUSE) => {
//   Js.log2("Fuse.r: ", Fure.r)
// })

// module DynamicFuse = unpack(: Fuse)

// module ReactDiagrams = {
//   open ReactDiagramsDyn

//   // let createEngine = default
// }

// let engine = ReactDiagramsDyn.createEngine(.)
// Js.log2("Engine_result: ", engine)

// let engine = DynReactDiagrams.make()

// module ReactDiagramsdasf = {
//   type engine
//   type node

//   // @module("@projectstorm/react-diagrams")
//   // external createEngine: unit => engine = "createEngine"

//   // module DefaultLinkModel = {
//   //   type options = {
//   //     name: string,
//   //     color: string,
//   //   }

//   //   @module("@projectstorm/react-diagrams") @new
//   //   external make: options => node = "DefaultLinkModel"
//   // }

//   // module DefaultNodeModel = {
//   //   type options = {
//   //     name: string,
//   //     color: string,
//   //   }

//   //   @module("@projectstorm/react-diagrams") @new
//   //   external make: options => node = "DefaultNodeModel"
//   // }

//   // @send external addOutPort: (node, string) => unit = "addOutPort"
//   // @send external setPosition: (node, float, float) => unit = "setPosition"

//   // module Canvas = {
//   //   @module("@projectstorm/react-canvas-core") @react.component
//   //   external make: (~engine: engine) => React.element = "CanvasWidget"
//   // }
// }

// let node1 = ReactDiagrams.DefaultNodeModel.make({name: "Node 1", color: "rgb(0,192,255)"})
// ReactDiagrams.addOutPort(node1, "Out")
// let node2 = ReactDiagrams.DefaultNodeModel.make({name: "Node 2", color: "rgb(0,192,5)"})
// ReactDiagrams.setPosition(node2, 100., 100.)
// ReactDiagrams.addOutPort(node2, "Out")

// Js.log2("intro: ", getIntrospectionQuery())

module type STUDIO = {
  @react.component
  let make: (~schema: GraphQLJs.schema, ~initialChain: Chain.t) => React.element
}

@val
external loader: @as("./components/Studio.js") _ => Js.Promise.t<module(STUDIO)> = "import"

module Inner = {
  type schemaState = Loading | Loaded(GraphQLJs.schema)

  type state = {schema: schemaState}
  @react.component
  let make = (~mod) => {
    let module(Studio: STUDIO) = mod
    let (state, setState) = React.useState(() => {schema: Loading})

    React.useEffect0(() => {
      let promise = OneGraphRe.fetchOneGraph(OneGraphRe.auth, getIntrospectionQuery(), None, None)
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
    let router = Next.Router.useRouter()

    let chainId = router.query->Js.Dict.get("form_id")

    <div>
      <Next.Head>
        <script src="https://unpkg.com/typescript@latest/lib/typescriptServices.js" />
      </Next.Head>
      {switch state.schema {
      | Loading => "Loading schema..."->React.string
      | Loaded(schema) => <>
          {switch chainId {
          | None => "No form id found"->React.string
          | Some(chainId) => <Form schema chainId={chainId} />
          }}
        </>
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
