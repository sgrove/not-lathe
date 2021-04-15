module DevTimeJson = {
  @module("../DevTime_Json.js") external traces: array<Chain.Trace.t> = "traces"
  @module("../DevTime_Json.js") external devJsonChain: Chain.t = "devJsonChain"
  @module("../DevTime_Json.js") external simpleChain: Chain.t = "simpleChain"
  @module("../DevTime_Json.js") external spotifyChain: Chain.t = "spotifyChain"
  @module("../DevTime_Json.js") external descuriChain: Chain.t = "descuriChain"
}

type logLevel = [#info | #warn | #error]

type logLine<'logBody> = {
  level: logLevel,
  body: array<'logBody>,
}

type t = {
  name: string,
  version: (int, int, int),
  chains: array<Chain.t>,
  traceRetentionPolicy: [#all | #onlyErrors | #never],
  traceRetentionDays: int,
}

let stringVersion = (info: t) => {
  let (major, minor, patch) = info.version
  j`${major->string_of_int}.${minor->string_of_int}.${patch->string_of_int}`
}

let completed = () => {
  <span className="bg-green-200 text-green-600 py-1 px-3 rounded-full text-xs">
    {j`Completed`->React.string}
  </span>
}

let errored = () => {
  <span className="bg-red-800 text-red-100 py-1 px-3 rounded-full text-xs">
    {j`Errors`->React.string}
  </span>
}

let active = () => {
  <span
    style={ReactDOMStyle.make(
      ~backgroundColor=Comps.colors["green-4"],
      ~color=Comps.colors["gray-6"],
      (),
    )}
    className="text-purple-600 py-1 px-3 rounded-full text-xs">
    {j`Active`->React.string}
  </span>
}

let slow = () => {
  <span className="bg-yellow-200 text-yellow-600 py-1 px-3 rounded-full text-xs">
    {j`Slow`->React.string}
  </span>
}

let pending = () => {
  <span className="bg-red-200 text-red-600 py-1 px-3 rounded-full text-xs">
    {j`Pending`->React.string}
  </span>
}

let noErrors = () => {
  <span className="text-sm font-semibold px-4 py-1 text-gray-800 rounded-full bg-green-300">
    {j`No errors`->React.string}
  </span>
}

module PackageEditor = {
  type diff = {
    addedFunctions: array<Chain.typeScriptDefinition>,
    removedFunctions: array<Chain.typeScriptDefinition>,
    changedFunctions: array<Chain.typeScriptDefinition>,
  }

  // TODO: Detect field removable, renames, etc. and make it breaking change
  let diffPackage = (~schema, a: t, b: t): option<diff> => {
    let aFns = a.chains->Belt.Array.map(chain => {
      let typeDef = Chain.typeScriptDefinition(~schema, chain)
      typeDef
    })

    let bFns = b.chains->Belt.Array.map(chain => {
      let typeDef = Chain.typeScriptDefinition(~schema, chain)
      typeDef
    })

    let addedFunctions = bFns->Belt.Array.keep(bFn => {
      !(aFns->Belt.Array.some(aFn => bFn.functionName == aFn.functionName))
    })

    let removedFunctions = aFns->Belt.Array.keep(aFn => {
      !(bFns->Belt.Array.some(bFn => bFn.functionName == aFn.functionName))
    })

    let changedFunctions = bFns->Belt.Array.keep(bFn => {
      let previousFunction = aFns->Belt.Array.getBy(aFn => bFn.functionName == aFn.functionName)

      previousFunction->Belt.Option.mapWithDefault(false, aFn => {
        aFn.inputType != bFn.inputType && aFn.returnType != bFn.returnType
      })
    })

    switch (addedFunctions, removedFunctions, changedFunctions) {
    | ([], [], []) => None
    | (_, _, _) =>
      Some({
        addedFunctions: addedFunctions,
        removedFunctions: removedFunctions,
        changedFunctions: changedFunctions,
      })
    }
  }

  let versionBumpForDiff = (diff: diff): (int, int, int) => {
    switch (diff.removedFunctions, diff.addedFunctions, diff.changedFunctions) {
    | ([], [], []) => (0, 0, 0)
    | ([], [], _) => (0, 0, 1)
    | ([], _, _) => (0, 1, 0)
    | (_, _, _) => (1, 0, 0)
    }
  }

  let computeNewVersion = (package: t, diff) => {
    let (major, minor, patch) = package.version

    let newVersion = switch diff->versionBumpForDiff {
    | (0, 0, patchDelta) => (major, minor, patch + patchDelta)
    | (0, minorDelta, 0) => (major, minor + minorDelta, 0)
    | (majorDelta, 0, 0) => (major + majorDelta, 0, 0)
    | _ => package.version
    }

    {
      ...package,
      version: newVersion,
    }
  }

  type view =
    | Nothing
    | Settings
    | Publish(diff)

  type state = {view: view}

  @react.component
  let make = (
    ~schema,
    ~initialPackage: t,
    ~package: t,
    ~onCreateChain,
    ~onInspectChain,
    ~onEditChain,
    ~onDeleteChain,
    ~onEditPackage,
  ) => {
    open React

    let (state, setState) = useState(() => {view: Nothing})
    let chains = package.chains

    let diff = diffPackage(~schema, initialPackage, package)

    <div
      className="w-full m-2 h-full bg-white flex items-center justify-center font-sans overflow-hidden"
      style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-8"], ())}>
      <div className="w-full h-full ">
        <div className="flex justify-between">
          <h1
            className="m-5 flex-1 font-bold"
            style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
            {package.name->string}
            <span className="mx-2"> <code> {package->stringVersion->string} </code> </span>
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
            // style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}
              disabled={diff->Belt.Option.isNone}
              onClick={_ => {
                diff->Belt.Option.forEach(diff =>
                  setState(oldState => {...oldState, view: Publish(diff)})
                )
              }}>
              <Icons.Login className="inline-block " color={Comps.colors["gray-4"]} />
              {" Publsh changes to npm"->string}
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
                <tr
                  key={chain.id->Belt.Option.mapWithDefault("no-id", Uuid.toString)}
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
                              chain
                              ->Chain.gatherAllReferencedServices(~schema)
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
                    {"OFGM***************************************"->string}
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
                  <td className="py-3 px-6 text-center"> {active()} </td>
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
                          {"Trace Retention Policy: "->string}
                        </span>
                      </div>
                    </td>
                    <td className="py-3 px-6 ">
                      <Comps.Select
                        value={switch package.traceRetentionPolicy {
                        | #all => "all"
                        | #onlyErrors => "onlyErrors"
                        | #never => "never"
                        }}
                        onChange={event => {
                          let value = ReactEvent.Form.target(event)["value"]
                          let policy = switch value {
                          | "all" => Some(#all)
                          | "onlyErrors" => Some(#onlyErrors)
                          | "never" => Some(#never)
                          | _ => None
                          }

                          policy->Belt.Option.forEach(policy => {
                            let newPackage = {...package, traceRetentionPolicy: policy}
                            onEditPackage(newPackage)
                          })
                        }}>
                        <option value="all"> {"Keep trace for every invocation"->string} </option>
                        <option value="onlyErrors">
                          {"Only keep trace for invocations with errors"->string}
                        </option>
                        <option value="never"> {"Never retain any trace data"->string} </option>
                      </Comps.Select>
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
                          {"Days to retain trace data: "->string}
                        </span>
                      </div>
                    </td>
                    <td className="py-3 px-6 ">
                      <input
                        disabled={package.traceRetentionPolicy == #never}
                        className="bg-transparent border-none px-2 leading-tight outline-none text-white"
                        type_="number"
                        value={package.traceRetentionDays->string_of_int}
                        placeholder="days"
                        onChange={event => {
                          let value = ReactEvent.Form.target(event)["value"]
                          try {
                            let number = value->int_of_string
                            let newPackage = {...package, traceRetentionDays: number}
                            onEditPackage(newPackage)
                          } catch {
                          | _ => ()
                          }
                        }}
                      />
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
                <span className="mx-2">
                  <code> {initialPackage->stringVersion->string} </code>
                </span>
                <span className="mx-2"> {" => "->string} </span>
                <span className="mx-2">
                  <code> {package->computeNewVersion(diff)->stringVersion->string} </code>
                </span>
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
                <tbody className="text-gray-600 text-sm font-light">
                  {package.chains
                  ->Belt.Array.map(chain => {
                    let typeDef = Chain.typeScriptDefinition(~schema, chain)
                    <tr
                      className={"rounded-md border-4 border-gray-900 text-gray-50 hover:bg-gray-400"}>
                      <td> {typeDef.functionName->string} </td>
                      <td> <Comps.Pre> {typeDef.inputType->string} </Comps.Pre> </td>
                      <td> <Comps.Pre> {typeDef.returnType->string} </Comps.Pre> </td>
                    </tr>
                  })
                  ->array}
                </tbody>
              </table>
            </div>
            <div className="w-full ml-auto flex">
              <Comps.Button className="flex-grow" disabled={true}> {j`Save`->string} </Comps.Button>
              <Comps.Button
              // className="bg-transparent hover:bg-gray-500 text-blue-700 font-semibold hover:text-white py-2 px-4 border border-blue-500 hover:border-transparent rounded flex-grow"
                className="flex-grow"
                onClick={_ => setState(oldState => {...oldState, view: Nothing})}>
                {j`Cancel`->string}
              </Comps.Button>
            </div>
          </div>
        </Comps.Modal>
      }}
    </div>
  }
}

module CollapsableTable = {
  type state = {isOpen: bool}

  @react.component
  let make = (~className="min-w-full leading-normal", ~head, ~children, ~defaultOpen=true) => {
    open React
    let (state, setState) = useState(() => {isOpen: defaultOpen})
    <table className>
      <thead
        className="cursor-pointer" onClick={_ => setState(oldState => {isOpen: !oldState.isOpen})}>
        {head}
      </thead>
      <tbody className={state.isOpen ? "" : "hidden"}> {children} </tbody>
    </table>
  }
}

@val
external parseInt: (string, int) => int = "parseInt"

module ChainLogs = {
  let slowRequestMsThreshold = 800
  let slowChainMsThreshold = 1500

  let stableFakeRequestTime = (~traceId, requestTraceJson) => {
    let magicTraceNumber =
      traceId
      ->Uuid.toString
      ->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("\W+", ~flags="g"), "")
      ->Js.String2.substring(~from=0, ~to_=10)
      ->parseInt(16)

    let length = requestTraceJson->Obj.magic->Js.Json.stringify->Js.String2.length
    let stretched = length + magicTraceNumber
    Js.Math.abs_int(mod(stretched, 1851)) + 50
  }

  type filter = All | Flagged | Errored | Slow

  type state = {inspected: option<Uuid.v4>, filter: filter, search: option<string>}

  @react.component
  let make = (~chain: Chain.t, ~traces: array<Chain.Trace.t>, ~onEditChain) => {
    open React
    let (state, setState) = useState(() => {
      search: None,
      inspected: traces->Belt.Array.get(0)->Belt.Option.map(trace => trace.trace.id),
      filter: All,
    })

    let filterFn = filter =>
      switch (filter, state.search) {
      | (All, None) => _ => true
      | (All, Some(search)) =>
        (trace: Chain.Trace.t) => {
          trace.trace.id
          ->Uuid.toString
          ->Js.String2.match_(Js.Re.fromStringWithFlags(search, ~flags="i"))
          ->Belt.Option.isSome
        }
      | (Flagged, _)
      | (Slow, _) =>
        _ => false
      | (Errored, search) =>
        (trace: Chain.Trace.t) => {
          let hasErrors = Obj.magic(
            trace.trace,
          )["data"]["oneGraph"]["executeChain"]["results"]->Belt.Array.some(result => {
            try {
              let hasErrors = result["result"]->Belt.Array.some(result => {
                result["errors"]->Js.Null_undefined.toOption->Belt.Option.isSome
              })
              hasErrors
            } catch {
            | _ => false
            }
          })

          let searchMatches = switch search {
          | None => true
          | Some(search) =>
            trace.trace.id
            ->Uuid.toString
            ->Js.String2.match_(Js.Re.fromStringWithFlags(search, ~flags="i"))
            ->Belt.Option.isSome
          }

          hasErrors && searchMatches
        }
      }

    let filteredTraces = traces->Belt.Array.keep(filterFn(state.filter))

    let categories = [All, Flagged, Errored, Slow]->Belt.Array.map(category => {
      let name = switch category {
      | All => "All"
      | Flagged => "Flagged"
      | Errored => "Errored"
      | Slow => "Slow"
      }

      let style =
        category == state.filter
          ? ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-16"], ())
          : ReactDOMStyle.make()

      let filterFn = filterFn(category)

      let categoryCount =
        traces->Belt.Array.reduce(0, (acc, next) => filterFn(next) ? acc + 1 : acc)

      <div className="mt-3">
        <div
          style
          className={"-mx-3 inline-block py-1 px-3 text-sm font-medium flex items-center hover:bg-gray-700 cursor-pointer justify-between rounded-lg"}
          onClick={_ => setState(oldState => {...oldState, filter: category, inspected: None})}>
          <span>
            <span style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
              {name->string}
            </span>
          </span>
          {categoryCount > 0
            ? <span
                className="inline-block px-2 py-1 text-center py-1 leading-none text-xs font-semibold text-gray-700 rounded-full"
                style={ReactDOMStyle.make(
                  ~backgroundColor=Comps.colors["gray-17"],
                  ~color=Comps.colors["gray-6"],
                  (),
                )}>
                {categoryCount->string_of_int->string}
              </span>
            : null}
        </div>
      </div>
    })

    let filteredTracesList =
      filteredTraces
      ->Belt.SortArray.stableSortBy((a, b) => {
        b.createdAt->Js.Date.fromString->Obj.magic - a.createdAt->Js.Date.fromString->Obj.magic
      })
      ->Belt.Array.map(trace => {
        let className = Some(trace.trace.id) == state.inspected ? "bg-gray-600" : ""

        let hasErrors = Obj.magic(
          trace.trace,
        )["data"]["oneGraph"]["executeChain"]["results"]->Belt.Array.some(result => {
          try {
            let hasErrors = result["result"]->Belt.Array.some(result => {
              result["errors"]->Js.Null_undefined.toOption->Belt.Option.isSome
            })
            hasErrors
          } catch {
          | _ => false
          }
        })

        <button
          className={"block w-full text-left py-2 border-b hover:bg-gray-700 " ++ className}
          style={ReactDOMStyle.make(
            ~color=Comps.colors["gray-6"],
            ~borderColor=Comps.colors["gray-1"],
            (),
          )}
          onClick={event => {
            event->ReactEvent.Mouse.stopPropagation
            setState(oldState => {...oldState, inspected: Some(trace.trace.id)})
          }}>
          <div className="px-2 flex justify-between">
            <span className="text-xs font-semibold"> {trace.trace.id->Uuid.toString->string} </span>
          </div>
          <div className="px-2 flex justify-between items-center">
            <span
              className="text-xs font-semibold"
              style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}>
              {trace.createdAt->Js.Date.fromString->Utils.Date.timeAgo->string}
            </span>
            <span className="text-xs font-semibold text-gray-900 px-4 py-2">
              {hasErrors ? errored() : noErrors()}
            </span>
          </div>
        </button>
      })

    let noSelectedTrace =
      <div
        className="m-2 w-full text-center flex flex-1 flex-grow flex-col justify-items-center justify-center items-center justify-items align-middle"
        style={ReactDOMStyle.make(~color=Comps.colors["gray-4"], ~height="50%", ())}>
        <Icons.MonoAddBlocks color={Comps.colors["gray-13"]} />
        <span className="mt-2"> {"No trace selected"->React.string} </span>
      </div>

    let inspectedTrace =
      state.inspected
      ->Belt.Option.flatMap(inspectedId => {
        let inspected = traces->Belt.Array.getBy(trace => trace.trace.id == inspectedId)
        inspected
      })
      ->Belt.Option.mapWithDefault(noSelectedTrace, trace => {
        let hasErrors = Obj.magic(
          trace.trace,
        )["data"]["oneGraph"]["executeChain"]["results"]->Belt.Array.some(result => {
          try {
            let hasErrors = result["result"]->Belt.Array.some(result => {
              result["errors"]->Js.Null_undefined.toOption->Belt.Option.isSome
            })
            hasErrors
          } catch {
          | _ => false
          }
        })

        let apiMetrics = trace.trace.extensions->Belt.Option.flatMap(extensions => {
          extensions.metrics->Belt.Option.flatMap(metrics => metrics.api)
        })

        let badges = [
          hasErrors ? errored() : noErrors(),
          apiMetrics->Belt.Option.mapWithDefault(0, m => m.totalRequestMs) > slowChainMsThreshold
            ? slow()
            : null,
        ]

        let variables = trace.variables->Belt.Option.getWithDefault(Js.Json.parseExn("{}"))

        let variableEntries = variables->Obj.magic->Js.Dict.entries

        <>
          <div className="shadow-lg ml-2 mr-2 ">
            <div className="pb-4">
              {<div className="block py-3 border-t">
                <div className="px-4 py-2 flex justify-between">
                  <div>
                    <span
                      className="mr-2"
                      style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
                      <code> {trace.trace.id->Uuid.toString->string} </code>
                    </span>
                    {badges->array}
                  </div>
                  <div>
                    <Comps.Button
                      onClick={_ => {
                        onEditChain(~chain, ~trace)
                      }}>
                      {"Use as mock"->string}
                    </Comps.Button>
                  </div>
                </div>
              </div>}
              <div
                className="w-full m-4"
                style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
                {"General"->string}
              </div>
              <CollapsableTable
                className="min-w-full leading-normal text-xs"
                head={<tr className="text-left mb-2">
                  <th
                    style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}
                    className="px-5 py-3 font-semibold tracking-wider">
                    {j`Host`->string}
                  </th>
                  <th
                    style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}
                    className="px-5 py-3 font-semibold tracking-wider">
                    {j`Request Count`->string}
                  </th>
                  <th
                    style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}
                    className="px-5 py-3 font-semibold tracking-wider">
                    {j`Total ms / host`->string}
                  </th>
                </tr>}>
                {
                  let avoidedReqs =
                    apiMetrics->Belt.Option.mapWithDefault(0, m => m.avoidedRequestCount)

                  <tr
                    className="rounded-sm"
                    style={ReactDOMStyle.make(
                      ~color=Comps.colors["gray-6"],
                      ~backgroundColor=Comps.colors["gray-15"],
                      (),
                    )}>
                    <td className="px-5 py-5 text-sm w-2/5">
                      <div className="flex items-center">
                        <code> {"All hosts"->string} </code>
                      </div>
                    </td>
                    <td className="px-5 py-5 text-sm w-2/5">
                      <p className="whitespace-no-wrap">
                        {(apiMetrics
                        ->Belt.Option.mapWithDefault(0, m => m.requestCount)
                        ->string_of_int ++ " reqs")->string}
                        {switch avoidedReqs {
                        | 0 => null
                        | avoided => j`(${avoided->string_of_int} avoided)`->string
                        }}
                      </p>
                    </td>
                    <td className="px-5 py-5 text-sm w-2/5">
                      <p className="whitespace-no-wrap">
                        {(apiMetrics
                        ->Belt.Option.mapWithDefault(0, m => m.totalRequestMs)
                        ->string_of_int ++ "ms total")->string}
                      </p>
                    </td>
                  </tr>
                }
                {
                  let byHost =
                    trace.trace.extensions
                    ->Belt.Option.flatMap(extensions => extensions.metrics)
                    ->Belt.Option.flatMap(metrics => metrics.api)
                    ->Belt.Option.flatMap(api => api.byHost)
                    ->Belt.Option.mapWithDefault([], Js.Dict.entries)

                  byHost
                  ->Belt.Array.map(((host, metrics)) => {
                    let metrics = metrics->Obj.magic
                    <tr
                      className="rounded-sm"
                      style={ReactDOMStyle.make(
                        ~color=Comps.colors["gray-6"],
                        ~backgroundColor=Comps.colors["gray-15"],
                        (),
                      )}>
                      <td className="px-5 py-5 text-sm w-2/5">
                        <div className="flex items-center">
                          <code> {(host ++ ": ")->string} </code>
                        </div>
                      </td>
                      <td className="px-5 py-5 text-sm w-2/5">
                        <p className="whitespace-no-wrap">
                          {(metrics["requestCount"]->string_of_int ++ " reqs")->string}
                        </p>
                      </td>
                      <td className="px-5 py-5 text-sm w-2/5">
                        <p className="whitespace-no-wrap">
                          {(metrics["totalRequestMs"]->string_of_int ++ "ms total")->string}
                        </p>
                      </td>
                    </tr>
                  })
                  ->array
                }
              </CollapsableTable>
            </div>
          </div>
          <div className="shadow-lg ml-2 mr-2 ">
            <div className="pb-4">
              {<div className="block" style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
                <div className="px-4 py-2 flex justify-between">
                  {switch variableEntries {
                  | [] => <span> {j`No variables in trace`->string} </span>
                  | _ => <span> {j`Trace Variables `->string} </span>
                  }}
                </div>
              </div>}
              {switch variableEntries {
              | [] => null
              | entries =>
                <CollapsableTable
                  className="min-w-full leading-normal"
                  head={<tr className="text-left mb-2">
                    <th
                      style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}
                      className="px-5 py-3 font-semibold tracking-wider">
                      {j`Name`->string}
                    </th>
                    <th
                      style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}
                      className="px-5 py-3 font-semibold tracking-wider">
                      {j`Value`->string}
                    </th>
                  </tr>}>
                  {entries
                  ->Belt.Array.map(((key, value)) => {
                    <tr>
                      <td className="px-5 py-5 border-b border-gray-200 bg-white text-sm w-2/5">
                        <div className="flex items-center"> <code> {key->string} </code> </div>
                      </td>
                      <td
                        className="px-5 py-5 border-b border-gray-200 bg-white text-sm overflow-x-scroll overflow-y-scroll">
                        <pre className="text-gray-900 whitespace-no-wrap text-left">
                          {value->Js.Json.stringifyWithSpace(2)->string}
                        </pre>
                      </td>
                    </tr>
                  })
                  ->array}
                </CollapsableTable>
              }}
            </div>
          </div>
          <div>
            {Obj.magic(trace.trace)["data"]["oneGraph"]["executeChain"]["results"]
            ->Belt.Array.map(result => {
              let request = result["request"]

              let chainRequest = chain.requests->Belt.Array.getBy(chainRequest => {
                request["id"] == chainRequest.id
              })

              let serviceImages = chainRequest->Belt.Option.mapWithDefault(null, request => {
                let images =
                  request.operation.services
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
                        className={" h-6 w-6 rounded-full object-cover transform hover:scale-125 inline-block border-2 border-gray-300 " ++ (
                          idx > 0 ? "-m-1" : "ml-2"
                        )}
                      />
                    )
                  )
                  ->Belt.Array.keepMap(el => el)

                images->array
              })

              let fakeRequestLength = stableFakeRequestTime(~traceId=trace.trace.id, result)
              let slowRequest = fakeRequestLength > slowRequestMsThreshold

              let hasErrors =
                result["result"]
                ->Belt.Array.keep(result =>
                  result->Obj.magic->Js.Nullable.toOption->Belt.Option.isSome
                )
                ->Belt.Array.some(result => {
                  result["errors"]->Js.Null_undefined.toOption->Belt.Option.isSome
                })

              let argumentDependencies = result["argumentDependencies"]

              let argumentDependenciesTable =
                argumentDependencies->Belt.Array.length == 0
                  ? null
                  : <CollapsableTable
                      className="min-w-full leading-normal"
                      head={<tr className="text-left mb-2">
                        <th
                          style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}
                          className="px-5 py tracking-wider font-normal">
                          {"Name / Status"->string}
                        </th>
                        <th
                          style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}
                          className="px-5 py tracking-wider font-normal">
                          {"Value"->string}
                        </th>
                        <th
                          style={ReactDOMStyle.make(~color=Comps.colors["gray-3"], ())}
                          className="px-5 py tracking-wider font-normal">
                          {"Logs"->string}
                        </th>
                      </tr>}>
                      {argumentDependencies
                      ->Obj.magic
                      ->Belt.Array.map(argumentDependency => {
                        let status =
                          argumentDependency["error"]
                          ->Js.Nullable.toOption
                          ->Belt.Option.mapWithDefault(null, _ => errored())

                        let argumentDependency = Obj.magic(argumentDependency)
                        <tr
                          className="border-b-2"
                          style={ReactDOMStyle.make(
                            ~backgroundColor=Comps.colors["gray-15"],
                            ~borderColor=Comps.colors["gray-8"],
                            ~color=Comps.colors["gray-6"],
                            (),
                          )}>
                          <td className="px-5 py-1 text-sm w-2/5">
                            {status} {" "->string} {argumentDependency["name"]->string}
                          </td>
                          <td className="px-5 py-1 text-sm w-2/5">
                            <pre className="overflow-x-scroll w-full overflow-y-scroll">
                              {argumentDependency["returnValues"]
                              ->Js.Null_undefined.toOption
                              ->Belt.Option.getWithDefault([])
                              ->Belt.Array.get(0)
                              ->Belt.Option.mapWithDefault("", value => {
                                value->Js.Json.stringifyWithSpace(2)
                              })
                              ->string}
                            </pre>
                          </td>
                          <td className="px-5 py-1 text-sm w-2/5">
                            <pre className="overflow-x-scroll overflow-y-scroll">
                              {argumentDependency["logs"]
                              ->Belt.Array.map((output: logLine<'a>) => {
                                let color = switch output.level {
                                | #info => Comps.colors["gray-6"]
                                | #warn => Comps.colors["yellow"]
                                | #error => Comps.colors["red"]
                                }
                                <span style={ReactDOMStyle.make(~color, ())}>
                                  {output.body->Obj.magic->Js.Json.stringify->string}
                                </span>
                              })
                              ->array}
                            </pre>
                          </td>
                        </tr>
                      })
                      ->array}
                    </CollapsableTable>

              let badges = [hasErrors ? errored() : null, slowRequest ? slow() : null]

              <div
                className="shadow-lg ml-2 mr-2 rounded-lg border-t"
                style={ReactDOMStyle.make(~borderColor=Comps.colors["gray-1"], ())}>
                <div className="block py-3 pb-4">
                  <div
                    className="px-4 py-2 flex justify-between"
                    style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
                    <div>
                      <span className="text-sm  mr-2"> {request["id"]->string} </span>
                      {badges->array}
                      serviceImages
                    </div>
                    <div className="flex">
                      <span
                        className="px-4 text-sm  "
                        style={ReactDOMStyle.make(~borderColor=Comps.colors["gray-6"], ())}>
                        {j`${fakeRequestLength->string_of_int}ms`->string}
                      </span>
                    </div>
                  </div>
                  {argumentDependenciesTable}
                  <div className="px-4 py-2 text-sm font-semibold text-gray-700">
                    {result["result"]
                    ->Belt.Array.map(result => {
                      <ReactJsonView
                        src={result
                        ->Obj.magic
                        ->Js.Nullable.toOption
                        ->Belt.Option.getWithDefault(Js.Dict.empty())}
                        collapsed=true
                        name={request["id"]}
                        displayDataTypes=false
                        theme="monokai"
                      />
                    })
                    ->array}
                  </div>
                </div>
              </div>
            })
            ->array}
            <div
              className="w-full m-4" style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
              {"Raw API Requests"->string}
            </div>
            {trace.trace.extensions
            ->Belt.Option.flatMap(extensions => extensions.apiRequests)
            ->Belt.Option.getWithDefault([])
            ->Belt.Array.map(apiRequest => {
              let apiRequest = apiRequest->Obj.magic
              let title = `${apiRequest["method"]} ${apiRequest["uri"]}`

              <div className="shadow-lg pt-4 ml-2 mr-2 rounded-lg">
                <div
                  className="block py-3 border-t pb-4"
                  style={ReactDOMStyle.make(
                    ~color=Comps.colors["gray-6"],
                    ~backgroundColor=Comps.colors["gray-15"],
                    (),
                  )}>
                  <div className="px-4 py-2 flex justify-between">
                    <span className="inline-block text-sm font-semibold truncate">
                      {title->string}
                    </span>
                  </div>
                  <ReactJsonView
                    src={apiRequest}
                    collapsed=true
                    name={"apiCall"}
                    displayDataTypes=false
                    theme="monokai"
                  />
                </div>
              </div>
            })
            ->array}
          </div>
        </>
      })

    <div
      className="flex flex-col"
      style={ReactDOMStyle.make(
        ~height="calc(100vh - 56px)",
        ~backgroundColor=Comps.colors["gray-8"],
        (),
      )}>
      <div className="flex-1 flex overflow-x-hidden">
        <div className="p-6 overflow-y-auto" style={ReactDOMStyle.make(~width="256px", ())}>
          <nav>
            <h2
              className="font-semibold uppercase tracking-wide"
              style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
              {j`Logs`->string}
            </h2>
            {categories->array}
          </nav>
        </div>
        <main className="flex flex-1 w-full">
          <div
            style={ReactDOMStyle.make(~width="334px", ~borderColor=Comps.colors["gray-1"], ())}
            className="overflow-y-auto overflow-hidden border-l border-r p-6"
            onClick={_ => setState(oldState => {...oldState, inspected: None})}>
            <h2
              className="font-semibold uppercase tracking-wide"
              style={ReactDOMStyle.make(~color=Comps.colors["gray-6"], ())}>
              {j`Traces`->string}
            </h2>
            <div
              className="flex items-center my-4 rounded-md inline-block"
              style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}>
              <div className="pl-2"> <Icons.Search color={Comps.colors["gray-4"]} /> </div>
              <input
                className="w-full rounded-md text-gray-200 leading-tight focus:outline-none py-2 px-2 border-0 text-white"
                style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}
                id="search"
                spellCheck=false
                type_="text"
                placeholder="Search"
                onChange={event => {
                  let value = ReactEvent.Form.target(event)["value"]
                  setState(oldState => {
                    ...oldState,
                    search: switch value->Js.String2.trim {
                    | "" => None
                    | other => Some(other)
                    },
                  })
                }}
              />
            </div>
            <div className="pb-4"> {filteredTracesList->array} </div>
          </div>
          <div
          // style={ReactDOMStyle.make(~maxWidth="850px", ())}
            className="flex flex-col flex-1 w-auto inline-block overflow-y-auto overflow-hidden">
            {inspectedTrace}
          </div>
        </main>
      </div>
    </div>
  }
}

