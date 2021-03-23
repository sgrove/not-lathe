let special_token = "XlMpa0MEz1ZMIYtebUGttQpV9I8CCwL5VejNbfStd2c"

module AdvancedMode = {
  let enabled = false
}

module Clipboard = {
  @module("copy-to-clipboard") external copy: string => unit = "default"
}

module GraphQLPreview = {
  @react.component @module("../GraphQLMockInputType.js")
  external make: (
    ~requestId: string,
    ~schema: GraphQLJs.schema,
    ~definition: GraphQLJs.graphqlOperationDefinition,
    ~fragmentDefinitions: Js.Dict.t<GraphQLJs.graphqlOperationDefinition>,
    ~onCopy: array<string> => unit,
  ) => React.element = "GraphQLPreview"
}

@deriving(abstract)
type formInputOptions = {
  @optional
  labelClassname: string,
  @optional
  inputClassName: string,
}

@module("../GraphQLForm.js")
external formInput: (
  GraphQLJs.schema,
  GraphQLJs.variableDefinition,
  'setFormVariablesFn,
  formInputOptions,
) => React.element = "formInput"

type inspectable =
  | Nothing(Chain.t)
  | Block(Card.block)
  | Request({chain: Chain.t, request: Chain.request})
  | RequestArgument({chain: Chain.t, request: Chain.request, variableName: string})

type remoteChainCalls = {
  fetch: string,
  curl: string,
  scriptKit: string,
  netlify: string,
}

type mockRequestValueVariable = {
  name: string,
  value: Js.Json.t,
}

type mockRequestValues = {
  variables: Js.Json.t,
  graphQLResult: GraphQLJs.queryResult,
}

let transpileFullChainScript = (chain: Chain.t): string => {
  let baseTranspiled = BsReactMonaco.TypeScript.tsTranspile(chain.script, {"target": "ES2020"})

  let allCalls =
    chain.requests
    ->Belt.Array.map(request => {
      let requestCalls = request.variableDependencies->Belt.Array.keepMap(varDep => {
        switch varDep.dependency {
        | ArgumentDependency(_argDep) =>
          let call = Chain.callForVariable(request, varDep.name)
          Some(call)
        | GraphQLProbe(probe) =>
          let call = Chain.callForProbe(request, varDep.name, probe)
          Some(call)

        | _ => None
        }
      })

      requestCalls->Js.Array2.joinWith("\n\n")
    })
    ->Js.Array2.joinWith("\n\n")

  let fullScript = j`${baseTranspiled}

${allCalls}`

  fullScript
}

let patchRequestArgDeps = (request: Chain.request) => {
  let variableDependencies = request.variableDependencies->Belt.Array.map(varDep => {
    let dependency = switch varDep.dependency {
    | ArgumentDependency(argDep) =>
      let requestScriptName = Chain.requestScriptNames(request).functionName

      let functionFromScript = j`${requestScriptName}_${varDep.name}`
      let newArgDep = {
        ...argDep,
        functionFromScript: functionFromScript,
        fromRequestIds: request.dependencyRequestIds,
      }
      Chain.ArgumentDependency(newArgDep)
    | GraphQLProbe(probe) =>
      let requestScriptName = Chain.requestScriptNames(request).functionName

      let functionFromScript = j`${requestScriptName}_${varDep.name}`
      let newProbe = {
        ...probe,
        functionFromScript: functionFromScript,
      }
      Chain.GraphQLProbe(newProbe)
    | other => other
    }

    {...varDep, dependency: dependency}
  })

  {...request, variableDependencies: variableDependencies}
}

let patchChainRequestsArgDeps = (chain: Chain.t) => {
  chain.requests->Belt.Array.map(request => {
    patchRequestArgDeps(request)
  })
}

let evalRequest = (
  ~schema: GraphQLJs.schema,
  ~chain: Chain.t,
  ~request: Chain.request,
  ~requestValueCache: Js.Dict.t<Js.Json.t>,
): Js.Promise.t<result<mockRequestValues, 'err>> => {
  QuickJsEmscripten.getQuickJS()
  ->Js.Promise.then_(
    quickjs => {
      let payload =
        request.variableDependencies
        ->Belt.Array.keepMap(varDep =>
          switch varDep.dependency {
          | ArgumentDependency(argDep) => Some(argDep.fromRequestIds)
          | _ => None
          }
        )
        ->Belt.Array.concatMany
        ->Belt.Array.keepMap(upstreamRequestId => {
          chain.requests->Belt.Array.getBy(request => request.id == upstreamRequestId)
        })
        ->Belt.Array.reduce(Js.Dict.empty(), (acc, nextRequest) => {
          switch acc->Js.Dict.get(nextRequest.id) {
          | Some(_) => acc
          | None =>
            let parsedOperation = nextRequest.operation.body->GraphQLJs.parse
            let definition = parsedOperation.definitions->Belt.Array.getExn(0)

            let variables = GraphQLJs.Mock.mockOperationVariables(schema, definition->Obj.magic)

            switch requestValueCache->Js.Dict.get(nextRequest.id) {
            | Some(results) =>
              acc->Js.Dict.set(
                nextRequest.id,
                {variables: variables, graphQLResult: results->Obj.magic},
              )
              acc
            | None =>
              let results = GraphQLJs.graphqlSync(
                schema,
                nextRequest.operation.body,
                None,
                None,
                Some(variables),
              )
              acc->Js.Dict.set(nextRequest.id, {variables: variables, graphQLResult: results})
              acc
            }
          }
        })

      let transpiled = chain->transpileFullChainScript

      let payload =
        payload
        ->Js.Dict.entries
        ->Belt.Array.map(((key, mockedValue)) => {
          (key, mockedValue.graphQLResult)
        })
        ->Js.Dict.fromArray
        ->Obj.magic
        ->Js.Json.stringify

      let operationDoc = request.operation.body
      let parsedOperation = request.operation.body->GraphQLJs.parse
      let definition = parsedOperation.definitions->Belt.Array.getExn(0)
      let mockedVariables = GraphQLJs.Mock.mockOperationVariables(schema, definition->Obj.magic)

      let variables = request.variableDependencies->Belt.Array.reduce(mockedVariables, (
        acc,
        nextVarDependency,
      ) => {
        switch nextVarDependency.dependency {
        | ArgumentDependency(argDep) =>
          let call = `${argDep.functionFromScript}(${payload})`

          let script = transpiled ++ "\n\n" ++ call

          let fullScript =
            script->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("export ", ~flags="g"), "")
          open QuickJsEmscripten

          let result = quickjs->evalCode(fullScript)

          acc->Obj.magic->Js.Dict.set(nextVarDependency.name, result)
          acc
        | _ => acc
        }
      })

      let graphQLResult = GraphQLJs.graphqlSync(schema, operationDoc, None, None, Some(variables))

      Ok({
        variables: variables,
        graphQLResult: graphQLResult,
      })->Js.Promise.resolve
    },
    // TODO: Use acorn to remove all export declarations

    _,
  )
  ->Js.Promise.catch(err => {
    Js.Console.warn2("Error evalRequest: ", err)
    Js.Promise.resolve(Error(err))
  }, _)
}

