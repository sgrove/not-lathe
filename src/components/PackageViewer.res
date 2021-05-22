module PackageFragment = %relay(`
  fragment PackageViewer_oneGraphAppPackage on OneGraphAppPackage {
    description
    id
    name
    version
    chains {
      ...ChainViewer_oneGraphAppPackageChain
      ...ChainEditor_oneGraphAppPackageChain
      id
      name
      authToken {
        obscuredToken
        name
        userAuths {
          service
        }
      }
    }
  }
  `)

module AuthTokensFragment = %relay(`
  fragment PackageViewer_authTokens on OneGraphUser {
    personalTokens {
      token
      obscuredToken
      expireDate
      name
      appId
    }
  }
  `)

type diff = {
  addedFunctions: array<Chain.typeScriptDefinition>,
  removedFunctions: array<Chain.typeScriptDefinition>,
  changedFunctions: array<Chain.typeScriptDefinition>,
}

type view =
  | Nothing
  | Settings
  | Publish(diff)
  | Chain(string)

type state = {view: view}

module EditorTemp = {
  @react.component
  let make = (~schema, ~chain: PackageViewer_oneGraphAppPackage_graphql.Types.fragment_chains) => {
    let config: Config.Studio.t = {
      oneGraphAppId: "",
      persistQueryToken: "",
      chainAccessToken: None,
    }

    <ChainEditor
      config
      schema
      chainRefs=chain.fragmentRefs
      localStorageChain=Package.DevTimeJson.spotifyChain
      trace=None
      helpOpen=false
      onSaveChain={(newChain: Chain.t) => {
        ()
        // setState(oldState => {
        //   newChain->Chain.saveToLocalStorage

        //   let inspected = switch oldState.inspected {
        //   | Edit({trace}) => Edit({chain: newChain, trace: trace})
        //   | _ => Edit({chain: newChain, trace: None})
        //   }
        //   {
        //     ...oldState,
        //     package: {
        //       ...oldState.package,
        //       chains: oldState.package.chains->Belt.Array.map(oldChain => {
        //         oldChain.id == newChain.id ? newChain : oldChain
        //       }),
        //     },
        //     inspected: inspected,
        //   }
        // })
      }}
      onClose={() => {
        ()
        // setState(oldState => {
        //   ...oldState,
        //   inspected: Package,
        // })
      }}
      onSaveAndClose={newChain => {
        ()
        // setState(oldState => {
        //   ...oldState,
        //   inspected: Package,
        //   package: {
        //     ...oldState.package,
        //     chains: oldState.package.chains->Belt.Array.map(oldChain => {
        //       oldChain == chain ? newChain : oldChain
        //     }),
        //   },
        // })
      }}
    />
  }
}

