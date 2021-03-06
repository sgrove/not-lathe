let special_token = "XlMpa0MEz1ZMIYtebUGttQpV9I8CCwL5VejNbfStd2c"

module AdvancedMode = {
  let enabled = false
}

module Clipboard = {
  @module("copy-to-clipboard") external copy: string => unit = "default"
}

module GraphQLPreview = {
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
}

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

let forceablySetInputValue = (node, value) => {
  let helper = %raw(`function(node, value) {
  // only process the change on elements we know have a value setter in their constructor
const inputTypes =  [
    window.HTMLInputElement,
    window.HTMLSelectElement,
    window.HTMLTextAreaElement,
]

  if ( inputTypes.indexOf(node.__proto__.constructor) >-1 ) {

        const setValue = Object.getOwnPropertyDescriptor(node.__proto__, 'value').set;
        const event = new Event('input', { bubbles: true });

        setValue.call(node, value);
        node.dispatchEvent(event);

    }}`)

  helper(node, value)
}

type inspectable =
  | Nothing({chain: Chain.t, trace: option<Chain.Trace.t>})
  | Block(Card.block)
  | Request({chain: Chain.t, request: Chain.request})
  | RequestArgument({chain: Chain.t, request: Chain.request, variableName: string})

type netlifyRemoteChainCall = {
  path: string,
  form: string,
  code: string,
}

type nextjsRemoteChainCall = {
  path: string,
  code: string,
}

type remoteChainCalls = {
  fetch: string,
  curl: string,
  scriptKit: string,
  netlify: netlifyRemoteChainCall,
  nextjs: nextjsRemoteChainCall,
}

type mockRequestValueVariable = {
  name: string,
  value: Js.Json.t,
}

type mockRequestValues = {
  variables: Js.Json.t,
  graphQLResult: GraphQLJs.queryResult,
}

module CollapsableSection = {
  @react.component
  let make = (~title, ~defaultOpen=true, ~children) => {
    open React
    let (isOpen, setIsOpen) = useState(() => defaultOpen)

    <>
      <Comps.Header
        onClick={_ => setIsOpen(isOpen => !isOpen)}
        style={ReactDOMStyle.make(~cursor="pointer", ~color=Comps.colors["gray-6"], ())}>
        {isOpen
          ? <Icons.CaretUp className="inline mr-2" color={Comps.colors["gray-6"]} />
          : <Icons.CaretRight className="inline mr-2" color={Comps.colors["gray-6"]} />}
        title
      </Comps.Header>
      <div className={isOpen ? "" : "hidden"}> {children} </div>
    </>
  }
}

let checkFunctionExists = (~parsed=?, ~script: string, ~request: Chain.request): bool => {
  let names = request->Chain.requestScriptNames

  let parsed = switch parsed {
  | None =>
    try {
      Some(TypeScript.createSourceFile(~name="main.ts", ~source=script, ~target=99, true))
    } catch {
    | _ => None
    }
  | other => other
  }

  switch parsed {
  | None =>
    script
    ->Js.String2.match_(Js.Re.fromString(j`export function ${names.functionName}`))
    ->Belt.Option.isSome
  | Some(parsed) => parsed->TypeScript.findFnPos(names.functionName)->Belt.Option.isSome
  }
}

let ensureRequestFunctionExists = (
  ~parsed=?,
  ~returnProperties=?,
  ~script: string,
  ~request: Chain.request,
  (),
) => {
  let names = request->Chain.requestScriptNames

  let nameExistsInScript = checkFunctionExists(~parsed?, ~script, ~request)

  let returnProperties =
    returnProperties
    ->Belt.Option.getWithDefault([])
    ->Belt.Array.joinWith(", ", ((key, value)) => j`${key}: ${value}`)

  nameExistsInScript
    ? script
    : script ++
      j`

export function ${names.functionName} (payload : ${names.inputTypeName}) : ${names.returnTypeName} {
  /** TODO: Define ${returnProperties} */
  return {${returnProperties}}
}`
}