type inspectable = Package | Chain(Chain.t) | Edit({chain: Chain.t, trace: option<Chain.Trace.t>})

type state = {inspected: inspectable, package: t, initialPackage: t, helpOpen: bool}

@react.component
let make = (~schema, ~config) => {
  open React

  let (state: state, setState) = useState(() => {
    let initialChains = [
      DevTimeJson.descuriChain,
      DevTimeJson.spotifyChain,
      DevTimeJson.devJsonChain,
    ]

    let initialChains = Chain.loadFromLocalStorage()->Belt.Array.concat(initialChains)

    let package: t = {
      name: "bushido-fns",
      version: (1, 0, 1),
      chains: initialChains,
      traceRetentionDays: 5,
      traceRetentionPolicy: #all,
    }

    {
      inspected: Package,
      // Edit({chain: initialChains[0], trace: None}),
      package: package,
      initialPackage: package,
      helpOpen: false,
    }
  })

  ReactHotKeysHook.useHotkeys(
    ~keys="shift+/",
    ~callback=(event, _handler) => {
      event->ReactEvent.Keyboard.preventDefault
      event->ReactEvent.Keyboard.stopPropagation
      setState(oldState => {...oldState, helpOpen: !oldState.helpOpen})
    },
    ~options=ReactHotKeysHook.options(),
    ~deps=None,
  )

  ReactHotKeysHook.useHotkeys(
    ~keys="esc",
    ~callback=(_event, _handler) => {
      setState(oldState => {
        oldState.helpOpen ? {...oldState, helpOpen: false} : oldState
      })
    },
    ~options=ReactHotKeysHook.options(),
    ~deps=None,
  )

  let navButton = (~onClick, ~onDoubleClick=?, content) => {
    <button className="mr-2" ?onDoubleClick onClick> content </button>
  }

  let content = switch state.inspected {
  | Chain(chain) =>
    let traces =
      Chain.Trace.loadFromLocalStorage()->Belt.Array.keep(trace => Some(trace.chainId) == chain.id)
    <ChainLogs
      chain
      traces
      onEditChain={(~chain, ~trace) => {
        setState(oldState => {
          ...oldState,
          inspected: Edit({chain: chain, trace: Some(trace)}),
        })
      }}
    />
  | Edit({chain, trace}) =>
    <ChainEditor
      config
      schema
      initialChain=chain
      trace
      helpOpen=state.helpOpen
      onSaveChain={(newChain: Chain.t) => {
        setState(oldState => {
          newChain->Chain.saveToLocalStorage

          let inspected = switch oldState.inspected {
          | Edit({trace}) => Edit({chain: newChain, trace: trace})
          | _ => Edit({chain: newChain, trace: None})
          }
          {
            ...oldState,
            package: {
              ...oldState.package,
              chains: oldState.package.chains->Belt.Array.map(oldChain => {
                oldChain.id == newChain.id ? newChain : oldChain
              }),
            },
            inspected: inspected,
          }
        })
      }}
      onClose={() => {
        setState(oldState => {
          ...oldState,
          inspected: Package,
        })
      }}
      onSaveAndClose={newChain => {
        setState(oldState => {
          ...oldState,
          inspected: Package,
          package: {
            ...oldState.package,
            chains: oldState.package.chains->Belt.Array.map(oldChain => {
              oldChain == chain ? newChain : oldChain
            }),
          },
        })
      }}
    />
  | Package =>
    <PackageEditor
      schema
      package=state.package
      initialPackage=state.initialPackage
      onEditPackage={newPackage => {
        setState(oldState => {
          ...oldState,
          package: newPackage,
        })
      }}
      onDeleteChain={targetChain => {
        targetChain->Chain.deleteFromLocalStorage
        setState(oldState => {
          ...oldState,
          package: {
            ...oldState.package,
            chains: oldState.package.chains->Belt.Array.keep(chain => chain.id != targetChain.id),
          },
          inspected: Package,
        })
      }}
      onCreateChain={newChain => {
        newChain->Chain.saveToLocalStorage
        setState(oldState => {
          ...oldState,
          package: {
            ...oldState.package,
            chains: oldState.package.chains->Belt.Array.concat([newChain]),
          },
          inspected: Edit({chain: newChain, trace: None}),
        })
      }}
      onInspectChain={chain => {
        setState(oldState => {
          ...oldState,
          inspected: Chain(chain),
        })
      }}
      onEditChain={(~chain, ~trace) => {
        setState(oldState => {
          ...oldState,
          inspected: Edit({chain: chain, trace: trace}),
        })
      }}
    />
  }

  let makeNav = (inspected: inspectable) => {
    <nav
      className="p-4 text-white"
      style={ReactDOMStyle.make(
        ~color=Comps.colors["gray-11"],
        ~backgroundColor=Comps.colors["gray-12"],
        (),
      )}>
      {navButton(~onClick=_ => (), "OneGraph"->string)}
      {navButton(~onClick=_ => {
        setState(oldState => {
          ...oldState,
          inspected: Package,
        })
      }, (" > " ++ state.package.name)->string)}
      {switch inspected {
      | Package => React.null
      | Chain(chain)
      | Edit({chain}) =>
        navButton(~onClick=_ => (), <strong> {(" >" ++ chain.name)->string} </strong>)
      }}
    </nav>
  }
  <> {makeNav(state.inspected)} {content} </>
}

let r = Babel.transform