@react.component
let make = (
  ~schema,
  ~onCreateChain,
  ~onInspectChain,
  ~onEditChain,
  ~onDeleteChain,
  ~onEditPackage,
  ~onPublishPackageToNpm,
  ~onPublishPackageToGitHub,
  ~oneGraphAppPackageRef,
  ~authTokensRef,
) => {
  let package = PackageFragment.use(oneGraphAppPackageRef)
  let chains = package.chains
  let authTokens = authTokensRef->Belt.Option.mapWithDefault([], authTokensRef => {
    let oneGraphUser = AuthTokensFragment.use(authTokensRef)
    oneGraphUser.personalTokens->Belt.Option.getWithDefault([])
  })

  open React

  let (state, setState) = useState(() => {
    view: switch package.chains {
    | [] => Nothing
    | chains => Chain(chains[0].id)
    },
  })

  let nav =
    <nav className="bg-grey-light p-3 rounded font-sans w-full">
      <ol className="list-reset flex text-grey-dark">
        <li> <a href="#" className="text-blue"> {j`Home`->string} </a> </li>
        <li> <span className="mx-2"> {j`/`->string} </span> </li>
        {switch state.view {
        | Nothing => <>
            <li className="font-bold">
              <a href="#" onClick={_ => setState(_ => {view: Nothing})} className="text-blue ">
                {package.name->string}
              </a>
            </li>
          </>
        | Settings => <>
            <li>
              <a href="#" onClick={_ => setState(_ => {view: Nothing})} className="text-blue ">
                {package.name->string}
              </a>
            </li>
            <li> <span className="mx-2"> {j`/`->string} </span> </li>
            <li className="font-bold"> {"Settings"->string} </li>
          </>
        | Publish(_) => <>
            <li>
              <a href="#" onClick={_ => setState(_ => {view: Nothing})} className="text-blue ">
                {package.name->string}
              </a>
            </li>
            <li> <span className="mx-2"> {j`/`->string} </span> </li>
            <li className="font-bold"> {"Publish new version"->string} </li>
          </>
        | Chain(id) =>
          let chain = chains->Belt.Array.getBy(chain => chain.id == id)

          <>
            <li>
              <a href="#" onClick={_ => setState(_ => {view: Nothing})} className="text-blue ">
                {package.name->string}
              </a>
            </li>
            <li> <span className="mx-2"> {j`/`->string} </span> </li>
            <li className="font-bold">
              {chain->Belt.Option.mapWithDefault(null, chain => {
                chain.name->string
              })}
            </li>
          </>
        }}
      </ol>
    </nav>

  <>
    {nav}
    {switch state.view {
    | Chain(id) =>
      let chain = chains->Belt.Array.getBy(chain => chain.id == id)

      chain->Belt.Option.mapWithDefault(null, chain => {
        <> <EditorTemp schema chain /> </>
      })
    | _ =>
      <div
        className="w-full m-2 h-full bg-white flex items-center justify-center font-sans overflow-hidden"
        style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-8"], ())}>
        <div className="w-full h-full ">
          <div className="flex justify-between">
            <h1
              className="m-5 flex-1 font-bold"
              style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
              {package.name->string}
              <span className="mx-2"> <code> {package.version->string} </code> </span>
            </h1>
            <div className="m-2">
              <Comps.Button
                onClick={_ => {
                  setState(oldState => {...oldState, view: Settings})
                }}>
                <Icons.Gears className="inline-block " color={Comps.colors["gray-4"]} />
                {" Package Settings"->string}
              </Comps.Button>
            </div>
            <div className="m-2">
              <Comps.Button
                disabled={true}
                onClick={_ => {
                  ()
                  // diff->Belt.Option.forEach(diff =>
                  //   setState(oldState => {...oldState, view: Publish(diff)})
                  // )
                }}>
                <Icons.Gears className="inline-block " color={Comps.colors["gray-4"]} />
                {" View Diff"->string}
              </Comps.Button>
            </div>
            <div className="m-2">
              <Comps.Button
              // style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}
              // disabled={diff->Belt.Option.isNone}
                onClick={_ => {
                  switch {
                    Utils.prompt(
                      "Enter npm api token to publish:",
                      ~default=None,
                    )->Js.Nullable.toOption
                  } {
                  | None => ()
                  | Some(apiToken) =>
                    onPublishPackageToNpm(~npmAuth={"apiToken": apiToken}->Obj.magic)
                  }
                }}>
                <Icons.Login className="inline-block " color={Comps.colors["gray-4"]} />
                {" Publish changes to npm"->string}
              </Comps.Button>
            </div>
            <div className="m-2">
              <Comps.Button
              // style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}
              // disabled={diff->Belt.Option.isNone}
                onClick={_ => {
                  switch {
                    Utils.prompt(
                      "Enter GitHub OAuth token (with repo and write:packages scopes) to publish:",
                      ~default=None,
                    )->Js.Nullable.toOption
                  } {
                  | None => ()
                  | Some(apiToken) => onPublishPackageToGitHub(~gitHubOAuthToken=apiToken)
                  }
                }}>
                <Icons.Login className="inline-block " color={Comps.colors["gray-4"]} />
                {" Publish changes to GitHub registry"->string}
              </Comps.Button>
            </div>
            <div className="m-2">
              <Comps.Button
              // style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}
                onClick={_ => {
                  switch Utils.prompt("New chain name", ~default=Some("newChain"))
                  ->Js.Nullable.toOption
                  ->Belt.Option.mapWithDefault("", name => name->Js.String2.trim) {
                  | "" => ()
                  | other =>
                    let chain = Chain.makeEmptyChain(other)
                    onCreateChain(chain)
                  }
                }}>
                <Icons.Plus className="inline-block " color={Comps.colors["gray-4"]} />
                {" New Chain"->string}
              </Comps.Button>
            </div>
          </div>
          <div className="w-full h-full shadow-md rounded my-6">
            <table className="min-w-max h-full w-full table-auto">
              <thead>
                <tr
                  className="text-gray-600 text-sm leading-normal"
                  style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}>
                  <th className="py-3 px-6 text-left"> {j`Chain Name`->string} </th>
                  <th className="py-3 px-6 text-left"> {j`Auth Token`->string} </th>
                  <th className="py-3 px-6 text-center"> {j`Data Retention`->string} </th>
                  <th className="py-3 px-6 text-center"> {j`Team Access`->string} </th>
                  <th className="py-3 px-6 text-center"> {j`Status`->string} </th>
                  <th className="py-3 px-6 text-center"> {j`Actions`->string} </th>
                </tr>
              </thead>
              <tbody className="text-gray-600 text-sm font-light">
                {chains
                ->Belt.Array.mapWithIndex((index, chain) => {
                  let even = mod(index, 2) == 0
                  let style = ReactDOMStyle.make(
                    ~backgroundColor=Comps.colors["gray-15"],
                    ~marginTop="5px",
                    ~color=Comps.colors["gray-6"],
                    (),
                  )
                  let className = even
                    ? " text-gray-50 hover:bg-gray-400"
                    : " text-gray-50 hover:bg-gray-700"

                  let saveChain = (newChain: Chain.t) => {
                    // let newPackage = {
                    //   ...package,
                    //   chains: package.chains->Belt.Array.map(chain => {
                    //     chain.id == newChain.id ? newChain : chain
                    //   }),
                    // }
                    Js.log2("onEditPackage: ", newChain)
                    // onEditPackage(newPackage)
                  }
                  <tr
                    key={chain.id}
                    style
                    className={"rounded-md border-4 border-gray-900 " ++ className}>
                    <td className="py-3 px-6 text-left whitespace-nowrap">
                      <div className="flex items-center">
                        <span
                          className="font-medium cursor-pointer mr-2"
                          onClick={_ => {
                            onEditChain(~chain, ~trace=None)
                          }}>
                          {chain.name->string}
                        </span>
                        <div className="flex items-center">
                          <div className="flex items-center justify-center">
                            {
                              let images =
                                // chain.services
                                []
                                ->Belt.Array.mapWithIndex((idx, service) =>
                                  service
                                  ->Utils.serviceImageUrl
                                  ->Belt.Option.map(((url, friendlyServiceName)) =>
                                    <img
                                      key={friendlyServiceName}
                                      alt=friendlyServiceName
                                      title=friendlyServiceName
                                      width="24px"
                                      src=url
                                      className={" rounded-full border-gray-200 border-2 transform hover:scale-125 " ++ (
                                        idx > 0 ? "-m-1" : ""
                                      )}
                                    />
                                  )
                                )
                                ->Belt.Array.keepMap(el => el)

                              images->Belt.Array.length > 0 ? images->array : " "->string
                            }
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="py-3 px-6 ">
                      <Comps.Select
                        className="inline-block comp-select"
                        value={chain.authToken->Belt.Option.mapWithDefault("", authToken =>
                          authToken.obscuredToken
                        )}
                        onChange={event => {
                          let value = ReactEvent.Form.target(event)["value"]
                          let accessToken = switch value {
                          | "" => None
                          | other => Some(other)
                          }

                          // let newChain = {
                          //   ...chain,
                          //   accessToken: accessToken,
                          // }
                          // saveChain(newChain)
                        }}>
                        <option value=""> {"None"->string} </option>
                        {authTokens
                        ->Belt.Array.map(authToken => {
                          <option key={authToken.obscuredToken} value={authToken.token}>
                            {j`${authToken.name->Belt.Option.getWithDefault(
                                "Unnamed",
                              )} (${authToken.obscuredToken})`->string}
                          </option>
                        })
                        ->array}
                      </Comps.Select>
                    </td>
                    <td>
                      <Comps.Select
                        className="inline-block comp-select"
                        value={switch Chain.ALL {
                        | Chain.ALL => "ALL"
                        | ERRORS => "ERRORS"
                        | NEVER => "NEVER"
                        }}
                        onChange={event => {
                          let value = ReactEvent.Form.target(event)["value"]
                          let policy = switch value {
                          | "ALL" => Some(Chain.ALL)
                          | "ERRORS" => Some(ERRORS)
                          | "NEVER" => Some(NEVER)
                          | _ => None
                          }

                          // policy->Belt.Option.forEach(policy => {
                          //   let newChain = {
                          //     ...chain,
                          //     traceRetentionPolicy: {
                          //       ...chain.traceRetentionPolicy,
                          //       captureTarget: policy,
                          //     },
                          //   }
                          //   saveChain(newChain)
                          // })
                        }}>
                        <option value="ALL"> {"Keep trace for every invocation"->string} </option>
                        <option value="ERRORS">
                          {"Only keep trace for invocations with errors"->string}
                        </option>
                        <option value="NEVER"> {"Never retain any trace data"->string} </option>
                      </Comps.Select>
                      <br />
                      {switch Chain.NEVER {
                      | Chain.NEVER => null
                      | _ => <>
                          {" for "->string}
                          <input
                            disabled={true}
                            className="bg-transparent border-none px-2 leading-tight outline-none text-white inline"
                            type_="number"
                            // value={chain.traceRetentionPolicy.retentionDays->string_of_int}
                            placeholder="days"
                            style={ReactDOMStyle.make(~width="10ch", ())}
                            onChange={event => {
                              let value = ReactEvent.Form.target(event)["value"]
                              try {
                                let number = value->int_of_string
                                // let newChain = {
                                //   ...chain,
                                //   traceRetentionPolicy: {
                                //     ...chain.traceRetentionPolicy,
                                //     retentionDays: number,
                                //   },
                                // }
                                // saveChain(newChain)
                              } catch {
                              | _ => ()
                              }
                            }}
                          />
                          {" days"->string}
                        </>
                      }}
                    </td>
                    <td className="py-3 px-6 text-center">
                      <div className="flex items-center justify-center">
                        {["sgrove", "dwwoelfel"]
                        ->Belt.Array.mapWithIndex((idx, username) =>
                          <img
                            key={username}
                            alt=username
                            title=username
                            width="24px"
                            src={j`https://github.com/${username}.png?size=200`}
                            className={" rounded-full border-gray-200 border transform hover:scale-125 " ++ (
                              idx > 0 ? "-m-1" : ""
                            )}
                          />
                        )
                        ->array}
                      </div>
                    </td>
                    <td className="py-3 px-6 text-center"> {Package.active()} </td>
                    <td className="py-3 px-6 text-center">
                      <div className="flex item-center justify-center">
                        <div
                          className="mr-2 transform hover:bg-gray-800 hover:scale-110 cursor-pointer border rounded-lg p-2"
                          style={ReactDOMStyle.make(~borderColor=Comps.colors["gray-2"], ())}
                          onClick={_ => onInspectChain(chain)}>
                          <Icons.Visibility color={Comps.colors["gray-4"]} />
                        </div>
                        <div
                          className="mr-2 transform hover:bg-gray-800 hover:scale-110 cursor-pointer border rounded-lg p-2"
                          style={ReactDOMStyle.make(~borderColor=Comps.colors["gray-2"], ())}
                          onClick={_ => onEditChain(~chain, ~trace=None)}>
                          <Icons.EditPencil color={Comps.colors["gray-4"]} />
                        </div>
                        <div
                          className="mr-2 transform hover:bg-gray-800 hover:scale-110 cursor-pointer border rounded-lg p-2"
                          style={ReactDOMStyle.make(~borderColor=Comps.colors["gray-2"], ())}
                          onClick={_ =>
                            switch Utils.confirm("Really delete chain: " ++ chain.name ++ "?") {
                            | false => ()
                            | true => onDeleteChain(chain)
                            }}>
                          <Icons.Trash color={Comps.colors["gray-4"]} />
                        </div>
                      </div>
                    </td>
                  </tr>
                })
                ->array}
              </tbody>
            </table>
          </div>
        </div>
        {switch state.view {
        | Nothing => null
        | Settings =>
          <Comps.Modal>
            <div className="flex w-full flex-col">
              <div className="flex flex-grow flex-row h-full">
                <table className="">
                  <thead>
                    <tr
                      className="text-gray-600 text-sm leading-normal"
                      style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}>
                      <th className="py-3 px-6 text-left"> {j`Name`->string} </th>
                      <th className="py-3 px-6 text-left"> {j`Setting`->string} </th>
                    </tr>
                  </thead>
                  <tbody className={""}>
                    <tr
                      style={
                        let style = ReactDOMStyle.make(
                          ~backgroundColor=Comps.colors["gray-15"],
                          ~marginTop="5px",
                          ~color=Comps.colors["gray-6"],
                          (),
                        )
                        style
                      }
                      className={"rounded-md border-4 border-gray-900 "}>
                      <td className="py-3 px-6 text-left whitespace-nowrap">
                        <div className="flex items-center">
                          <span className="font-medium cursor-pointer mr-2">
                            {"Package name: "->string}
                          </span>
                        </div>
                      </td>
                      <td className="py-3 px-6 ">
                        <div className="relative text-lg bg-transparent text-gray-800">
                          <div className="flex items-center ml-2 mr-2">
                            <input
                              defaultValue={package.name}
                              style={ReactDOMStyle.make(
                                ~backgroundColor=Comps.colors["gray-9"],
                                (),
                              )}
                              className="border-none px-2 leading-tight outline-none text-white form-input"
                              type_="text"
                              placeholder={"npm-package-name"}
                              onChange={event => {
                                let value = ReactEvent.Form.target(event)["value"]
                                let newPackage = {...package, name: value}
                                onEditPackage(newPackage)
                              }}
                            />
                          </div>
                        </div>
                      </td>
                    </tr>
                    <tr
                      style={
                        let style = ReactDOMStyle.make(
                          ~backgroundColor=Comps.colors["gray-15"],
                          ~marginTop="5px",
                          ~color=Comps.colors["gray-6"],
                          (),
                        )
                        style
                      }
                      className={"rounded-md border-4 border-gray-900 "}>
                      <td className="py-3 px-6 text-left whitespace-nowrap">
                        <div className="flex items-center">
                          <span className="font-medium cursor-pointer mr-2">
                            {"Package descriptions: "->string}
                          </span>
                        </div>
                      </td>
                      <td className="py-3 px-6 ">
                        <div className="relative text-lg bg-transparent text-gray-800">
                          <div className="flex items-center ml-2 mr-2">
                            <input
                              defaultValue={package.description->Belt.Option.getWithDefault("")}
                              style={ReactDOMStyle.make(
                                ~backgroundColor=Comps.colors["gray-9"],
                                (),
                              )}
                              className="border-none px-2 leading-tight outline-none text-white form-input"
                              type_="text"
                              onChange={event => {
                                let value = switch ReactEvent.Form.target(
                                  event,
                                )["value"]->Js.String2.trim {
                                | "" => None
                                | other => Some(other)
                                }

                                let newPackage = {...package, description: value}
                                onEditPackage(newPackage)
                              }}
                            />
                          </div>
                        </div>
                      </td>
                    </tr>
                    <tr
                      style={
                        let style = ReactDOMStyle.make(
                          ~backgroundColor=Comps.colors["gray-15"],
                          ~marginTop="5px",
                          ~color=Comps.colors["gray-6"],
                          (),
                        )
                        style
                      }
                      className={"rounded-md border-4 border-gray-900 "}>
                      <td className="py-3 px-6 text-left whitespace-nowrap">
                        <div className="flex items-center">
                          <span className="font-medium cursor-pointer mr-2">
                            {"Manually set package version ('int.int.int'): "->string}
                          </span>
                        </div>
                      </td>
                      <td className="py-3 px-6 ">
                        <div className="relative text-lg bg-transparent text-gray-800">
                          <div className="flex items-center ml-2 mr-2" />
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div className="w-full ml-auto flex">
                <Comps.Button
                // className="bg-transparent hover:bg-gray-500 text-blue-700 font-semibold hover:text-white py-2 px-4 border border-blue-500 hover:border-transparent rounded flex-grow"
                  className="flex-grow"
                  onClick={_ => setState(oldState => {...oldState, view: Nothing})}>
                  {j`Close`->string}
                </Comps.Button>
              </div>
            </div>
          </Comps.Modal>
        | Publish(diff) =>
          <Comps.Modal>
            <div className="w-full h-full shadow-md rounded my-6 text-white flex flex-col">
              <div className="overflow-y-scroll flex flex-col">
                <h1
                  className="m-5 flex-1 font-bold block"
                  style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
                  {"Publish package changes: "->string}
                  <span className="mx-2"> <code> {package.version->string} </code> </span>
                  <span className="mx-2"> {" => "->string} </span>
                  <span className="mx-2" />
                </h1>
                <table className="min-w-max h-full w-full table-auto">
                  <thead>
                    <tr
                      className="text-gray-600 text-sm leading-normal"
                      style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}>
                      <th className="py-3 px-6 text-left"> {j`Function`->string} </th>
                      <th className="py-3 px-6 text-left"> {j`Input`->string} </th>
                      <th className="py-3 px-6 text-center"> {j`Return`->string} </th>
                    </tr>
                  </thead>
                  <tbody className="text-gray-600 text-sm font-light" />
                </table>
              </div>
              <div className="w-full ml-auto flex">
                <Comps.Button className="flex-grow" disabled={true}>
                  {j`Save`->string}
                </Comps.Button>
                <Comps.Button
                // className="bg-transparent hover:bg-gray-500 text-blue-700 font-semibold hover:text-white py-2 px-4 border border-blue-500 hover:border-transparent rounded flex-grow"
                  className="flex-grow"
                  onClick={_ => setState(oldState => {...oldState, view: Nothing})}>
                  {j`Cancel`->string}
                </Comps.Button>
              </div>
            </div>
          </Comps.Modal>
        | Chain(_) => null
        }}
      </div>
    }}
  </>
}