let findMissingAuthServicesFromChainResult = result => {
  try {
    let chainResults = Obj.magic(result)["data"]["oneGraph"]["executeChain"]["results"]

    chainResults
    ->Belt.Array.map(operation => {
      let errors = try {
        let rawErrors =
          Obj.magic(operation)["result"]
          ->Belt.Array.map(result => result["errors"])
          ->Obj.magic
          ->Belt.Array.concatMany

        rawErrors
      } catch {
      | _ => []
      }

      let services = OneGraphAuth.findMissingAuthServices(Some(errors))

      services
    })
    ->Belt.Array.concatMany
    ->OneGraphAuth.distinctServices
  } catch {
  | _ => []
  }
}

let internallyPatchChain = chain => {
  let transpiled = transpileFullChainScript(chain)

  let requestsWithLockedVariables = patchChainRequestsArgDeps(chain)

  {
    ...chain,
    requests: requestsWithLockedVariables,
    script: transpiled,
  }
}

let transformChain = chain => {
  let compiled = internallyPatchChain(chain)->Chain.compileOperationDoc

  compiled
}

let remoteChainCalls = (~appId, ~chainId, chain: Chain.t) => {
  let compiled = chain->transformChain
  let targetChain = compiled.chains->Belt.Array.getUnsafe(0)

  let freeVariables =
    targetChain.exposedVariables
    ->Belt.Array.map(exposed => {
      let key = exposed.exposedName
      let value = switch exposed.upstreamType {
      | "String"
      | "String!" => `""`
      | "Int"
      | "Int!" => "42"
      | "Float"
      | "Float!" => "42.0"
      | _other => "{}"
      }

      j`"${key}": ${value}`
    })
    ->Js.Array2.joinWith(", ")

  let curl = j`curl -X POST "https://serve.onegraph.com/graphql?app_id=${appId}" --data '{"doc_id": "${chainId}", "operationName": "${targetChain.operationName}", "variables": {${freeVariables}}}'`

  let fetch = j`await fetch("https://serve.onegraph.com/graphql?app_id=${appId}",
  {
    method: "POST",
    "Content-Type": "application/json",
    body: JSON.stringify({
      "doc_id": "${chainId}",
      "operationName": "${targetChain.operationName}",
      "variables": {${freeVariables}}
      }
    )
  }
)`

  let htmlInputs =
    targetChain.exposedVariables
    ->Belt.Array.map(exposed => {
      let key = exposed.exposedName
      let html = switch exposed.upstreamType {
      | "String"
      | "String!" =>
        `
  <label>
    ${key}
    <input type="text" name="${key}">
  </label>`
      | "Int"
      | "Int!" =>
        `
  <label>
    ${key}
    <input type="number" name="${key}" step=1>
  </label>`
      | "Float"
      | "Float!" =>
        `
  <label>
    ${key}
    <input type="number" name="${key}" step=0.1>
  </label>`
      | _other => ""
      }

      html
    })
    ->Js.Array2.joinWith("\n")

  let netlifyHtml = j`<form class="${chain.name}-form" action="/.netlify/functions/${chain.name}" method="POST">${htmlInputs}
  <button class="button" type="submit">Say hello!</button>
</form>`

  let netlifyVariables =
    targetChain.exposedVariables
    ->Belt.Array.map(exposed => {
      let key = exposed.exposedName
      let coerce = switch exposed.upstreamType {
      | "String"
      | "String!" =>
        j`params["${key}"]`
      | "Int"
      | "Int!" =>
        j`parseInt(params["${key}"])`
      | "Float"
      | "Float!" =>
        j`parseFloat(params["${key}"])`
      | "Boolean"
      | "Boolean!" =>
        j`params["${key}"]?.trim() === "true"`
      | "JSON"
      | "JSON!" =>
        j`JSON.parse(params["${key}"])`
      | _other => j`params["${key}"]`
      }

      j`const ${key} = ${coerce}`
    })
    ->Js.Array2.joinWith("\n\t")

  let netlifyVariablesObject =
    targetChain.exposedVariables
    ->Belt.Array.map(exposed => {
      let key = exposed.exposedName

      j`"${key}": ${key}`
    })
    ->Js.Array2.joinWith(", ")

  let netlifyScript = j`// ./functions/${chain.name}.js
const fetch = require("node-fetch");
const querystring = require("querystring");

exports.handler = async (event, context) => {
  // Only allow POST
  if (event.httpMethod !== "POST") {
    return { statusCode: 405, body: "Method Not Allowed" };
  }

  // When the method is POST, the name will no longer be in the event’s
  // queryStringParameters – it’ll be in the event body encoded as a query string
  const params = querystring.parse(event.body);
  ${netlifyVariables}

  // Execute chain
  await fetch(
    "https://serve.onegraph.com/graphql?app_id=${appId}",
  {
    method: "POST",
    "Content-Type": "application/json",
    body: JSON.stringify({
      "doc_id": "${chainId}",
      "operationName": "${targetChain.operationName}",
      "variables": {${netlifyVariablesObject}}
      }
    )
  })

  return {
    statusCode: 200,
    body: "Finished executing chain!",
  };
};
`

  let netlify = j`${netlifyHtml}

${netlifyScript}`

  let scriptKitArgs =
    targetChain.exposedVariables
    ->Belt.Array.map(exposed => {
      let key = exposed.exposedName
      let coerce = switch exposed.upstreamType {
      | "String"
      | "String!" =>
        j`await arg("${key}")`
      | "Int"
      | "Int!" =>
        j`parseInt(await arg("${key}"))`
      | "Float"
      | "Float!" =>
        j`parseFloat(await arg("${key}"))`
      | "JSON"
      | "JSON!" =>
        j`JSON.parse(await arg("${key}"))`
      | _other => j`await arg("${key}"")`
      }

      j`// ${exposed.upstreamType}
const ${key} = ${coerce}`
    })
    ->Js.Array2.joinWith("\n")

  let scriptKitVariables =
    targetChain.exposedVariables
    ->Belt.Array.map(exposed => {
      let key = exposed.exposedName

      j`"${key}": ${key}`
    })
    ->Js.Array2.joinWith(", ")

  let scriptKit = j`
${scriptKitArgs}

let response = await post("https://serve.onegraph.com/graphql?app_id=${appId}",
  JSON.stringify(
    {
     "doc_id": "${chainId}",
     "operationName": "${targetChain.operationName}",
     "variables": {${scriptKitVariables}}
    }
  ) 
)

console.log("Response: ", response.data)
`

  {
    curl: curl,
    fetch: fetch,
    scriptKit: scriptKit,
    netlify: netlify,
  }
}