let deleteRequestFunctionIfEmpty = (
  ~parsed=?,
  ~script: string,
  ~request: Chain.request,
  (),
): result<string, [#invalidSyntax]> => {
  let names = request->Chain.requestScriptNames

  let parsed = switch parsed {
  | None =>
    try {
      Some(TypeScript.createSourceFile(~name="main.ts", ~source=script, ~target=99, true))
    } catch {
    | _ => None
    }
  | other => other
  }

  switch parsed {
  | None => Error(#invalidSyntax)
  | Some(parsed) =>
    switch parsed->TypeScript.isFunctionEmpty(names.functionName) {
    | None
    | Some(NotEmpty) =>
      Ok(script)
    | Some(Empty)
    | Some(EmptyObjectReturn)
    | Some(ProbablyGenerated) =>
      Ok(
        parsed
        ->TypeScript.findFnPos(names.functionName)
        ->Belt.Option.mapWithDefault(script, ({start, end}) => {
          script->Utils.String.replaceRange(~start, ~end, ~by="")->Js.String2.trim
        }),
      )
    }
  }
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
  ~requestValueCache: RequestValueCache.t,
  ~trace: option<Chain.Trace.t>,
): Js.Promise.t<result<mockRequestValues, 'err>> => {
  QuickJsEmscripten.getQuickJS()->Js.Promise.then_(quickjs => {
    Debug.assignToWindowForDeveloperDebug(~name="existingTrace", trace)

    let payload =
      request.variableDependencies
      ->Belt.Array.keepMap(varDep =>
        switch varDep.dependency {
        | ArgumentDependency(argDep) => Some(argDep.fromRequestIds)
        | GraphQLProbe(probe) => Some([probe.fromRequestId])
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

          let traceValue = trace->Belt.Option.flatMap(trace => {
            try {
              let results = Obj.magic(trace.trace)["data"]["oneGraph"]["executeChain"]["results"]
              Debug.assignToWindowForDeveloperDebug(
                ~name="variable_upstream_" ++ nextRequest.id,
                results,
              )
              let returnedTrace =
                results
                ->Belt.Array.getBy(result => result["request"]["id"] == nextRequest.id)
                ->Belt.Option.flatMap(request => request["result"][0])
              returnedTrace
            } catch {
            | _ => None
            }
          })

          switch (requestValueCache->Js.Dict.get(nextRequest.id), traceValue) {
          | (Some(results), _) =>
            acc->Js.Dict.set(
              nextRequest.id,
              {variables: variables, graphQLResult: results->Obj.magic},
            )
            acc
          | (_, Some(traceValue)) =>
            acc->Js.Dict.set(
              nextRequest.id,
              {variables: variables, graphQLResult: traceValue->Obj.magic},
            )
            acc

          | (None, None) =>
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
      | GraphQLProbe(probe) =>
        let call = `${probe.functionFromScript}(${payload})`

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
  }, _)->Js.Promise.catch(err => {
    Js.Console.warn2("Error evalRequest: ", err)
    Js.Promise.resolve(Error(err))
  }, _)
}

let babelTranspile = (script, ~filename, ~runId) => {
  let code = script

  try {
    let transformResult = Babel.transform(
      code,
      ~options={
        "filename": filename,
        "plugins": {
          open Babel
          [
            (typescriptPlugin, pluginOptions({"allExtensions": true})),
            (optionalChainingPlugin, pluginOptions({"allExtensions": true})),
            (Insight.babelTransform, pluginOptions({"runId": runId})),
          ]
        },
      },
    )

    let transformResult = {
      ...transformResult,
      code: transformResult.code->Js.String2.replaceByRe(
        Js.Re.fromStringWithFlags("export ", ~flags="g"),
        "",
      ),
    }

    Ok(transformResult)
  } catch {
  | err =>
    Js.Console.warn2("Exception while hyperevaling", err)
    Error(err)
  }
}

let babelInvocations = (
  ~schema,
  ~trace: option<Chain.Trace.t>,
  ~chain: Chain.t,
  ~requestValueCache: RequestValueCache.t,
) => {
  let calls = chain.requests->Belt.Array.map(request => {
    let names = request->Chain.requestScriptNames

    let upstreamRequests = request.dependencyRequestIds->Belt.Array.keepMap(upstreamRequestId => {
      chain.requests->Belt.Array.getBy(request => request.id == upstreamRequestId)
    })

    let payload = upstreamRequests->Belt.Array.reduce(Js.Dict.empty(), (acc, nextRequest) => {
      switch acc->Js.Dict.get(nextRequest.id) {
      | Some(_) => acc
      | None =>
        let parsedOperation = nextRequest.operation.body->GraphQLJs.parse
        let definition = parsedOperation.definitions->Belt.Array.getExn(0)

        let variables = GraphQLJs.Mock.mockOperationVariables(schema, definition->Obj.magic)

        let traceValue = trace->Belt.Option.flatMap(trace => {
          try {
            let results = Obj.magic(trace.trace)["data"]["oneGraph"]["executeChain"]["results"]
            Debug.assignToWindowForDeveloperDebug(
              ~name="variable_upstream_" ++ nextRequest.id,
              results,
            )
            let returnedTrace =
              results
              ->Belt.Array.getBy(result => result["request"]["id"] == nextRequest.id)
              ->Belt.Option.flatMap(request => request["result"][0])
            returnedTrace
          } catch {
          | _ => None
          }
        })

        switch (requestValueCache->Js.Dict.get(nextRequest.id), traceValue) {
        | (Some(results), _) =>
          acc->Js.Dict.set(
            nextRequest.id,
            {variables: variables, graphQLResult: results->Obj.magic},
          )
          acc
        | (_, Some(traceValue)) =>
          acc->Js.Dict.set(
            nextRequest.id,
            {variables: variables, graphQLResult: traceValue->Obj.magic},
          )
          acc

        | (None, None) =>
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

    let simplifiedPayload =
      payload
      ->Js.Dict.entries
      ->Belt.Array.map(((key, value)) => {
        (key, value.graphQLResult)
      })
      ->Js.Dict.fromArray

    j`try {
${names.functionName}(${simplifiedPayload->Obj.magic->Js.Json.stringify})
} catch (e) {
  console.warn("${names.functionName} error: ", e)
}`
  })

  calls
}

let evalBabelInQuick = (
  ~transformResult: Babel.transformResult,
  ~insight: Babel.Insight.insight,
  ~onSuccess,
  ~onError,
) => {
  let store = insight.store

  let evalResults = Babel.Insight.asyncHyperEval(
    ~transformResult=Ok(transformResult),
    ~runner=Babel.Insight.wasmQuickJSRunner,
  )

  switch evalResults {
  | Error(err) => onError(err)
  | Ok(evalResults) =>
    open Babel.Insight
    let r = evalResults->Js.Promise.then_(results => {
        results->Belt.Array.forEach(record => {
          store->addRecord(record)
        })
        onSuccess(~results, ~store)->Js.Promise.resolve
      }, _)->ignore
    r
  }
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

let webhookUrlForAppId = (~appId) => {
  j`https://websmee.com/hook/${appId}`
}

let remoteChainCalls = (~schema, ~appId, ~chainId, chain: Chain.t) => {
  let webhookUrl = webhookUrlForAppId(~appId)
  let compiled = chain->transformChain(~schema, ~webhookUrl)
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

  let variableParams =
    targetChain.exposedVariables
    ->Belt.Array.map(exposed => {
      let key = exposed.exposedName
      key
    })
    ->Js.Array2.joinWith(", ")

  let curl = j`curl -X POST "https://serve.onegraph.com/graphql?app_id=${appId}" --data '{"doc_id": "${chainId}", "operationName": "${targetChain.operationName}", "variables": {${freeVariables}}}'`

  let fetch = j`async function ${chain.name} ({${variableParams}}) {
  await fetch("https://serve.onegraph.com/graphql?app_id=${appId}",
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
  )
}`

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

  // When the method is POST, the name will no longer be in the event???s
  // queryStringParameters ??? it???ll be in the event body encoded as a query string
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

  let netlify = {
    path: j`functions/${chain.name}.js`,
    form: netlifyHtml,
    code: netlifyScript,
  }

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

  let nextJsVariableCoerced =
    targetChain.exposedVariables
    ->Belt.Array.map(exposed => {
      let key = exposed.exposedName
      let coerce = switch exposed.upstreamType {
      | "String"
      | "String!" => key
      | "Int"
      | "Int!" =>
        j`parseInt(${key}) || 0`
      | "Float"
      | "Float!" =>
        j`parseFloat(${key}) || 0.0`
      | "Boolean"
      | "Boolean!" =>
        j`${key}?.trim() === "true"`
      | "JSON"
      | "JSON!" =>
        j`JSON.parse(${key})`
      | _other => key
      }

      j`${key}: ${coerce}`
    })
    ->Js.Array2.joinWith(",\n\t")

  let nextjsScript = j`const fetch = require("node-fetch");

async function ${chain.name} ({${variableParams}}) {
  const resp = await fetch("https://serve.onegraph.com/graphql?app_id=${appId}",
    {
      method: "POST",
      "Content-Type": "application/json",
      body: JSON.stringify({
        "doc_id": "${chainId}",
        "operationName": "${targetChain.operationName}",
        "variables": {${nextJsVariableCoerced}}
        }
      )
    }
  )

  return resp.json()
}

export default async function handler(req, res) {
  /* If not using GET, be sure to set the header "Content-Type: application/json"
     for requests to your Next.js API */
  const { query, ${variableParams} } = req.method === 'GET' ? req.query : req.body

  const result = await ${chain.name}({ ${variableParams} })

  let errors = result.errors || [];

  // Gather all of the errors from the nodes in the request chain
  result?.data?.oneGraph?.executeChain?.results?.forEach((call) => {
    const requestId = call.request.id

    const requestErrors =
      call?.result?.flatMap((result) => result?.errors)?.filter(Boolean) || []

    const callArgumentDependencyErrors =
      call?.argumentDependencies
        ?.filter((argumentDependency) => !!argumentDependency?.error)
        ?.map((argumentDependency) => {
          return {
            name: requestId + '.' + argumentDependency.name,
            errors: argumentDependency.error,
          }
        })
        ?.filter(Boolean) || []

    if (requestErrors.length > 0 || callArgumentDependencyErrors.length > 0) {
      console.warn('Error in requestId=', requestId, requestErrors, errors)
      errors = errors
        .concat(requestErrors)
        .concat(callArgumentDependencyErrors)
        .filter(Boolean)
    }
  })

  // No errors present means the chain executed well
  if ((errors || []).length === 0) {
    res.status(200).json({
      success: true
    })
  } else {
    if ((result.errors || []).length > 0) {
      console.warning("Error in executing chain ${chain.name}", errors)
    }
    res.status(500).json({ message: "Error executing chain" })
  }
}`

  let nextjs = {
    path: j`pages/api/${chain.name}.js`,
    code: nextjsScript,
  }

  {
    curl: curl,
    fetch: fetch,
    scriptKit: scriptKit,
    netlify: netlify,
    nextjs: nextjs,
  }
}

let transformAndExecuteChain = (chain, ~schema, ~oneGraphAuth, ~variables) => {
  let webhookUrl = webhookUrlForAppId(~appId=oneGraphAuth->OneGraphAuth.appId)

  let compiled = chain->transformChain(~schema, ~webhookUrl)

  let targetChain = compiled.chains->Belt.Array.getUnsafe(0)

  let promise = OneGraphRe.fetchOneGraph(
    oneGraphAuth,
    compiled.operationDoc,
    Some(targetChain.operationName),
    variables,
  )

  promise
}

// let transformAndExecuteChainSubscription = (
//   chain,
//   ~schema,
//   ~subscriptionClient: OneGraphSubscriptionClient.t,
//   ~variables,
//   ~onData,
//   ~onError,
//   ~onClosed,
// ) => {
//   let webhookUrl = webhookUrlForAppId(~appId=oneGraphAuth->OneGraphAuth.appId)
//   let compiled = chain->transformChain(~schema, ~appId)

//   let targetChain = compiled.chains->Belt.Array.getUnsafe(0)

//   let payload: OneGraphSubscriptionClient.operationOptions<'a, 'b> = {
//     query: compiled.operationDoc,
//     operationName: targetChain.operationName,
//     variables: variables,
//     context: None,
//   }

//   Js.log(targetChain.operationName)
//   Js.log(compiled.operationDoc)
//   Js.log(variables)

//   subscriptionClient
//   ->OneGraphSubscriptionClient.request(payload)
//   ->OneGraphSubscriptionClient.subscribe(~onData, ~onError, ~onClosed)
// }

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

    <div className="flex flex-col">
      <Comps.Pre
        style={ReactDOMStyle.make(~maxHeight="unset", ~whiteSpace="pre", ())} className="flex-1">
        {block.body->React.string}
      </Comps.Pre>
      <Comps.Button onClick={_ => onAddBlock(block)} className="w-full">
        <Icons.Mediation color={Comps.colors["gray-6"]} className="inline-block" />
        {"Add block to chain"->React.string}
      </Comps.Button>
    </div>
  }
}

type repoNode = {
  id: string,
  nameWithOwner: string,
}

type repoEdge = {node: repoNode}

type projectTypeGuess = option<OneGraphRe.GitHub.projectType>

module GitHub = {
  type state = {
    repoList: option<array<repoEdge>>,
    selectedRepo: option<repoEdge>,
    repoProjectGuess: projectTypeGuess,
  }

  @react.component
  let make = (~schema, ~chain: Chain.t, ~savedChainId, ~oneGraphAuth) => {
    let loadedChain = Some(chain)
    // Chain.loadFromLocalStorage()->Belt.Array.getBy(chain =>
    //   chain.id == savedChainId->Belt.Option.map(Uuid.parseExn)
    // )

    let appId = oneGraphAuth->OneGraphAuth.appId

    open React

    let remoteChainCalls =
      savedChainId->Belt.Option.flatMap(chainId =>
        loadedChain->Belt.Option.map(loadedChain =>
          remoteChainCalls(~schema, ~appId, ~chainId, loadedChain)
        )
      )

    let (state, setState) = React.useState(() => {
      repoList: None,
      selectedRepo: None,
      repoProjectGuess: None,
    })

    React.useEffect0(() => {
      Debug.assignToWindowForDeveloperDebug(
        ~name="guessGitHubProject",
        OneGraphRe.GitHub.guessProjecType,
      )
      OneGraphRe.basicFetchOneGraphPersistedQuery(
        ~appId="993a3e2d-de45-44fa-bff4-0c58c6150cbf",
        ~accessToken=None,
        ~docId="fc839e0e-982b-43fc-b59b-3c080e17480a",
        ~operationName=Some("ExecuteChainMutation_look_ma_connections"),
        ~variables=None,
      )
      ->Js.Promise.then_(result => {
        Obj.magic(result)["data"]
        ->Js.Undefined.toOption
        ->Belt.Option.forEach(data => {
          try {
            data["oneGraph"]["executeChain"]["results"]
            ->Belt.Array.getBy(result => result["request"]["id"] == "ListMyRepositories")
            ->Belt.Option.forEach(request => {
              let repos = request["result"][0]["data"]["me"]["github"]["repositories"]["edges"]
              setState(oldState => {
                {...oldState, repoList: repos}
              })
            })
          } catch {
          | ex =>
            Js.Console.warn2("Exception while fetching GitHub Repo list", ex)
            ()
          }
        })
        ->Js.Promise.resolve
      }, _)
      ->ignore

      None
    })

    {
      state.repoList->Belt.Option.mapWithDefault(React.null, repoList => {
        <>
          <div
            className=" text-center" style={ReactDOMStyle.make(~color=Comps.colors["gray-4"], ())}>
            {"- OR -"->React.string}
          </div>
          <Comps.Select
            style={ReactDOMStyle.make(~width="100%", ~margin="10px", ())}
            value={state.selectedRepo->Belt.Option.mapWithDefault("", repo => repo.node.id)}
            onChange={event => {
              let id = ReactEvent.Form.target(event)["value"]
              let repo = state.repoList->Belt.Option.flatMap(repoList =>
                repoList->Belt.Array.getBy(repoEdge => {
                  repoEdge.node.id == id
                })
              )
              setState(oldState => {...oldState, selectedRepo: repo, repoProjectGuess: None})
              repo->Belt.Option.forEach(repo => {
                switch repo.node.nameWithOwner->Js.String2.split("/") {
                | [owner, name] =>
                  OneGraphRe.GitHub.guessProjecType(~owner, ~name)->Js.Promise.then_(result => {
                    setState(oldState => {
                      ...oldState,
                      repoProjectGuess: Some(result),
                    })->Js.Promise.resolve
                  }, _)->ignore
                | _ => ()
                }
              })
            }}>
            <option value="" />
            {repoList
            ->Belt.Array.map(repoEdge => {
              <option value={repoEdge.node.id}>
                {repoEdge.node.nameWithOwner->React.string}
              </option>
            })
            ->array}
          </Comps.Select>
          <Comps.Button
            disabled={state.repoProjectGuess->Belt.Option.isNone ||
              savedChainId->Belt.Option.isNone}
            className="w-full"
            onClick={_ =>
              remoteChainCalls->Belt.Option.forEach(remoteChainCalls => {
                state.repoProjectGuess->Belt.Option.forEach(repoProjectGuess => {
                  state.selectedRepo->Belt.Option.forEach(repo => {
                    switch repo.node.nameWithOwner->Js.String2.split("/") {
                    | [owner, name] =>
                      let content = switch repoProjectGuess {
                      | Unknown =>
                        remoteChainCalls.fetch->Prettier.format({
                          "parser": "babel",
                          "plugins": [Prettier.babel],
                          "singleQuote": true,
                        })
                      | Netlify(#any) =>
                        let code = remoteChainCalls.netlify.code

                        let fmt = s =>
                          s->Prettier.format({
                            "parser": "babel",
                            "plugins": [Prettier.babel],
                            "singleQuote": true,
                          })

                        Debug.assignToWindowForDeveloperDebug(~name="nextjscode", code)
                        Debug.assignToWindowForDeveloperDebug(~name="pfmt", fmt)

                        code->Prettier.format({
                          "parser": "babel",
                          "plugins": [Prettier.babel],
                          "singleQuote": true,
                        })
                      | Netlify(#nextjs)
                      | Nextjs =>
                        let code = remoteChainCalls.nextjs.code

                        let fmt = s =>
                          s->Prettier.format({
                            "parser": "babel",
                            "plugins": [Prettier.babel],
                            "singleQuote": true,
                          })

                        Debug.assignToWindowForDeveloperDebug(~name="nextjscode", code)
                        Debug.assignToWindowForDeveloperDebug(~name="pfmt", fmt)

                        code->Prettier.format({
                          "parser": "babel",
                          "plugins": [Prettier.babel],
                          "singleQuote": true,
                        })
                      }

                      let path = switch repoProjectGuess {
                      | Unknown => j`src/${chain.name}.js`
                      | Netlify(#any) => remoteChainCalls.netlify.path
                      | Netlify(#nextjs)
                      | Nextjs =>
                        remoteChainCalls.nextjs.path
                      }

                      let file = {
                        OneGraphRe.GitHub.path: path,
                        content: content,
                        mode: "100644",
                      }

                      OneGraphRe.GitHub.pushToRepo({
                        "owner": owner,
                        "name": name,
                        "branch": "onegraph-studio",
                        "treeFiles": [file],
                        "message": "Automated push for " ++ chain.name,
                        "acceptOverrides": true,
                      })
                      ->Js.Promise.then_(result => {
                        Js.log2("GitHub push result: ", result)->Js.Promise.resolve
                      }, _)
                      ->ignore
                    | _ => ()
                    }
                  })
                })
              })}>
            {switch (savedChainId, state.selectedRepo, state.repoProjectGuess) {
            | (None, _, _) => "Persist chain to push to GitHub"->string
            | (_, None, _) => "Select a GitHub repository"->string
            | (_, _, None) => "Determining project type..."->string
            | (Some(_), Some(_), Some(projectGuess)) =>
              let target = switch projectGuess {
              | Unknown => "repo"
              | Netlify(#nextjs)
              | Nextjs => "next.js project"
              | Netlify(#any) => "Netlify functions"
              }
              <>
                <Icons.Login className="inline-block" color={Comps.colors["gray-6"]} />
                {j`  Push chain to ${target} on GitHub`->string}
              </>
            }}
          </Comps.Button>
        </>
      })
    }
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
          <div className="mt-1 flex rounded-md">
            <div className="flex-1 flex-grow" />
            <div
              style={ReactDOMStyle.make(
                ~backgroundColor=Comps.colors["brown-1"],
                ~color=Comps.colors["gray-4"],
                (),
              )}
              className="inline-flex justify-end items-center text-right px-3 rounded-l-md text-sm">
              {"$variableName:"->string}
            </div>
            <input
              style={ReactDOMStyle.make(
                ~backgroundColor=Comps.colors["gray-7"],
                ~minWidth="10ch",
                ~borderTopLeftRadius="0px",
                ~borderBottomLeftRadius="0px",
                (),
              )}
              className="block px-3 text-gray-500 rounded-md shadow-sm focus:outline-none focus:ring-blue-300 focus:border-blue-300 sm:text-sm rounded-l-none"
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
          <div className="flex rounded-md">
            <div className="flex-1 flex-grow" />
            <div
              style={ReactDOMStyle.make(
                ~backgroundColor=Comps.colors["brown-1"],
                ~color=Comps.colors["gray-4"],
                (),
              )}
              className="inline-flex justify-end items-center text-right px-3 rounded-l-md text-sm">
              {"ifMissing:"->string}
            </div>
            <Comps.Select
              style={ReactDOMStyle.make(
                ~borderTopLeftRadius="0px",
                ~borderBottomLeftRadius="0px",
                (),
              )}
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
            </Comps.Select>
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
            <div className="flex-1 flex-grow" />
            <div
              style={ReactDOMStyle.make(
                ~backgroundColor=Comps.colors["brown-1"],
                ~color=Comps.colors["gray-4"],
                (),
              )}
              className="inline-flex justify-end items-center text-right px-3 rounded-l-md text-sm">
              {"ifMissing:"->string}
            </div>
            <Comps.Select
              value={probe.ifMissing->Obj.magic}
              style={ReactDOMStyle.make(
                ~borderTopLeftRadius="0px",
                ~borderBottomLeftRadius="0px",
                (),
              )}
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
            </Comps.Select>
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

type authTokenDisplay = {
  accessToken: string,
  displayedToken: string,
  name: string,
}

module Request = {
  @react.component
  let make = (
    ~appId,
    ~request: Chain.request,
    ~chain: Chain.t,
    ~onChainUpdated,
    ~inspected as _: inspectable,
    ~schema: GraphQLJs.schema,
    ~onRequestCodeInspected,
    ~cachedResult: option<GraphQLJs.queryResult>,
    ~onExecuteRequest,
    ~onLogin,
    ~requestValueCache,
    ~onDeleteEdge,
    ~onPotentialVariableSourceConnect,
    ~onDragStart,
    ~trace: option<Chain.Trace.t>,
    ~authTokens: array<authTokenDisplay>,
  ) => {
    open React
    let connectionDrag = useContext(ConnectionContext.context)

    let (openedTabs, setOpenedTabs) = useState(() => Belt.Set.String.empty)
    let (mockedEvalResults, setMockedEvalResults) = useState(() => None)
    let (formVariables, setFormVariables) = React.useState(() => Js.Dict.empty())
    let (potentialConnection, setPotentialConnection) = React.useState(() => Belt.Set.String.empty)
    let domRef = React.useRef(Js.Nullable.null)
    let (currentAuthToken, setCurrentAuthToken) = useState(() => None)

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

      evalRequest(~schema, ~chain, ~request, ~requestValueCache, ~trace)
      ->Js.Promise.then_(result => {
        setMockedEvalResults(_ =>
          switch result {
          | Ok(result) =>
            let variables = result->Obj.magic->Js.Dict.get("variables")
            variables->Belt.Option.map(variables => Ok(variables))
          | other => Some(other)
          }
        )->Js.Promise.resolve
      }, _)
      ->ignore
      None
    }, (request->Js.Json.stringifyAny->Belt.Option.getExn, chain.script))

    let parsedOperation = request.operation.body->GraphQLJs.parse
    let definition = parsedOperation.definitions->Belt.Array.getExn(0)

    let variableNames = request.operation->Card.getFirstVariables

    let variables = variableNames->Belt.Array.map(((variableName, variableType)) => {
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

      let dragClassName = switch connectionDrag {
      | ConnectionContext.StartedSource(_) => "drag-target"
      | ConnectionContext.StartedTarget({target: Variable({variableDependency})})
        if variableDependency.name == variableName => "drag-source"
      | _ => ""
      }

      <article
        key={variableName}
        id={"inspector-variable-" ++ variableName}
        className={"m-2 variable-settings " ++
        dragClassName ++ {
          potentialConnection->Belt.Set.String.has(variableName) ? " drop-ready" : ""
        }}
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
            potentialConnection->Belt.Set.String.has(variableName) ? " border-blue-900" : ""
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
            <span
              className="font-thin" style={ReactDOMStyle.make(~color=Comps.colors["gray-4"], ())}>
              {(": " ++ variableType)->string}
            </span>
          </div>
          <Comps.Select
            style={ReactDOMStyle.make(~paddingRight="40px", ())}
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

                let newRequestHasComputedDependency =
                  newRequest.variableDependencies->Belt.Array.some(varDep =>
                    switch varDep.dependency {
                    | ArgumentDependency(_) => true
                    | _ => false
                    }
                  )

                let newScript = newRequestHasComputedDependency
                  ? {
                      let returnProperties =
                        newRequest.variableDependencies->Belt.Array.keepMap(varDep => {
                          switch varDep.dependency {
                          | ArgumentDependency(_) => Some((varDep.name, varDep.name))
                          | _ => None
                          }
                        })

                      ensureRequestFunctionExists(
                        ~returnProperties,
                        ~script=chain.script,
                        ~request=newRequest,
                        (),
                      )
                    }
                  : switch deleteRequestFunctionIfEmpty(
                      ~script=chain.script,
                      ~request=newRequest,
                      (),
                    ) {
                    | Error(#invalidSyntax) =>
                      Js.Console.warn("Could not remove function, script has invalid syntax")
                      chain.script
                    | Ok(newScript) => newScript
                    }

                let newChain = {...chain, requests: requests, script: newScript}
                onChainUpdated(newChain)
                setOpenedTabs(oldOpenedTabs => oldOpenedTabs->Belt.Set.String.add(varDep.name))
              }
            }}>
            <option value={"variable"}> {"Variable Input"->string} </option>
            <option value={"argument"}> {"Computed Value"->string} </option>
            <option disabled=true value={"probe"}> {"Direct Connection"->string} </option>
          </Comps.Select>
        </div>
        <div
          className={"text-grey-darkest p-2 text-gray-200 overflow-scroll rounded-b-sm " ++ (
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
              className="og-secodary-button"
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

    let webhookUrl = webhookUrlForAppId(~appId)
    let compiledDoc = chain->Chain.compileOperationDoc(~schema, ~webhookUrl)

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
          formInputOptions(
            ~labelClassname="text-underline pl-2 m-2 mt-0 mb-0 font-thin text-sm font-mono",
            ~defaultValue=?trace->Belt.Option.flatMap(trace =>
              trace.variables->Belt.Option.flatMap(variables =>
                variables->Obj.magic->Js.Dict.get(name)
              )
            ),
            ~onMouseUp={
              event => {
                let element = ReactEvent.Mouse.target(event)->Obj.magic
                let clientX = event->ReactEvent.Mouse.clientX
                let clientY = event->ReactEvent.Mouse.clientY
                let mouseClientPosition = (clientX, clientY)
                switch connectionDrag {
                | ConnectionContext.StartedSource({sourceRequest, sourceDom}) =>
                  let connectionDrag = ConnectionContext.Completed({
                    sourceDom: sourceDom,
                    sourceRequest: sourceRequest,
                    target: Input({inputDom: element}),
                    windowPosition: mouseClientPosition,
                  })

                  onPotentialVariableSourceConnect(~connectionDrag)
                | _ => ()
                }
              }
            },
            (),
          ),
        )
      })

    let definitionResultData = requestValueCache

    let form =
      <form
        className={switch connectionDrag {
        | StartedSource(_) => "drag-enabled"
        | _ => ""
        } ++ " flex flex-col"}
        onSubmit={event => {
          event->ReactEvent.Form.preventDefault
          event->ReactEvent.Form.stopPropagation
          onExecuteRequest(~request, ~variables=formVariables, ~authToken=currentAuthToken)
        }}>
        {inputs->Belt.Array.length > 0 ? {inputs->React.array} : React.null}
        <Comps.Select
          className="w-full select-button comp-select my-4 mx-2"
          onChange={event => {
            let value = ReactEvent.Form.target(event)["value"]
            let token = switch value {
            | "TEMP" => None
            | other => Some(other)
            }

            setCurrentAuthToken(_ => token)
          }}>
          <option value="TEMP"> {"Use current scratchpad auth"->string} </option>
          {authTokens
          ->Belt.Array.map(token => {
            <option value={token.accessToken}> {token.displayedToken->string} </option>
          })
          ->array}
        </Comps.Select>
        <Comps.Button className="w-full" type_="submit"> {"Execute"->React.string} </Comps.Button>
      </form>

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

    let (openedTab, setOpenedTab) = React.useState(() => #inspector)

    <div className="max-h-full overflow-y-scroll" ref={ReactDOM.Ref.domRef(domRef)}>
      <div
        className="w-full flex ml-2 border-b justify-around"
        style={ReactDOMStyle.make(~borderColor=Comps.colors["gray-1"], ())}>
        <button
          onClick={_ => {
            setOpenedTab(_ => #inspector)
          }}
          className={"flex justify-center flex-grow cursor-pointer p-1 " ++ {
            openedTab == #inspector ? " inspector-tab-active" : " inspector-tab-inactive"
          }}>
          <Icons.Remote
            className=""
            width="24px"
            height="24px"
            color={openedTab == #inspector ? Comps.colors["blue-1"] : Comps.colors["gray-6"]}
          />
          <span className="mx-2"> {"Request"->React.string} </span>
        </button>
        <button
          onClick={_ => {
            setOpenedTab(_ => #form)
          }}
          className={"flex justify-center flex-grow cursor-pointer p-1 rounded-sm " ++ {
            openedTab == #form ? " inspector-tab-active" : " inspector-tab-inactive"
          }}>
          <Icons.List
            width="24px"
            height="24px"
            color={openedTab == #form ? Comps.colors["blue-1"] : Comps.colors["gray-6"]}
          />
          <span className="mx-2"> {"Try Block"->React.string} </span>
        </button>
      </div>
      {switch openedTab {
      | #inspector => <>
          {variables->Belt.Array.length > 0
            ? <CollapsableSection title={"Variable Settings"->React.string}>
                {variables->array}
              </CollapsableSection>
            : React.null}
          {variables->Belt.Array.length > 0
            ? <CollapsableSection
                title={<>
                  {"Computed Variable Preview"->string}
                  <button
                    onClick={event => {
                      event->ReactEvent.Mouse.preventDefault
                      event->ReactEvent.Mouse.stopPropagation
                      onRequestCodeInspected(~request)
                    }}>
                    <Icons.Help className="inline-block ml-2" />
                  </button>
                </>}>
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
              </CollapsableSection>
            : React.null}
          {request.dependencyRequestIds->Belt.Array.length > 0
            ? <CollapsableSection title={"Upstream Requests"->React.string}>
                {upstreamRequests->array}
              </CollapsableSection>
            : React.null}
          <CollapsableSection title={"GraphQL Structure"->React.string}>
            <div
              className="my-2 mx-4 p-2 rounded-sm text-gray-200 overflow-scroll"
              style={ReactDOMStyle.make(
                ~backgroundColor=Comps.colors["gray-8"],
                ~maxHeight="150px",
                (),
              )}>
              <GraphQLPreview
                requestId=request.id
                schema
                definition
                fragmentDefinitions={GraphQLJs.Mock.gatherFragmentDefinitions({
                  "operationDoc": chainFragmentsDoc,
                })}
                onCopy={({path}) => {
                  let dataPath = path->Js.Array2.joinWith("?.")
                  let fullPath = "payload." ++ dataPath

                  fullPath->Clipboard.copy
                }}
                definitionResultData
              />
            </div>
          </CollapsableSection>
        </>
      | #form =>
        <CollapsableSection title={"Execute block"->string}>
          {form}
          {authButtons->array}
          <Comps.Pre>
            {cachedResult
            ->Belt.Option.mapWithDefault("Nothing", json =>
              Obj.magic(json)->Js.Json.stringifyWithSpace(2)
            )
            ->string}
          </Comps.Pre>
        </CollapsableSection>
      }}
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
    ~onPotentialVariableSourceConnect,
    ~onLogin: string => unit,
    ~onPersistChain,
    ~transformAndExecuteChain,
    // ~transformAndExecuteChainSubscription,
    ~onDeleteRequest,
    ~onRequestInspected,
    ~savedChainId,
    ~oneGraphAuth,
    ~trace: option<Chain.Trace.t>,
    ~initialChain,
    ~onSaveChain,
    ~onClose,
    ~authTokens,
    ~onChainUpdated,
  ) => {
    open React

    let connectionDrag = useContext(ConnectionContext.context)
    let (potentialConnection, setPotentialConnection) = React.useState(() => Belt.Set.String.empty)

    let webhookUrl = webhookUrlForAppId(~appId=oneGraphAuth->OneGraphAuth.appId)
    let compiledOperation = chain->Chain.compileOperationDoc(~schema, ~webhookUrl)

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
    let (openedTab, setOpenedTab) = React.useState(() => #inspector)

    let isSubscription =
      chain.requests->Belt.Array.some(request => request.operation.kind == Subscription)

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
            formInputOptions(
              ~labelClassname="background-blue-400",
              ~defaultValue=?trace->Belt.Option.flatMap(trace =>
                trace.variables->Belt.Option.flatMap(variables =>
                  variables->Obj.magic->Js.Dict.get(exposedVariable.exposedName)
                )
              ),
              ~onMouseUp={
                event => {
                  let element = ReactEvent.Mouse.target(event)->Obj.magic
                  let clientX = event->ReactEvent.Mouse.clientX
                  let clientY = event->ReactEvent.Mouse.clientY
                  let mouseClientPosition = (clientX, clientY)
                  switch connectionDrag {
                  | ConnectionContext.StartedSource({sourceRequest, sourceDom}) =>
                    let connectionDrag = ConnectionContext.Completed({
                      sourceDom: sourceDom,
                      sourceRequest: sourceRequest,
                      target: Input({inputDom: element}),
                      windowPosition: mouseClientPosition,
                    })

                    onPotentialVariableSourceConnect(~connectionDrag)
                  | _ => ()
                  }
                }
              },
              (),
            ),
          )
        })

        inputs->React.array
      })
      ->Belt.Option.getWithDefault(React.null)

    let isChainViable = chain.requests->Belt.Array.length > 0

    let (currentAuthToken, setCurrentAuthToken) = useState(() => None)

    let requests = chain.requests->Belt.Array.map(request => {
      let dragClassName =
        switch connectionDrag {
        | ConnectionContext.StartedSource({sourceRequest})
          if sourceRequest.id != request.id => "node-drop drag-target"
        | _ => ""
        } ++ {
          potentialConnection->Belt.Set.String.has(request.id) ? " drop-ready" : ""
        }

      <article
        key={request.id}
        className={"mx-2 " ++ dragClassName}
        onMouseEnter={event => {
          switch connectionDrag {
          | StartedSource(_) => setPotentialConnection(s => s->Belt.Set.String.add(request.id))
          | _ => ()
          }
        }}
        onMouseLeave={event => {
          switch connectionDrag {
          | StartedSource(_) => setPotentialConnection(s => s->Belt.Set.String.remove(request.id))
          | _ => ()
          }
        }}
        onMouseUp={event => {
          let clientX = event->ReactEvent.Mouse.clientX
          let clientY = event->ReactEvent.Mouse.clientY
          let mouseClientPosition = (clientX, clientY)
          setPotentialConnection(s => s->Belt.Set.String.remove(request.id))
          switch connectionDrag {
          | StartedSource({sourceRequest, sourceDom}) =>
            let connectionDrag = ConnectionContext.CompletedPendingVariable({
              sourceRequest: sourceRequest,
              targetRequest: request,
              windowPosition: mouseClientPosition,
              sourceDom: sourceDom,
            })

            onPotentialVariableSourceConnect(~connectionDrag)
          | _ => ()
          }
        }}>
        <div
          className={"flex justify-between items-center cursor-pointer p-1 rounded-sm " ++
          dragClassName}>
          <span
            className="font-semibold text-sm font-mono pl-2"
            style={ReactDOMStyle.make(~color=Comps.colors["green-4"], ())}
            onClick={_ => onRequestInspected(request)}>
            {request.id->string}
          </span>
          <Comps.Button
            className="og-secodary-button"
            onClick={event => {
              event->ReactEvent.Mouse.stopPropagation
              event->ReactEvent.Mouse.preventDefault
              let confirmation = Utils.confirm(j`Really delete "${request.operation.title}"?`)

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

    let runChain = () => {
      let variables = Some(formVariables->Obj.magic)

      switch isSubscription {
      | false => transformAndExecuteChain(~variables, ~authToken=currentAuthToken)
      | true => transformAndExecuteChain(~variables, ~authToken=currentAuthToken)
      // | true => transformAndExecuteChainSubscription(~variables)
      }
    }

    let formTab =
      <>
        <CollapsableSection title={"Chain Form"->React.string}>
          <form
            className={switch connectionDrag {
            | StartedSource(_) => "drag-enabled"
            | _ => ""
            } ++ " flex flex-col"}
            onSubmit={event => {
              event->ReactEvent.Form.preventDefault
              event->ReactEvent.Form.stopPropagation
              runChain()
            }}>
            {form}
            {authButtons->React.array}
            <Comps.Select
              className="w-full select-button comp-select my-4 mx-2"
              style={ReactDOMStyle.make(~paddingRight="40px", ())}
              onChange={event => {
                let value = ReactEvent.Form.target(event)["value"]
                let token = switch value {
                | "TEMP" => None
                | other => Some(other)
                }

                setCurrentAuthToken(_ => token)
              }}>
              <option value="TEMP"> {"Use current scratchpad auth"->string} </option>
              {authTokens
              ->Belt.Array.map(token => {
                <option value={token.accessToken}> {token.name->string} </option>
              })
              ->array}
            </Comps.Select>
            <Comps.Button type_="submit" className="w-full">
              <Icons.RunLink className="inline-block" color={Comps.colors["gray-6"]} />
              {(isSubscription ? " Start chain" : "  Run chain")->React.string}
            </Comps.Button>
            // <Comps.Pre>
            //   {formVariables->Obj.magic->Js.Json.stringifyWithSpace(2)->string}
            // </Comps.Pre>
          </form>
        </CollapsableSection>
        {chainExecutionResults
        ->Belt.Option.map(chainExecutionResults =>
          <ChainResultsViewer chain chainExecutionResults={Some(chainExecutionResults)} />
        )
        ->Belt.Option.getWithDefault(React.null)}
      </>
    let saveTab =
      <div className="flex flex-col">
        <Comps.Header> {"Step 1:"->React.string} </Comps.Header>
        <span className="mx-4"> {"Choose auth to use with persisted chain:"->string} </span>
        <Comps.Select
          className="w-full select-button comp-select my-4 mx-2"
          onChange={event => {
            let value = ReactEvent.Form.target(event)["value"]
            let token = switch value {
            | "TEMP" => None
            | other => Some(other)
            }

            setCurrentAuthToken(_ => token)
          }}>
          {authTokens
          ->Belt.Array.map(token => {
            <option value={token.accessToken}> {token.name->string} </option>
          })
          ->array}
        </Comps.Select>
        <Comps.Button
          onClick={_ => {
            onPersistChain(~authToken=currentAuthToken)
          }}
          className="w-full">
          <Icons.AddLink className="inline-block" color={Comps.colors["gray-6"]} />
          {{
            savedChainId->Belt.Option.isNone ? "  Persist Chain" : "  Persisted!"
          }->React.string}
        </Comps.Button>
        <Comps.Header> {"Step 2:"->React.string} </Comps.Header>
        <Comps.Select
          value=""
          className="w-full select-button comp-select"
          disabled={savedChainId->Belt.Option.isNone}
          style={ReactDOMStyle.make(
            ~backgroundColor=?{
              savedChainId->Belt.Option.isNone ? None : Some(Comps.colors["blue-1"])
            },
            ~color=?{
              savedChainId->Belt.Option.isNone ? None : Some(Comps.colors["gray-6"])
            },
            ~width="100%",
            ~margin="10px",
            ~textAlign="center",
            (),
          )}
          onChange={event =>
            savedChainId->Belt.Option.forEach(chainId => {
              let appId = oneGraphAuth->OneGraphAuth.appId

              let remoteChainCalls = remoteChainCalls(~appId, ~chainId, ~schema, chain)

              let value = switch ReactEvent.Form.target(event)["value"] {
              | "form" => Some(j`http://localhost:3003/form?form_id=${chainId}`)
              | "fetch" => Some(remoteChainCalls.fetch)
              | "id" => Some(chainId)
              | "curl" => Some(remoteChainCalls.curl)
              | "netlify" =>
                Some(
                  j`/** HTML form for this function
${remoteChainCalls.netlify.form}
**/

${remoteChainCalls.netlify.code}
`,
                )
              | "scriptkit" => Some(remoteChainCalls.scriptKit)
              | _ => None
              }
              value->Belt.Option.forEach(Clipboard.copy)
            })}>
          <option value=""> {j`???? Copy usage`->React.string} </option>
          <option value={"form"}> {"Copy link to form"->React.string} </option>
          <option value={"fetch"}> {"Copy fetch call"->React.string} </option>
          <option value={"curl"}> {"Copy cURL call"->React.string} </option>
          <option value={"netlify"}> {"Copy Netlify function usage"->React.string} </option>
          <option value={"scriptkit"}> {"Copy ScriptKit usage"->React.string} </option>
          <option value={"id"}> {"Copy Chain Id"->React.string} </option>
        </Comps.Select>
        {
          // Enable later
          // <GitHub chain savedChainId oneGraphAuth />
          null

          // <div>
          //   <Comps.Select style={ReactDOMStyle.make(~width="100%", ~margin="10px", ())}>
          //     <option> {"sgrove/blog"->React.string} </option>
          //   </Comps.Select>
          //   <Comps.Button
          //     onClick={_ => {
          //       onPersistChain()
          //     }}
          //     disabled=true
          //     className="w-full">
          //     <Icons.Login className="inline-block" color={Comps.colors["gray-6"]} />
          //     {"  Push"->React.string}
          //   </Comps.Button>
          // </div>
        }
      </div>

    let inspectorTab =
      <>
        {
          // <pre className="m-2 p-2 bg-gray-600 rounded-sm text-gray-200 overflow-scroll select-all">
          //   {formVariables->Obj.magic->Js.Json.stringifyWithSpace(2)->React.string}
          // </pre>
          isChainViable
            ? React.null
            : <div
                className="m-2 w-full text-center flex flex-1 flex-grow flex-col justify-items-center justify-center items-center justify-items align-middle"
                style={ReactDOMStyle.make(~color=Comps.colors["gray-4"], ~height="50%", ())}>
                <Icons.MonoAddBlocks color={Comps.colors["gray-13"]} />
                <span className="mt-2"> {"Add some blocks to get started"->React.string} </span>
              </div>
        }
        <CollapsableSection defaultOpen=false title={"Metadata"->React.string}>
          <div className="relative text-lg bg-transparent text-gray-800">
            <div className="flex items-center ml-2 mr-2">
              <textarea
                defaultValue={chain.description->Belt.Option.getWithDefault("")}
                style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-9"], ())}
                className="border-none px-2 leading-tight outline-none text-white form-input"
                type_="text"
                placeholder={"Chain description"}
                onChange={event => {
                  let value = ReactEvent.Form.target(event)["value"]->Js.String2.trim
                  let description = switch value {
                  | "" => None
                  | other => Some(other)
                  }
                  let newChain = {...chain, description: description}
                  onChainUpdated(newChain)
                }}
              />
            </div>
          </div>
        </CollapsableSection>
        {requests->Belt.Array.length > 0
          ? <CollapsableSection title={"Chain Requests"->React.string}>
              {requests->array}
            </CollapsableSection>
          : React.null}
        {initialChain == chain
          ? null
          : <Comps.Button onClick={_ => {onSaveChain(chain)}}>
              {"Save Changes"->string}
            </Comps.Button>}
        <Comps.Button onClick={_ => {onClose()}}>
          {"Cancel changes and exit"->string}
        </Comps.Button>
        <CollapsableSection defaultOpen=false title={"Internal Debug info"->React.string}>
          <Comps.Pre selectAll=true>
            {chain->Obj.magic->Js.Json.stringifyWithSpace(2)->React.string}
          </Comps.Pre>
        </CollapsableSection>
        // <CollapsableSection defaultOpen=false title={"Compiled Executable Chain"->React.string}>
        //   <Comps.Pre selectAll=true>
        //     {
        //       let compiled = chain->transformChain(~schema)
        //       // let script = transformed.script

        //       // let script = Obj.magic(transformed)["script"]

        //       // script->Js.Json.string->Js.Json.stringifyWithSpace(2)->React.string
        //       compiled->Obj.magic->Js.Json.stringifyWithSpace(2)->React.string
        //     }
        //   </Comps.Pre>
        // </CollapsableSection>
      </>

    <>
      <div
        className="w-full flex ml-2 border-b justify-around"
        style={ReactDOMStyle.make(~borderColor=Comps.colors["gray-1"], ())}>
        <button
          onClick={_ => {
            setOpenedTab(_ => #inspector)
          }}
          className={"flex justify-center flex-grow cursor-pointer p-1 outline-none " ++ {
            openedTab == #inspector ? " inspector-tab-active" : " inspector-tab-inactive"
          }}>
          <Icons.Link
            className=""
            width="24px"
            height="24px"
            color={openedTab == #inspector ? Comps.colors["blue-1"] : Comps.colors["gray-6"]}
          />
          <span className="mx-2"> {"Chain"->React.string} </span>
        </button>
        <button
          onClick={_ => {
            setOpenedTab(_ => #form)
          }}
          className={"flex justify-center flex-grow cursor-pointer p-1 rounded-sm outline-none " ++ {
            openedTab == #form ? " inspector-tab-active" : " inspector-tab-inactive"
          }}>
          <Icons.List
            width="24px"
            height="24px"
            color={openedTab == #form ? Comps.colors["blue-1"] : Comps.colors["gray-6"]}
          />
          <span className="mx-2"> {"Try Chain"->React.string} </span>
        </button>
        <button
          onClick={_ => {
            setOpenedTab(_ => #save)
          }}
          className={"flex justify-center flex-grow cursor-pointer p-1 rounded-sm outline-none " ++ {
            openedTab == #save ? " inspector-tab-active" : " inspector-tab-inactive"
          }}>
          <Icons.OpenInNew
            width="24px"
            height="24px"
            color={openedTab == #save ? Comps.colors["blue-1"] : Comps.colors["gray-6"]}
          />
          <span className="mx-2"> {"Export"->React.string} </span>
        </button>
      </div>
      {switch openedTab {
      | #inspector => inspectorTab
      | #form => formTab
      | #save => saveTab
      }}
    </>
  }
}

let activeTabClasses = "text-gray-600 py-4 px-6 block hover:text-blue-500 focus:outline-none text-blue-500 border-b-2 font-medium border-blue-500"
let inactiveTabClass = "text-white py-4 px-6 block hover:text-blue-500 focus:outline-none"

module SubInspector = {
  @react.component
  let make = (
    ~inspected: inspectable,
    ~onAddBlock: Card.block => unit,
    ~onChainUpdated: Chain.t => unit,
    ~onReset: unit => unit,
    ~chain: Chain.t,
    ~schema: GraphQLJs.schema,
    ~onLogin: string => unit,
    ~onRequestCodeInspected,
    ~onExecuteRequest,
    ~requestValueCache: RequestValueCache.t,
    ~onDeleteEdge,
    ~onDragStart,
    ~trace,
    ~appId,
    ~onPotentialVariableSourceConnect,
    ~authTokens,
  ) => {
    open React
    ReactHotKeysHook.useHotkeys(
      ~keys="esc",
      ~callback=(event, _handler) => {
        event->ReactEvent.Keyboard.preventDefault
        event->ReactEvent.Keyboard.stopPropagation
        onReset()
      },
      ~options=ReactHotKeysHook.options(),
      ~deps=None,
    )

    <div
      className="w-full text-white border-l border-gray-800"
      style={ReactDOMStyle.make(
        ~backgroundColor="rgb(27,29,31)",
        ~height="calc(100vh - 56px)",
        ~boxShadow="-5px 0 5px rgba(150, 150, 150, 0.25)",
        (),
      )}>
      <nav className="flex flex-row py-1 px-2 mb-2 justify-between">
        <Comps.Header>
          {switch inspected {
          | Nothing(_) => ""
          | Block({title}) => "Block: " ++ title
          | Request({request}) => "Request: " ++ request.id
          | RequestArgument(_) => "Request Argument"
          }->string}
        </Comps.Header>
        <span className="text-white cursor-pointer" onClick={_ => onReset()}>
          {j`???`->React.string}
        </span>
      </nav>
      <div
        className="overflow-y-scroll"
        style={ReactDOMStyle.make(~height="calc(100vh - 56px - 56px)", ())}>
        {switch inspected {
        | Nothing(_) => null
        | Block(block) => <Block schema block onAddBlock />
        | Request({request})
        | RequestArgument({request}) =>
          let cachedResult = requestValueCache->RequestValueCache.get(~requestId=request.id)
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
            trace
            appId
            authTokens
          />
        }}
      </div>
    </div>
  }
}

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
  // ~transformAndExecuteChainSubscription,
  ~onPersistChain,
  ~savedChainId: option<string>,
  ~onRequestCodeInspected,
  ~onExecuteRequest,
  ~requestValueCache,
  ~onDeleteRequest,
  ~onDeleteEdge,
  ~onRequestInspected,
  ~oneGraphAuth,
  ~onDragStart,
  ~trace,
  ~initialChain,
  ~onSaveChain,
  ~onClose,
  ~appId,
  ~onPotentialVariableSourceConnect,
  ~authTokens,
) => {
  open React
  let subInspectorRef = useRef(None)
  let transitions = ReactSpring.useTransition(
    switch inspected {
    | Nothing(_) => false
    | _ => true
    },
    None,
    ReactSpring.lifeCycle(
      ~from=ReactDOMStyle.make(
        ~position="absolute",
        ~opacity="1",
        ~top="0px",
        ~left="0px",
        ~transform="translateX(100%)",
        ~width="100%",
        (),
      ),
      ~enter=ReactDOMStyle.make(
        ~position="absolute",
        ~opacity="1",
        ~top="0px",
        ~left="0px",
        ~transform="translateX(0%)",
        (),
      ),
      ~leave=ReactDOMStyle.make(
        ~position="absolute",
        ~opacity="1",
        ~top="0px",
        ~left="0px",
        ~transform="translateY(100%)",
        (),
      ),
      ~unique=true,
      ~ref=subInspectorRef,
      ~config=ReactSpring.config.stiff,
      (),
    ),
  )

  ReactSpring.useChain([subInspectorRef])

  ReactHotKeysHook.useHotkeys(
    ~keys="command+s",
    ~callback=(event, _handler) => {
      event->ReactEvent.Keyboard.preventDefault
      event->ReactEvent.Keyboard.stopPropagation
      onSaveChain(chain)
    },
    ~options=ReactHotKeysHook.options(),
    ~deps=Some([onSaveChain, chain->Obj.magic]),
  )
  <div
    className=" text-white border-l border-gray-800"
    style={ReactDOMStyle.make(
      ~backgroundColor="rgb(27,29,31)",
      ~height="calc(100vh - 56px)",
      ~position="relative",
      (),
    )}>
    <nav className="flex flex-row py-1 px-2 mb-2 justify-between">
      <Comps.Header> {"Chain Inspector"->string} </Comps.Header>
    </nav>
    <div
      className="overflow-y-scroll"
      style={ReactDOMStyle.make(~height="calc(100vh - 56px - 56px)", ())}>
      {switch inspected {
      | Nothing({chain, trace}) =>
        <Nothing
          chain
          trace
          schema
          chainExecutionResults
          onLogin
          transformAndExecuteChain
          onPersistChain
          savedChainId
          onDeleteRequest
          onRequestInspected
          oneGraphAuth
          initialChain
          onSaveChain
          onClose
          onPotentialVariableSourceConnect
          authTokens
          onChainUpdated
        />
      | _ =>
        <Nothing
          chain
          trace
          schema
          chainExecutionResults
          onLogin
          transformAndExecuteChain
          onPersistChain
          savedChainId
          onDeleteRequest
          onRequestInspected
          oneGraphAuth
          initialChain
          onSaveChain
          onClose
          onPotentialVariableSourceConnect
          authTokens
          onChainUpdated
        />
      }}
    </div>
    {switch inspected {
    | _ =>
      transitions
      ->Belt.Array.map(element => {
        open ReactSpring
        let props = element->propsGet
        let item = element->itemGet
        switch item {
        | false => null
        | true =>
          <ReactSpring.Animated style={props} key={element->keyGet}>
            <SubInspector
              inspected
              onAddBlock
              onChainUpdated
              onReset
              chain
              schema
              onLogin
              onRequestCodeInspected
              onExecuteRequest
              requestValueCache
              onDeleteEdge
              onDragStart
              trace
              appId
              onPotentialVariableSourceConnect
              authTokens
            />
          </ReactSpring.Animated>
        }
      })
      ->array
    }}
  </div>
}
