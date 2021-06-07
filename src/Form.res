type state = {chainExecutionResults: option<Js.Json.t>}

module Main = {
  @react.component
  let make = (~schema, ~chainId: string, ~appId: string) => {
    // let appId = "993a3e2d-de45-44fa-bff4-0c58c6150cbf"
    let (formVariables, setFormVariables) = React.useState(() => Js.Dict.empty())
    let (state, setState) = React.useState(() => {chainExecutionResults: None})

    let chain = chainId->Chain.loadFromLocalStorageById

    let form =
      chain
      ->Belt.Option.map(chain => {
        let webhookUrl = Compiler.Exports.webhookUrlForAppId(~appId)
        let compiledOperation = Compiler.transformChain(~schema, ~webhookUrl, chain)
        let targetChain = compiledOperation.chains->Belt.Array.get(0)->Belt.Option.getUnsafe
        let inputs = targetChain.exposedVariables->Belt.Array.map(exposedVariable => {
          let def: GraphQLJs.variableDefinition = {
            variable: {
              name: {
                value: exposedVariable.exposedName,
                kind: "Name",
                loc: None,
              },
            },
            typ: exposedVariable.upstreamType->GraphQLJs.parseType->Obj.magic,
          }

          GraphQLForm.formInput(schema, def, setFormVariables, GraphQLForm.formInputOptions())
        })

        inputs->React.array
      })
      ->Belt.Option.getWithDefault(React.null)

    open React

    <div
      style={ReactDOMStyle.make(~backgroundColor="rgb(60, 60, 60)", ())}
      className="border-t border-gray-500 h-screen">
      <nav className="flex flex-row border-b-2 border-blue-500 py-1 px-2">
        <button
          className={"text-left text-gray-600 hover:text-blue-500 focus:outline-none text-blue-500 flex-grow"}>
          {"Chain Form"->string}
        </button>
      </nav>
      <form
        className={"text-left text-gray-600 hover:text-blue-500 focus:outline-none text-blue-500 flex-grow"}>
        {form}
      </form>
      <button
        type_="button"
        onClick={_ => {
          chain->Belt.Option.forEach(chain => {
            let webhookUrl = Compiler.Exports.webhookUrlForAppId(~appId)
            let compiledOperation = chain->Compiler.transformChain(~schema, ~webhookUrl)
            let targetChain = compiledOperation.chains->Belt.Array.get(0)->Belt.Option.getUnsafe
            let variables = Some(formVariables->Obj.magic)

            OneGraphRe.basicFetchOneGraphPersistedQuery(.
              ~appId,
              ~accessToken=None,
              ~docId=chainId,
              ~operationName=Some(targetChain.operationName),
              ~variables,
            )
            ->Js.Promise.then_(result => {
              let json = result->Obj.magic
              setState(_ => {chainExecutionResults: json})->Js.Promise.resolve
            }, _)
            ->ignore
          })
        }}
        className="w-full focus:outline-none text-white text-sm py-2.5 px-5 border-b-4 border-gray-600 rounded-md bg-gray-500 hover:bg-gray-400">
        {"Submit Form"->string}
      </button>
      {state.chainExecutionResults
      ->Belt.Option.map(results => {
        <>
          <h1> {"Form results: "->string} </h1>
          <pre> {results->Js.Json.stringifyWithSpace(2)->string} </pre>
        </>
      })
      ->Belt.Option.getWithDefault(null)}
    </div>
  }
}

@react.component
let make = (~schema, ~chainId: string, ~appId) => {
  <Main schema chainId appId />
}
