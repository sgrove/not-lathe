%%raw(`import dynamic from 'next/dynamic'`)

module type STUDIO_COMPONENT = {
  @react.component
  let make: (~schema: GraphQLJs.schema, ~config: Config.Studio.t) => React.element
}

@val
external loader: @as("./components/Studio.js") _ => Js.Promise.t<module(STUDIO_COMPONENT)> =
  "import"

module Inner = {
  type schemaState =
    | Loading(string)
    | Dead({msg: string, error: Js.Promise.error})
    | Loaded(GraphQLJs.schema)

  type state = {schema: schemaState, oneGraphAuth: option<OneGraphAuth.t>}

  @react.component
  let make = (~mod, ~config: Config.Studio.t) => {
    let module(Studio: STUDIO_COMPONENT) = mod
    let (state, setState) = React.useState(() => {
      schema: Loading("Loading schema..."),
      oneGraphAuth: None,
    })

    React.useEffect0(() => {
      let oneGraphAuth = OneGraphAuth.create(
        OneGraphAuth.createOptions(~appId=config.oneGraphAppId, ()),
      )

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

    open React

    <div>
      {switch state.schema {
      | Loading(msg) =>
        <div className="flex h-screen">
          <div className="m-auto">
            <div className="bg-white rounded-lg border-gray-300 border p-3 shadow-lg">
              <div className="flex flex-row">
                <div className="px-2"> <Icons.Play color="gray" /> </div>
                <div className="ml-2 mr-6">
                  <span className="font-semibold"> {msg->React.string} </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      | Dead({error}) =>
        let origin = Utils.Window.locationOrigin()->Belt.Option.getWithDefault("")
        <>
          <div className="flex h-screen">
            <div className="m-auto">
              <div className="bg-white rounded-lg border-gray-300 border p-3 shadow-lg">
                <div className="flex flex-row">
                  <div className="px-2"> <Icons.Trash color="red" /> </div>
                  <div className="ml-2 mr-6">
                    <span className="font-semibold">
                      {j`Make sure `->string}
                      <strong> {origin->string} </strong>
                      {j`is in your CORS origins on the`->string}
                      <span className="block text-blue-500 bg-blue-200">
                        <a
                          href={j`https://www.onegraph.com/dashboard/app/${config.oneGraphAppId}?add-cors-origin=${origin}`}
                          target="_blank"
                          rel="noopener noreferrer">
                          {j`OneGraph dashboard for your app`->string}
                        </a>
                      </span>
                      {j`and then refresh to try again.`->string}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <pre> {error->Obj.magic->Js.Json.stringifyWithSpace(2)->string} </pre>
        </>
      | Loaded(schema) => <> <Studio schema config /> </>
      }}
    </div>
  }
}

module ConfigEditor = {
  type config = {
    oneGraphAppId: option<string>,
    persistQueryToken: option<string>,
    accessToken: option<string>,
  }

  let localStorageName = "oneGraphStudioConfig"

  let saveToLocalStorage = (config: Config.Studio.t): unit => {
    let jsonString = Obj.magic(config)->Js.Json.stringify

    Dom.Storage2.localStorage->Dom.Storage2.setItem(localStorageName, jsonString)
  }

  let loadFromLocalStorage = (): option<Config.Studio.t> => {
    try {
      let jsonString = Dom.Storage2.localStorage->Dom.Storage2.getItem(localStorageName)

      jsonString->Belt.Option.flatMap(jsonString => {
        let json = jsonString->Js.Json.parseExn
        let config: Config.Studio.t = Obj.magic(json)
        Some(config)
      })
    } catch {
    | _ => None
    }
  }

  let checkValidConfig = config => {
    let invalidAppId =
      config.oneGraphAppId
      ->Belt.Option.map(id => !Uuid.validate(id))
      ->Belt.Option.getWithDefault(false)

    switch (config.oneGraphAppId, invalidAppId, config.persistQueryToken, config.accessToken) {
    | (None, _, _, _) => Error("Please enter appId")
    | (_, true, _, _) => Error("Invalid appId")
    | (_, _, None, _) => Error("Please enter PersistQueryToken")
    | (_, _, _, None) => Error("Please enter AccessToken")
    | (Some(oneGraphAppId), _, Some(persistQueryToken), Some(_)) =>
      let newConfig: Config.Studio.t = {
        oneGraphAppId: oneGraphAppId,
        persistQueryToken: persistQueryToken,
        chainAccessToken: config.accessToken,
      }

      Ok(newConfig)
    }
  }

  @react.component
  let make = (~onUpdated) => {
    let (config, setConfig) = React.useState(() => {
      oneGraphAppId: None,
      persistQueryToken: None,
      accessToken: None,
    })

    let validConfig = checkValidConfig(config)

    let validOneGraphAppId =
      config.oneGraphAppId->Belt.Option.flatMap(id => Uuid.validate(id) ? Some(id) : None)

    open React
    let persistQueryTokenLink = validOneGraphAppId->Belt.Option.map(id => {
      <a
        className="text-blue-500"
        href={j`https://www.onegraph.com/dashboard/app/${id}/persisted-queries`}
        target="_blank"
        rel="nofollow">
        {"(Create one here)"->string}
      </a>
    })

    let accessTokenLink = validOneGraphAppId->Belt.Option.map(id => {
      <a
        className="text-blue-500"
        href={j`https://www.onegraph.com/dashboard/app/${id}/auth/server-side`}
        target="_blank"
        rel="nofollow">
        {"(Create one here)"->string}
      </a>
    })

    <div className="flex items-center min-h-screen bg-gray-900">
      <div className="container mx-auto">
        <div className="max-w-md mx-auto my-10 bg-gray-700 p-5 rounded-md shadow-sm">
          <div className="text-center">
            <h1 className="my-3 text-3xl font-semibold text-gray-200">
              {j`OneStudio Alpha Config`->string}
            </h1>
            <p className="text-gray-400">
              {j`Pardon the rough start, we just need a few tokens.`->string}
            </p>
          </div>
          <div className="m-7">
            <form
              onSubmit={event => {
                event->ReactEvent.Form.preventDefault
                switch validConfig {
                | Ok(config) => onUpdated(config)
                | Error(_) => ()
                }
              }}>
              <div className="mb-6">
                <label htmlFor="name" className="block mb-2 text-sm text-gray-400">
                  {j`OneGraph App id`->string}
                  <a
                    className="text-blue-500"
                    href="https://onegraph.com/dashboard"
                    target="_blank"
                    rel="nofollow">
                    {"(on your dashboard)"->string}
                  </a>
                </label>
                <input
                  type_="text"
                  name="name"
                  id="name"
                  placeholder="e.g. 4b34d36f-83e5-4789-9cf7-fe1ebe1ce527"
                  required=true
                  onChange={event => {
                    let value = switch ReactEvent.Form.target(event)["value"] {
                    | "" => None
                    | other => Some(other)
                    }
                    setConfig(oldConfig => {...oldConfig, oneGraphAppId: value})
                  }}
                  className="w-full px-3 py-2 placeholder-gray-300 border border-gray-300 rounded-md focus:outline-none focus:ring bg-gray-700 text-white placeholder-gray-500 border-gray-600 focus:ring-gray-900 focus:border-gray-500"
                />
              </div>
              <div className="mb-6">
                <label htmlFor="email" className="block mb-2 text-sm text-gray-400">
                  {j`PersistQueryToken`->string}
                  {persistQueryTokenLink->Belt.Option.getWithDefault(null)}
                </label>
                <input
                  type_="password"
                  name="PersistQueryToken"
                  id="PersistQueryToken"
                  required=true
                  disabled={validOneGraphAppId->Belt.Option.isNone}
                  onChange={event => {
                    let value = switch ReactEvent.Form.target(event)["value"] {
                    | "" => None
                    | other => Some(other)
                    }
                    setConfig(oldConfig => {...oldConfig, persistQueryToken: value})
                  }}
                  className="w-full px-3 py-2 placeholder-gray-300 border border-gray-300 rounded-md focus:outline-none focus:ring bg-gray-700 text-white placeholder-gray-500 border-gray-600 focus:ring-gray-900 focus:border-gray-500"
                />
              </div>
              <div className="mb-6">
                <label htmlFor="phone" className="text-sm text-gray-400">
                  {j`Personal Auth Token`->string}
                  {accessTokenLink->Belt.Option.getWithDefault(null)}
                </label>
                <input
                  type_="password"
                  name="accessToken"
                  id="accessToken"
                  required=true
                  disabled={validOneGraphAppId->Belt.Option.isNone}
                  onChange={event => {
                    let value = switch ReactEvent.Form.target(event)["value"] {
                    | "" => None
                    | other => Some(other)
                    }
                    setConfig(oldConfig => {...oldConfig, accessToken: value})
                  }}
                  className="w-full px-3 py-2 placeholder-gray-300 border border-gray-300 rounded-md focus:outline-none focus:ring bg-gray-700 text-white placeholder-gray-500 border-gray-600 focus:ring-gray-900 focus:border-gray-500"
                />
              </div>
              <div className="mb-6">
                <button
                  type_="submit"
                  className={"w-full px-3 py-4 text-white rounded-md focus:bg-indigo-600 focus:outline-none " ++ (
                    validConfig->Belt.Result.isOk ? "bg-indigo-500" : "bg-gray-500"
                  )}
                  disabled={validConfig->Belt.Result.isError}>
                  {switch validConfig {
                  | Ok(_) => j`Save Config`
                  | Error(msg) => msg
                  }->string}
                </button>
              </div>
              <p className="text-base text-center text-gray-400" id="result" />
            </form>
          </div>
        </div>
      </div>
    </div>
  }
}

type state<'a> = {
  msg: string,
  mod: option<'a>,
  config: option<Config.Studio.t>,
}

let default = () => {
  let (state, setState) = React.useState(() => {
    msg: "Retrieving config...",
    mod: None,
    config: ConfigEditor.loadFromLocalStorage(),
  })

  React.useEffect0(() => {
    loader->Js.Promise.then_((module(Studio: STUDIO_COMPONENT)) => {
      setState(oldState => {
        ...oldState,
        msg: "Loaded!",
        mod: Some(module(Studio: STUDIO_COMPONENT)),
      })->Js.Promise.resolve
    }, _)->ignore
    None
  })
  <>
    <Next.Head> <title> {"OneGraph Serverless Studio"->React.string} </title> </Next.Head>
    {switch state {
    | {mod: None} => <>
        <div className="flex h-screen">
          <div className="m-auto">
            <div className="bg-white rounded-lg border-gray-300 border p-3 shadow-lg">
              <div className="flex flex-row">
                <div className="px-2"> <Icons.Play color="gray" /> </div>
                <div className="ml-2 mr-6">
                  <span className="font-semibold"> {state.msg->React.string} </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </>

    | {config: None} =>
      <ConfigEditor
        onUpdated={config => {
          ConfigEditor.saveToLocalStorage(config)
          setState(oldState => {...oldState, config: Some(config)})
        }}
      />
    | {mod: Some(mod), config: Some(config)} => <Inner mod config />
    }}
  </>
}