let transformAndExecuteChain = (chain, ~oneGraphAuth, ~variables) => {
  let compiled = chain->transformChain

  let targetChain = compiled.chains->Belt.Array.getUnsafe(0)

  let promise = OneGraphRe.fetchOneGraph(
    oneGraphAuth,
    compiled.operationDoc,
    Some(targetChain.operationName),
    variables,
  )

  promise
}

module Block = {
  @react.component
  let make = (
    ~schema as _: GraphQLJs.schema,
    ~block: Card.block,
    ~onAddBlock: Card.block => unit,
  ) => {
    open React

    let (originalContent, setOriginalContent) = React.useState(() => block.body)
    let editor = React.useRef(None)

    React.useEffect1(() => {
      let value = editor.current->Belt.Option.map(BsReactMonaco.getValue)
      switch (value, Some(block.body) == value) {
      | (Some(_), false) =>
        setOriginalContent(_ => block.body)
        editor.current->Belt.Option.forEach(editor => editor->BsReactMonaco.setValue(block.body))
      | _ => ()
      }
      None
    }, [originalContent == block.body])

    <>
      <pre className="m-2 p-2 bg-gray-600 rounded-sm text-gray-200 overflow-scroll select-all">
        {block.body->React.string}
      </pre>
      <Comps.Button onClick={_ => onAddBlock(block)}>
        {"Add block to chain"->React.string}
      </Comps.Button>
    </>
  }
}

module DirectVariable = {
  @react.component
  let make = (
    ~request as _: Chain.request,
    ~chain as _: Chain.t,
    ~variable: string,
    ~onVariableUpdated,
  ) => {
    open React
    <div className="">
      <form>
        <label className="m-0">
          <div className="mt-1 flex rounded-md shadow-sm">
            <span
              className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
              {"$variableName:"->string}
            </span>
            <input
              className="block w-full px-3 text-gray-500 border border-gray-300 bg-white border-l-0 rounded-md shadow-sm focus:outline-none focus:ring-blue-300 focus:border-blue-300 sm:text-sm rounded-l-none"
              value={variable}
              onChange={event => {
                let value = ReactEvent.Form.target(event)["value"]
                onVariableUpdated(value)
              }}
            />
          </div>
        </label>
      </form>
    </div>
  }
}

module DirectJSON = {
  @react.component
  let make = (
    ~request as _: Chain.request,
    ~chain as _: Chain.t,
    ~json: Js.Json.t,
    ~onJsonUpdated,
  ) => {
    open React
    <div className="">
      <form>
        <label className="m-0">
          <div className="mt-1 flex rounded-md shadow-sm">
            <span
              className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
              {"Raw JSON:"->string}
            </span>
            <textarea
              className="block w-full px-3 text-gray-500 border border-gray-300 bg-white border-l-0 rounded-md shadow-sm focus:outline-none focus:ring-blue-300 focus:border-blue-300 sm:text-sm rounded-l-none"
              defaultValue={json->Js.Json.stringify}
              onChange={event => {
                let value = ReactEvent.Form.target(event)["value"]
                let newJson = try {
                  Some(Js.Json.parseExn(value))
                } catch {
                | _ => None
                }
                newJson->Belt.Option.forEach(onJsonUpdated)
              }}
            />
          </div>
        </label>
      </form>
    </div>
  }
}

module ArgumentDependency = {
  @react.component
  let make = (
    ~request as _: Chain.request,
    ~chain as _: Chain.t,
    ~argDep: Chain.argumentDependency,
    ~onArgDepUpdated,
  ) => {
    let setArgDep = makeNewArgDep => {
      onArgDepUpdated(makeNewArgDep(argDep))
    }

    open React
    <div>
      <form>
        <label className="m-0">
          <div className="flex rounded-md shadow-sm">
            <span
              className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
              {"ifMissing:"->string}
            </span>
            <select
              className="px-4 border border-gray-300 bg-white border-l-0 rounded-md shadow-sm focus:outline-none focus:ring-blue-300 focus:border-blue-300 sm:text-sm rounded-l-none m-0 pt-0 pb-0 pl-4 pr-8"
              value={argDep.ifMissing->Obj.magic}
              onChange={event => {
                let ifMissing = ReactEvent.Form.target(event)["value"]->Chain.ifMissingOfString
                switch ifMissing {
                | Error(_) => ()
                | Ok(ifMissing) =>
                  setArgDep(oldArgDep => {
                    let newArgDep = {
                      ...oldArgDep,
                      ifMissing: ifMissing,
                    }
                    newArgDep
                  })
                }
              }}>
              <option value={#ERROR->Chain.stringOfIfMissing}> {"Error"->string} </option>
              <option value={#ALLOW->Chain.stringOfIfMissing}> {"Allow"->string} </option>
              <option value={#SKIP->Chain.stringOfIfMissing}> {"Skip"->string} </option>
            </select>
          </div>
        </label>
        {AdvancedMode.enabled
          ? <label className="m-0">
              <div className="flex rounded-md shadow-sm">
                <span
                  className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
                  {"ifList:"->string}
                </span>
                <select
                  className="block w-full text-gray-500 px-3 border border-gray-300 bg-white border-l-0 rounded-md shadow-sm focus:outline-none focus:ring-blue-300 focus:border-blue-300 sm:text-sm rounded-l-none m-0 pt-0 pb-0 pl-4 pr-8"
                  value={argDep.ifList->Obj.magic}
                  onChange={event => {
                    let ifList = ReactEvent.Form.target(event)["value"]->Chain.ifListOfString
                    switch ifList {
                    | Error(_) => ()
                    | Ok(ifList) => setArgDep(oldArgDep => {...oldArgDep, ifList: ifList})
                    }
                  }}>
                  <option value={#FIRST->Chain.stringOfIfList}> {"First item"->string} </option>
                  <option value={#LAST->Chain.stringOfIfList}> {"Last item"->string} </option>
                  <option value={#ALL->Chain.stringOfIfList}>
                    {"All items as an array"->string}
                  </option>
                  <option value={#EACH->Chain.stringOfIfList}>
                    {"Run once for each item"->string}
                  </option>
                </select>
              </div>
            </label>
          : React.null}
        // <label className="m-0">
        //   <div className="flex rounded-md shadow-sm">
        //     <span
        //       className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
        //       {"fromRequests:"->string}
        //     </span>
        //     <select
        //       className="block w-full text-gray-500 px-3 border border-gray-300 bg-white border-l-0 rounded-md shadow-sm focus:outline-none focus:ring-blue-300 focus:border-blue-300 sm:text-sm rounded-l-none"
        //       value={""}
        //       onChange={event => {
        //         let targetReqId = ReactEvent.Form.target(event)["value"]
        //         let alreadyDependent =
        //           argDep.fromRequestIds->Belt.Array.some(reqId => reqId == targetReqId)
        //         let newFromRequestIds = switch alreadyDependent {
        //         | false => argDep.fromRequestIds->Belt.Array.concat([targetReqId])
        //         | true => argDep.fromRequestIds->Belt.Array.keep(reqId => reqId != targetReqId)
        //         }
        //         setArgDep(oldArgDep => {...oldArgDep, fromRequestIds: newFromRequestIds})
        //       }}>
        //       <option key="" value={""}> {""->string} </option>
        //       {otherRequests
        //       ->Belt.Array.map(req =>
        //         <option key={req.id} value={req.id}>
        //           {((argDependentOnOtherReq(req) ? "v " : "") ++ req.id)->string}
        //         </option>
        //       )
        //       ->array}
        //     </select>
        //   </div>
        // </label>
        // <label className="m-0">
        //   <div className="flex rounded-md shadow-sm">
        //     <span
        //       className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
        //       {"functionFromScript:"->string}
        //     </span>
        //     <select
        //       className="block w-full px-3 text-gray-500 border border-gray-300 bg-white border-l-0 rounded-md shadow-sm focus:outline-none focus:ring-blue-300 focus:border-blue-300 sm:text-sm rounded-l-none"
        //       value={argDep.functionFromScript}
        //       onChange={event => {
        //         let functionFromScript = ReactEvent.Form.target(event)["value"]
        //         switch functionFromScript {
        //         | "NEW_FUNCTION" =>
        //           switch Debug.prompt("Function name: ") {
        //           | None => ()
        //           | Some(functionName) => onFunctionCreated(request)
        //           }
        //         | _ =>
        //           setArgDep(oldArgDep => {...oldArgDep, functionFromScript: functionFromScript})
        //         }
        //       }}>
        //       <option value=""> {""->string} </option>
        //       {scriptFunctions
        //       ->Belt.Array.map(functionName => {
        //         <option value={functionName}> {functionName->string} </option>
        //       })
        //       ->array}
        //       <option value="NEW_FUNCTION"> {"[Create new function]"->string} </option>
        //     </select>
        //   </div>
        // </label>
        // <label className="m-0">
        //   <div className="flex rounded-md shadow-sm">
        //     <span
        //       className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
        //       {"Value Preview:"->string}
        //     </span>
        //   </div>
        // </label>
      </form>
    </div>
  }
}

module GraphQLProbe = {
  @react.component
  let make = (
    ~request as _: Chain.request,
    ~chain as _: Chain.t,
    ~probe: Chain.graphQLProbe,
    ~onArgDepUpdated,
  ) => {
    let setArgDep = makeNewArgDep => {
      onArgDepUpdated(makeNewArgDep(probe))
    }

    open React
    <div>
      <form>
        <label className="m-0">
          <div className="flex rounded-md shadow-sm">
            <span
              className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
              {"ifMissing:"->string}
            </span>
            <select
              className="block w-full text-gray-500 px-3 border border-gray-300 bg-white border-l-0 rounded-md shadow-sm focus:outline-none focus:ring-blue-300 focus:border-blue-300 sm:text-sm rounded-l-none m-0 pt-0 pb-0 pl-4 pr-8"
              value={probe.ifMissing->Obj.magic}
              onChange={event => {
                let ifMissing = ReactEvent.Form.target(event)["value"]->Chain.ifMissingOfString
                switch ifMissing {
                | Error(_) => ()
                | Ok(ifMissing) =>
                  setArgDep(oldArgDep => {
                    let newArgDep = {
                      ...oldArgDep,
                      ifMissing: ifMissing,
                    }
                    newArgDep
                  })
                }
              }}>
              <option value={#ERROR->Chain.stringOfIfMissing}> {"Error"->string} </option>
              <option value={#ALLOW->Chain.stringOfIfMissing}> {"Allow"->string} </option>
              <option value={#SKIP->Chain.stringOfIfMissing}> {"Skip"->string} </option>
            </select>
          </div>
        </label>
        {AdvancedMode.enabled
          ? <label className="m-0">
              <div className="flex rounded-md shadow-sm">
                <span
                  className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
                  {"ifList:"->string}
                </span>
                <select
                  className="block w-full text-gray-500 px-3 border border-gray-300 bg-white border-l-0 rounded-md shadow-sm focus:outline-none focus:ring-blue-300 focus:border-blue-300 sm:text-sm rounded-l-none m-0 pt-0 pb-0 pl-4 pr-8"
                  value={probe.ifList->Obj.magic}
                  onChange={event => {
                    let ifList = ReactEvent.Form.target(event)["value"]->Chain.ifListOfString
                    switch ifList {
                    | Error(_) => ()
                    | Ok(ifList) => setArgDep(oldArgDep => {...oldArgDep, ifList: ifList})
                    }
                  }}>
                  <option value={#FIRST->Chain.stringOfIfList}> {"First item"->string} </option>
                  <option value={#LAST->Chain.stringOfIfList}> {"Last item"->string} </option>
                  <option value={#ALL->Chain.stringOfIfList}>
                    {"All items as an array"->string}
                  </option>
                  <option value={#EACH->Chain.stringOfIfList}>
                    {"Run once for each item"->string}
                  </option>
                </select>
              </div>
            </label>
          : React.null}
      </form>
    </div>
  }
}

let emptyArgumentDependency = (variableName): Chain.variableDependency => {
  name: variableName,
  dependency: ArgumentDependency({
    functionFromScript: "INITIAL_UNKNOWN",
    maxRecur: None,
    ifMissing: #ERROR,
    ifList: #ALL,
    fromRequestIds: [],
    name: variableName,
  }),
}

module RequestArgument = {
  @react.component
  let make = (
    ~request: Chain.request,
    ~chain: Chain.t,
    ~variableName: string,
    ~onRequestUpdated,
    ~defaultRequestArgument,
  ) => {
    let argDep =
      request.variableDependencies
      ->Belt.Array.getBy(argDep => argDep.name === variableName)
      ->Belt.Option.getWithDefault(defaultRequestArgument)

    switch argDep.dependency {
    | Direct({value: Variable(variable)}) =>
      <DirectVariable
        request
        chain
        variable
        onVariableUpdated={newVariable => {
          let newRequest = {
            ...request,
            variableDependencies: request.variableDependencies->Belt.Array.keepMap(
              variableDependency => {
                let dependency =
                  variableDependency.name == variableName
                    ? Chain.Direct({name: variableName, value: Chain.Variable(newVariable)})
                    : variableDependency.dependency

                Some({...variableDependency, dependency: dependency})
              },
            ),
          }
          onRequestUpdated(newRequest)
        }}
      />
    | Direct({value: JSON(json)}) =>
      <DirectJSON
        request
        chain
        json
        onJsonUpdated={newJson => {
          let newRequest = {
            ...request,
            variableDependencies: request.variableDependencies->Belt.Array.keepMap(
              variableDependency => {
                let dependency =
                  variableDependency.name == variableName
                    ? Chain.Direct({name: variableName, value: Chain.JSON(newJson)})
                    : variableDependency.dependency

                Some({...variableDependency, dependency: dependency})
              },
            ),
          }
          onRequestUpdated(newRequest)
        }}
      />
    | ArgumentDependency(argDep) =>
      <ArgumentDependency
        request
        chain
        argDep
        onArgDepUpdated={newArgDep => {
          let newRequest = {
            ...request,
            variableDependencies: request.variableDependencies->Belt.Array.keepMap(
              variableDependency => {
                let dependency =
                  variableDependency.name == variableName
                    ? Chain.ArgumentDependency(newArgDep)
                    : variableDependency.dependency

                Some({...variableDependency, dependency: dependency})
              },
            ),
          }
          onRequestUpdated(newRequest)
        }}
      />
    | GraphQLProbe(probe) =>
      <GraphQLProbe
        request
        chain
        probe
        onArgDepUpdated={newProbe => {
          let newRequest = {
            ...request,
            variableDependencies: request.variableDependencies->Belt.Array.keepMap(
              variableDependency => {
                let dependency =
                  variableDependency.name == variableName
                    ? Chain.GraphQLProbe(newProbe)
                    : variableDependency.dependency

                Some({...variableDependency, dependency: dependency})
              },
            ),
          }
          onRequestUpdated(newRequest)
        }}
      />
    }
  }
}

let openedArrow =
  <div
    className="rounded-full border border border-indigo w-7 h-7 flex items-center justify-center bg-indigo">
    <svg
      ariaHidden=true
      fill="none"
      height="24"
      stroke="white"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="2"
      viewBox="0 0 24 24"
      width="24"
      xmlns="http://www.w3.org/2000/svg">
      <polyline points="18 15 12 9 6 15" />
    </svg>
  </div>

let closedArrow =
  <div className="rounded-full border border-grey w-7 h-7 flex items-center justify-center">
    <svg
      ariaHidden=true
      className=""
      fill="none"
      height="24"
      stroke="#606F7B"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="2"
      viewBox="0 0 24 24"
      width="24"
      xmlns="http://www.w3.org/2000/svg">
      <polyline points="6 9 12 15 18 9" />
    </svg>
  </div>

module Request = {
  @react.component
  let make = (
    ~request: Chain.request,
    ~chain: Chain.t,
    ~onChainUpdated,
    ~inspected as _: inspectable,
    ~schema: GraphQLJs.schema,
    ~onRequestCodeInspected,
    ~cachedResult: option<Js.Json.t>,
    ~onExecuteRequest,
    ~onLogin,
    ~requestValueCache,
    ~onDeleteEdge,
    ~onPotentialVariableSourceConnect,
    ~onDragStart,
  ) => {
    open React
    let connectionDrag = useContext(ConnectionContext.context)

    let (openedTabs, setOpenedTabs) = useState(() => Belt.Set.String.empty)
    let (mockedEvalResults, setMockedEvalResults) = useState(() => None)
    let (formVariables, setFormVariables) = React.useState(() => Js.Dict.empty())
    let (potentialConnection, setPotentialConnection) = React.useState(() => Belt.Set.String.empty)
    let domRef = React.useRef(Js.Nullable.null)

    let chainFragmentsDoc =
      chain.blocks
      ->Belt.Array.keepMap(block => {
        switch block.kind {
        | Fragment => Some(block.body)
        | _ => None
        }
      })
      ->Js.Array2.joinWith("\n\n")

    useEffect2(() => {
      let requestsWithLockedVariables = patchChainRequestsArgDeps(chain)
      let chain = {
        ...chain,
        requests: requestsWithLockedVariables,
      }

      let request = patchRequestArgDeps(request)

      evalRequest(~schema, ~chain, ~request, ~requestValueCache)->Js.Promise.then_(result => {
        setMockedEvalResults(_ =>
          switch result {
          | Ok(result) =>
            let variables = result->Obj.magic->Js.Dict.get("variables")
            variables->Belt.Option.map(variables => Ok(variables))
          | other => Some(other)
          }
        )->Js.Promise.resolve
      }, _)->ignore
      None
    }, (request->Js.Json.stringifyAny->Belt.Option.getExn, chain.script))

    let parsedOperation = request.operation.body->GraphQLJs.parse
    let definition = parsedOperation.definitions->Belt.Array.getExn(0)

    let variableNames = request.operation->Card.getFirstVariables

    let variables = variableNames->Belt.Array.map(((variableName, _variableType)) => {
      let varDep: Chain.variableDependency =
        request.variableDependencies
        ->Belt.Array.getBy(varDep => {
          varDep.name == variableName
        })
        ->Belt.Option.getWithDefault({
          name: variableName,
          dependency: Direct({name: variableName, value: JSON(j`""`->Js.Json.parseExn)}),
        })

      let isOpen = openedTabs->Belt.Set.String.has(varDep.name)

      <article
        key={variableName}
        id={"inspector-variable-" ++ variableName}
        className="m-2"
        onMouseEnter={event => {
          switch connectionDrag {
          | StartedSource(_) => setPotentialConnection(s => s->Belt.Set.String.add(variableName))
          | _ => ()
          }
        }}
        onMouseLeave={event => {
          switch connectionDrag {
          | StartedSource(_)
          | StartedTarget(_) =>
            setPotentialConnection(s => s->Belt.Set.String.remove(variableName))
          | _ => ()
          }
        }}
        onMouseDown={event => {
          switch event->ReactEvent.Mouse.altKey {
          | false => ()
          | true =>
            event->ReactEvent.Mouse.preventDefault
            event->ReactEvent.Mouse.stopPropagation
            switch connectionDrag {
            | Empty =>
              let sourceDom = event->ReactEvent.Mouse.target

              let connectionDrag: ConnectionContext.connectionDrag = StartedTarget({
                target: Variable({
                  targetRequest: request,
                  variableDependency: varDep,
                }),
                sourceDom: sourceDom->Obj.magic,
              })

              onDragStart(~connectionDrag)
              setPotentialConnection(s => s->Belt.Set.String.add(variableName))

            | _ => ()
            }
          }
        }}
        onMouseUp={event => {
          let clientX = event->ReactEvent.Mouse.clientX
          let clientY = event->ReactEvent.Mouse.clientY
          let mouseClientPosition = (clientX, clientY)
          setPotentialConnection(s => s->Belt.Set.String.remove(variableName))
          switch connectionDrag {
          | StartedSource({sourceRequest, sourceDom}) =>
            let connectionDrag = ConnectionContext.Completed({
              sourceRequest: sourceRequest,
              target: Variable({
                variableDependency: varDep,
                targetRequest: request,
              }),
              windowPosition: mouseClientPosition,
              sourceDom: sourceDom,
            })

            onPotentialVariableSourceConnect(~connectionDrag)
          | _ => ()
          }
        }}>
        <div
          className={"flex justify-between items-center cursor-pointer p-1  text-gray-200 " ++
          (isOpen ? "rounded-t-sm" : "rounded-sm") ++ (
            potentialConnection->Belt.Set.String.has(variableName)
              ? " bg-blue-600 border-blue-900"
              : ""
          )}
          onClick={_ => {
            setOpenedTabs(oldOpenedTabs =>
              isOpen
                ? oldOpenedTabs->Belt.Set.String.remove(varDep.name)
                : oldOpenedTabs->Belt.Set.String.add(varDep.name)
            )
          }}>
          <div
            style={ReactDOMStyle.make(~color=Comps.colors["green-4"], ())}
            className=" font-semibold text-sm font-mono inline-block flex-grow">
            {(j`\\$` ++ varDep.name)->string}
          </div>
          <select
            style={ReactDOMStyle.make(
              ~backgroundColor=Comps.colors["gray-7"],
              ~padding="6px",
              ~paddingRight="40px",
              ~color=Comps.colors["gray-4"],
              ~width="unset",
              ~borderRadius="6px",
              (),
            )}
            value={switch varDep.dependency {
            | ArgumentDependency(_) => "argument"
            | Direct({value: Variable(_)}) => "variable"
            | Direct({value: JSON(_)}) => "json"
            | GraphQLProbe(_) => "probe"
            }}
            onChange={event => {
              let newDependency: option<
                Chain.variableDependencyKind,
              > = switch ReactEvent.Form.target(event)["value"] {
              | "argument" =>
                Some(
                  ArgumentDependency({
                    functionFromScript: "INITIAL_UNKNOWN",
                    maxRecur: None,
                    ifMissing: #SKIP,
                    ifList: #FIRST,
                    fromRequestIds: [],
                    name: varDep.name,
                  }),
                )
              | "json" => Some(Direct({name: varDep.name, value: JSON(Js.Json.parseExn("{}"))}))
              | "variable" => Some(Direct({name: varDep.name, value: Variable(varDep.name)}))
              | _ => None
              }
              switch newDependency {
              | None => ()
              | Some(newDependency) =>
                let newVarDep = {...varDep, dependency: newDependency}

                let requestHasExistingVariableDependency =
                  request.variableDependencies->Belt.Array.some(existingVarDep =>
                    existingVarDep == varDep
                  )

                let newVariableDependencies = switch requestHasExistingVariableDependency {
                | false => request.variableDependencies->Belt.Array.concat([newVarDep])
                | true =>
                  request.variableDependencies->Belt.Array.map(existingVarDep =>
                    existingVarDep == varDep ? newVarDep : existingVarDep
                  )
                }

                let newRequest = {...request, variableDependencies: newVariableDependencies}
                let requests = chain.requests->Belt.Array.map(req => {
                  req == request ? newRequest : req
                })
                let newChain = {...chain, requests: requests}
                onChainUpdated(newChain)
                setOpenedTabs(oldOpenedTabs => oldOpenedTabs->Belt.Set.String.add(varDep.name))
              }
            }}>
            <option value={"variable"}> {"Variable Input"->string} </option>
            <option value={"argument"}> {"Computed Value"->string} </option>
            <option disabled=true value={"probe"}> {"GraphQL Probe"->string} </option>
          </select>
        </div>
        <div
          className={"text-grey-darkest p-2 bg-gray-600 text-gray-200 overflow-scroll rounded-b-sm " ++ (
            isOpen ? "" : "hidden"
          )}>
          <RequestArgument
            chain
            request
            variableName={varDep.name}
            defaultRequestArgument={varDep}
            onRequestUpdated={newRequest => {
              let newChain = {
                ...chain,
                requests: chain.requests->Belt.Array.keepMap(existingRequest => {
                  Some(existingRequest == request ? newRequest : existingRequest)
                }),
              }

              onChainUpdated(newChain)
            }}
          />
        </div>
      </article>
    })

    let upstreamRequests = request.dependencyRequestIds->Belt.Array.keepMap(upstreamRequestId => {
      let upstreamRequest =
        chain.requests->Belt.Array.getBy(existingRequest => existingRequest.id == upstreamRequestId)

      upstreamRequest->Belt.Option.map(upstreamRequest => {
        <article key={request.id ++ upstreamRequest.id} className="m-2">
          <div className={"flex justify-between items-center cursor-pointer p-1 rounded-sm"}>
            <span
              className="font-semibold text-sm font-mono pl-2"
              style={ReactDOMStyle.make(~color=Comps.colors["green-4"], ())}>
              {upstreamRequest.id->string}
            </span>
            <Comps.Button
              style={ReactDOMStyle.make(
                ~backgroundColor=Comps.colors["gray-7"],
                ~color=Comps.colors["gray-4"],
                (),
              )}
              onClick={event => {
                event->ReactEvent.Mouse.stopPropagation
                event->ReactEvent.Mouse.preventDefault
                onDeleteEdge(~targetRequestId=request.id, ~dependencyId=upstreamRequestId)
              }}>
              <Icons.Trash color={Comps.colors["gray-4"]} className="inline mr-2" />
              {"Remove Dependency"->string}
            </Comps.Button>
          </div>
        </article>
      })
    })

    let editor = React.useRef(None)

    let compiledDoc = chain->Chain.compileOperationDoc

    let content = compiledDoc.operationDoc

    React.useEffect1(() => {
      editor.current->Belt.Option.forEach(editor => editor->BsReactMonaco.setValue(content))
      None
    }, [content])

    let inputs =
      request.operation
      ->Card.getFirstVariables
      ->Belt.Array.map(((name, typ)) => {
        let def: GraphQLJs.variableDefinition = {
          variable: {
            name: {
              value: name,
              kind: "Name",
              loc: None,
            },
          },
          typ: typ->GraphQLJs.parseType->Obj.magic,
        }

        formInput(
          schema,
          def,
          setFormVariables,
          formInputOptions(~labelClassname="underline pl-2 m-2 mt-0 mb-0", ()),
        )
      })

    let form =
      inputs->Belt.Array.length > 0
        ? <form
            onSubmit={event => {
              event->ReactEvent.Form.preventDefault
              event->ReactEvent.Form.stopPropagation
              onExecuteRequest(~request, ~variables=formVariables)
            }}>
            {inputs->React.array}
            <Comps.Button type_="submit"> {"Execute"->React.string} </Comps.Button>
          </form>
        : React.null

    let missingAuthServices = cachedResult->Belt.Option.mapWithDefault([], results => {
      let services = OneGraphAuth.findMissingAuthServices(Some(results))

      services
    })

    let authButtons = missingAuthServices->Belt.Array.map(service => {
      <Comps.Button
        key={service}
        onClick={_ => {
          onLogin(service)
        }}>
        {("Log into " ++ service)->React.string}
      </Comps.Button>
    })

    <div className="max-h-full overflow-y-scroll" ref={ReactDOM.Ref.domRef(domRef)}>
      {variables->Belt.Array.length > 0
        ? <>
            <Comps.Header>
              <Icons.Caret className="inline mr-2" color={Comps.colors["gray-6"]} />
              {"Variable Settings"->React.string}
            </Comps.Header>
            {variables->array}
          </>
        : React.null}
      {variables->Belt.Array.length > 0
        ? <div>
            <Comps.Header onClick={_ => onRequestCodeInspected(~request)}>
              <Icons.Caret className="inline mr-2" color={Comps.colors["gray-6"]} />
              {"Computed Variable Preview"->string}
              <Icons.Export className="inline-block ml-2" />
            </Comps.Header>
            <Comps.Pre>
              {mockedEvalResults
              ->Belt.Option.map(r =>
                switch r {
                | Ok(d) => d
                | Error(d) => Obj.magic(d)
                }
                ->Obj.magic
                ->Js.Json.stringifyWithSpace(2)
              )
              ->Belt.Option.getWithDefault("Nothing")
              ->string}
            </Comps.Pre>
          </div>
        : React.null}
      {request.dependencyRequestIds->Belt.Array.length > 0
        ? <>
            <Comps.Header>
              <Icons.Caret className="inline mr-2" color={Comps.colors["gray-6"]} />
              {"Upstream Requests"->React.string}
            </Comps.Header>
            {upstreamRequests->array}
          </>
        : React.null}
      <Comps.Header>
        <Icons.Caret className="inline mr-2" color={Comps.colors["gray-6"]} />
        {"GraphQL Structure"->React.string}
      </Comps.Header>
      <div
        className="my-2 mx-4 p-2 rounded-sm text-gray-200 overflow-scroll"
        style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-8"], ~maxHeight="150px", ())}>
        <GraphQLPreview
          requestId=request.id
          schema
          definition
          fragmentDefinitions={GraphQLJs.Mock.gatherFragmentDefinitions({
            "operationDoc": chainFragmentsDoc,
          })}
          onCopy={path => {
            let dataPath = path->Js.Array2.joinWith("?.")
            let fullPath = "payload." ++ dataPath

            fullPath->Clipboard.copy
          }}
        />
      </div>
      <div>
        <Comps.Header
          onClick={_ => {
            onExecuteRequest(~request, ~variables=formVariables)
          }}>
          <Icons.Caret className="inline mr-2" color={Comps.colors["gray-6"]} />
          {"Execute block"->string}
          <Icons.Play className="inline-block ml-2" />
        </Comps.Header>
        {form}
        {authButtons->array}
        <Comps.Pre>
          {cachedResult
          ->Belt.Option.mapWithDefault("Nothing", json => json->Js.Json.stringifyWithSpace(2))
          ->string}
        </Comps.Pre>
      </div>
    </div>
  }
}

module ChainResultsViewer = {
  @react.component
  let make = (~chain as _, ~chainExecutionResults) => {
    let content =
      chainExecutionResults
      ->Belt.Option.map(json => Js.Json.stringifyWithSpace(json, 2))
      ->Belt.Option.getWithDefault("")

    let compiledChainViewerEditor = React.useRef(None)

    React.useEffect1(() => {
      compiledChainViewerEditor.current->Belt.Option.forEach(editor =>
        editor->BsReactMonaco.setValue(content)
      )
      None
    }, [content])

    let compiledChainViewer =
      <BsReactMonaco.Editor
        height="250px"
        className="h-auto"
        theme="vs-dark"
        language="graphql"
        defaultValue={content}
        options={
          "minimap": {"enabled": false},
        }
        onMount={(editorHandle, _monaco) => {
          compiledChainViewerEditor.current = Some(editorHandle)
          let options = BsReactMonaco.editorOptions(~readOnly=true, ())
          editorHandle->BsReactMonaco.updateOptions(options)
        }}
      />

    compiledChainViewer
  }
}

type state = {chainResult: option<string>}

module Nothing = {
  @react.component
  let make = (
    ~chain,
    ~schema,
    ~chainExecutionResults: option<Js.Json.t>,
    ~onLogin: string => unit,
    ~onPersistChain: unit => unit,
    ~transformAndExecuteChain,
    ~onDeleteRequest,
    ~onRequestInspected,
    ~savedChainId,
    ~oneGraphAuth,
  ) => {
    let compiledOperation = chain->Chain.compileOperationDoc

    let missingAuthServices =
      chainExecutionResults
      ->Belt.Option.map(findMissingAuthServicesFromChainResult)
      ->Belt.Option.getWithDefault([])

    let authButtons = missingAuthServices->Belt.Array.map(service => {
      <Comps.Button
        key={service}
        onClick={_ => {
          onLogin(service)
        }}>
        {("Log into " ++ service)->React.string}
      </Comps.Button>
    })

    let targetChain = compiledOperation.chains->Belt.Array.get(0)

    let (formVariables, setFormVariables) = React.useState(() => Js.Dict.empty())

    let form =
      targetChain
      ->Belt.Option.map(targetChain => {
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

          formInput(
            schema,
            def,
            setFormVariables,
            formInputOptions(~labelClassname="background-blue-400", ()),
          )
        })

        inputs->React.array
      })
      ->Belt.Option.getWithDefault(React.null)

    let isChainViable = chain.requests->Belt.Array.length > 0

    open React

    let requests = chain.requests->Belt.Array.map(request => {
      <article key={request.id} className="mx-2">
        <div className={"flex justify-between items-center cursor-pointer p-1 rounded-sm"}>
          <span
            className="font-semibold text-sm font-mono pl-2"
            style={ReactDOMStyle.make(~color=Comps.colors["green-4"], ())}
            onClick={_ => onRequestInspected(request)}>
            {request.id->string}
          </span>
          <Comps.Button
            style={ReactDOMStyle.make(
              ~backgroundColor=Comps.colors["gray-7"],
              ~color=Comps.colors["gray-4"],
              (),
            )}
            onClick={event => {
              event->ReactEvent.Mouse.stopPropagation
              event->ReactEvent.Mouse.preventDefault
              let confirmation = Debug.confirm(j`Really delete "${request.operation.title}"?`)

              switch confirmation {
              | false => ()
              | true => onDeleteRequest(request)
              }
            }}>
            <Icons.Trash color={Comps.colors["gray-4"]} className="inline mr-2" />
            {"Delete Request"->string}
          </Comps.Button>
        </div>
      </article>
    })

    <>
      {form}
      {authButtons->React.array}
      {
        // <pre className="m-2 p-2 bg-gray-600 rounded-sm text-gray-200 overflow-scroll select-all">
        //   {formVariables->Obj.magic->Js.Json.stringifyWithSpace(2)->React.string}
        // </pre>
        isChainViable
          ? <>
              <Comps.Button
                onClick={_ => {
                  let variables = Some(formVariables->Obj.magic)

                  transformAndExecuteChain(~variables)
                }}>
                {"Run chain"->React.string}
              </Comps.Button>
              {chainExecutionResults
              ->Belt.Option.map(chainExecutionResults =>
                <ChainResultsViewer chain chainExecutionResults={Some(chainExecutionResults)} />
              )
              ->Belt.Option.getWithDefault(React.null)}
              <Comps.Button
                onClick={_ => {
                  onPersistChain()
                }}>
                {"Save Chain"->React.string}
              </Comps.Button>
            </>
          : {"Add some blocks to get started"->React.string}
      }
      {savedChainId
      ->Belt.Option.map(chainId => {
        <select
          className="w-full focus:outline-none text-white text-sm py-2.5 px-5 border-b-4 border-gray-600 rounded-md bg-gray-500 hover:bg-gray-400 m-2"
          value=""
          onChange={event => {
            let chain = chainId->Chain.loadFromLocalStorage

            let appId = oneGraphAuth->OneGraphAuth.appId

            let remoteChainCalls = remoteChainCalls(~appId, ~chainId, chain->Belt.Option.getExn)

            let value = switch ReactEvent.Form.target(event)["value"] {
            | "form" => Some(j`http://localhost:3003/form?form_id=${chainId}`)
            | "fetch" => Some(remoteChainCalls.fetch)
            | "curl" => Some(remoteChainCalls.curl)
            | "netlify" => Some(remoteChainCalls.netlify)
            | "scriptkit" => Some(remoteChainCalls.scriptKit)
            | _ => None
            }
            value->Belt.Option.forEach(Clipboard.copy)
          }}>
          <option value=""> {"> Copy usage"->React.string} </option>
          <option value={"form"}> {"Copy link to form"->React.string} </option>
          <option value={"fetch"}> {"Copy fetch call"->React.string} </option>
          <option value={"curl"}> {"Copy cURL call"->React.string} </option>
          <option value={"netlify"}> {"Copy Netlify function usage"->React.string} </option>
          <option value={"scriptkit"}> {"Copy ScriptKit usage"->React.string} </option>
        </select>
      })
      ->Belt.Option.getWithDefault(React.null)}
      {requests->Belt.Array.length > 0
        ? <> <Comps.Header> {"Chain Requests"->React.string} </Comps.Header> {requests->array} </>
        : React.null}
      // <Comps.Header> {"Internal Debug info"->React.string} </Comps.Header>
      // <pre className="m-2 p-2 bg-gray-600 rounded-sm text-gray-200 overflow-scroll select-all">
      //   {chain->Obj.magic->Js.Json.stringifyWithSpace(2)->React.string}
      // </pre>
      // <Comps.Header> {"Compiled Executable Chain"->React.string} </Comps.Header>
      // <pre className="m-2 p-2 bg-gray-600 rounded-sm text-gray-200 overflow-scroll select-all">
      //   {
      //     let transformed = chain->internallyPatchChain
      //     let script = transformed.script

      //     // let script = Obj.magic(transformed)["script"]

      //     // script->Js.Json.string->Js.Json.stringifyWithSpace(2)->React.string
      //     script->React.string
      //   }
      // </pre>
    </>
  }
}

let activeTabClasses = "text-gray-600 py-4 px-6 block hover:text-blue-500 focus:outline-none text-blue-500 border-b-2 font-medium border-blue-500"
let inactiveTabClass = "text-white py-4 px-6 block hover:text-blue-500 focus:outline-none"

@react.component
let make = (
  ~inspected: inspectable,
  ~onAddBlock: Card.block => unit,
  ~onChainUpdated: Chain.t => unit,
  ~onReset: unit => unit,
  ~chain: Chain.t,
  ~schema: GraphQLJs.schema,
  ~chainExecutionResults: option<Js.Json.t>,
  ~onLogin: string => unit,
  ~transformAndExecuteChain,
  ~onPersistChain,
  ~savedChainId: option<string>,
  ~onRequestCodeInspected,
  ~onExecuteRequest,
  ~requestValueCache,
  ~onDeleteRequest,
  ~onDeleteEdge,
  ~onRequestInspected,
  ~oneGraphAuth,
  ~onPotentialVariableSourceConnect,
  ~onDragStart,
) => {
  open React

  <div
    className="h-screen text-white border-l border-gray-800"
    style={ReactDOMStyle.make(~backgroundColor="rgb(27,29,31)", ())}>
    <div>
      <nav className="flex flex-row py-1 px-2 mb-2">
        <button
          className={"text-left text-gray-600 hover:text-blue-500 focus:outline-none text-blue-500 flex-grow"}>
          {switch inspected {
          | Nothing(_) => "Inspector"
          | Block({title}) => "Block." ++ title
          | Request({request}) => request.id
          | RequestArgument(_) => "Request Argument"
          }->string}
        </button>
        {switch inspected {
        | Nothing(_) => null
        | _ => <span className="text-white" onClick={_ => onReset()}> {"X"->React.string} </span>
        }}
      </nav>
    </div>
    <div className="max-h-screen overflow-y-scroll">
      {switch inspected {
      | Nothing(chain) =>
        <Nothing
          chain
          schema
          chainExecutionResults
          onLogin
          transformAndExecuteChain
          onPersistChain
          savedChainId
          onDeleteRequest
          onRequestInspected
          oneGraphAuth
        />
      | Block(block) => <Block schema block onAddBlock />
      | Request({request})
      | RequestArgument({request}) =>
        let cachedResult = requestValueCache->Js.Dict.get(request.id)
        <Request
          inspected
          onRequestCodeInspected
          chain
          request
          onChainUpdated
          schema
          cachedResult
          onLogin
          onExecuteRequest
          requestValueCache
          onDeleteEdge
          onPotentialVariableSourceConnect
          onDragStart
        />
      }}
    </div>
  </div>
}
