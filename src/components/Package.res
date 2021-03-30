module DevTimeJson = {
  @module("../DevTime_Json.js") external traces: array<Chain.Trace.t> = "traces"
  @module("../DevTime_Json.js") external devJsonChain: Chain.t = "devJsonChain"
  @module("../DevTime_Json.js") external simpleChain: Chain.t = "simpleChain"
  @module("../DevTime_Json.js") external spotifyChain: Chain.t = "spotifyChain"
  @module("../DevTime_Json.js") external descuriChain: Chain.t = "descuriChain"
}

type info = {
  name: string,
  version: string,
  chains: array<Chain.t>,
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
  @react.component
  let make = (
    ~schema,
    ~package: info,
    ~chains: array<Chain.t>,
    ~onCreateChain,
    ~onInspectChain,
    ~onEditChain,
    ~onDeleteChain,
  ) => {
    open React

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
            // style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}
              onClick={_ => {
                switch Utils.prompt(
                  "New chain name",
                  ~default=Some("new_chain"),
                )->Belt.Option.mapWithDefault("", name => name->Js.String2.trim) {
                | "" => ()
                | other =>
                  let chain = Chain.makeEmptyChain(other)
                  onCreateChain(chain)
                }
              }}>
              <Icons.Gears className="inline-block " color={Comps.colors["gray-4"]} />
              {" Package Settings"->string}
            </Comps.Button>
          </div>
          <div className="m-2">
            <Comps.Button
            // style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}
              onClick={_ => {
                switch Utils.prompt(
                  "Publish changes to npm",
                  ~default=Some("new_chain"),
                )->Belt.Option.mapWithDefault("", name => name->Js.String2.trim) {
                | "" => ()
                | other =>
                  let chain = Chain.makeEmptyChain(other)
                  onCreateChain(chain)
                }
              }}>
              <Icons.Login className="inline-block " color={Comps.colors["gray-4"]} />
              {" Publsh changes to npm"->string}
            </Comps.Button>
          </div>
          <div className="m-2">
            <Comps.Button
            // style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}
              onClick={_ => {
                switch Utils.prompt(
                  "New chain name",
                  ~default=Some("new_chain"),
                )->Belt.Option.mapWithDefault("", name => name->Js.String2.trim) {
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
                          onInspectChain(chain)
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

      let className = category == state.filter ? " bg-gray-200" : ""

      let filterFn = filterFn(category)

      let categoryCount =
        traces->Belt.Array.reduce(0, (acc, next) => filterFn(next) ? acc + 1 : acc)

      <div className="mt-3">
        <div
          className={"-mx-3 inline-block py-1 px-3 text-sm font-medium flex items-center hover:bg-gray-200 cursor-pointer justify-between rounded-lg" ++
          className}
          onClick={_ => setState(oldState => {...oldState, filter: category, inspected: None})}>
          <span> <span className="text-gray-900"> {name->string} </span> </span>
          {categoryCount > 0
            ? <span
                className="inline-block px-4 py-1 text-center py-1 leading-none text-xs font-semibold text-gray-700 bg-gray-300 rounded-full">
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
        let className = Some(trace.trace.id) == state.inspected ? "bg-gray-300" : ""

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
          className={"block bg-white w-full text-left py-3 border-t hover:bg-gray-300 " ++
          className}
          onClick={event => {
            event->ReactEvent.Mouse.stopPropagation
            setState(oldState => {...oldState, inspected: Some(trace.trace.id)})
          }}>
          <div className="px-4 flex justify-between">
            <span className="text-xs font-semibold text-gray-900">
              {trace.trace.id->Uuid.toString->string}
            </span>
          </div>
          <div className="px-4 flex justify-between">
            <span className="text-xs font-semibold text-gray-600">
              {trace.createdAt->Js.Date.fromString->Utils.Date.timeAgo->string}
            </span>
          </div>
          <span className="text-xs font-semibold text-gray-900 px-4 py-2">
            {hasErrors ? errored() : noErrors()}
          </span>
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

        Js.log2("trace->apiMetrics: ", trace)

        let apiMetrics = trace.trace.extensions->Belt.Option.flatMap(extensions => {
          Js.log2("Extensions: ", extensions)
          extensions.metrics->Belt.Option.flatMap(metrics => metrics.api)
        })

        let badges = [
          hasErrors ? errored() : noErrors(),
          apiMetrics->Belt.Option.mapWithDefault(0, m => m.totalRequestMs) > slowChainMsThreshold
            ? slow()
            : null,
        ]

        <>
          <div className="shadow-lg ml-2 mr-2 ">
            <div className="pb-4">
              {<div className="block bg-white py-3 border-t">
                <div className="px-4 py-2 flex  justify-between">
                  <span>
                    {j`Trace: `->string} <code> {trace.trace.id->Uuid.toString->string} </code>
                  </span>
                  <div>
                    {badges->array}
                    <Comps.Button
                      onClick={_ => {
                        onEditChain(~chain, ~trace)
                      }}>
                      {"Use as mock"->string}
                    </Comps.Button>
                  </div>
                </div>
              </div>}
              <CollapsableTable
                className="min-w-full leading-normal"
                head={<tr>
                  <th
                    className="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-center text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    {j`Host`->string}
                  </th>
                  <th
                    className="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-center text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    {j`Request Count`->string}
                  </th>
                  <th
                    className="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-center text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    {j`Total ms / host`->string}
                  </th>
                </tr>}>
                {
                  let avoidedReqs =
                    apiMetrics->Belt.Option.mapWithDefault(0, m => m.avoidedRequestCount)

                  <tr>
                    <td className="px-5 py-5 border-b border-gray-200 bg-white text-sm w-2/5">
                      <div className="flex items-center">
                        <code> {"All hosts"->string} </code>
                      </div>
                    </td>
                    <td className="px-5 py-5 border-b border-gray-200 bg-white text-sm">
                      <p className="text-gray-900 whitespace-no-wrap text-center">
                        {(apiMetrics
                        ->Belt.Option.mapWithDefault(0, m => m.requestCount)
                        ->string_of_int ++ " reqs")->string}
                        {switch avoidedReqs {
                        | 0 => null
                        | avoided => j`(${avoided->string_of_int} avoided)`->string
                        }}
                      </p>
                    </td>
                    <td className="px-5 py-5 border-b border-gray-200 bg-white text-sm">
                      <p className="text-gray-900 whitespace-no-wrap text-center">
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
                    <tr>
                      <td className="px-5 py-5 border-b border-gray-200 bg-white text-sm w-2/5">
                        <div className="flex items-center">
                          <code> {(host ++ ": ")->string} </code>
                        </div>
                      </td>
                      <td className="px-5 py-5 border-b border-gray-200 bg-white text-sm">
                        <p className="text-gray-900 whitespace-no-wrap text-center">
                          {(metrics["requestCount"]->string_of_int ++ " reqs")->string}
                        </p>
                      </td>
                      <td className="px-5 py-5 border-b border-gray-200 bg-white text-sm">
                        <p className="text-gray-900 whitespace-no-wrap text-center">
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
              {<div className="block bg-white border-t">
                <div className="px-4 py-2 flex  justify-between">
                  <span> {j`Trace Variables `->string} </span>
                </div>
              </div>}
              <CollapsableTable
                className="min-w-full leading-normal"
                head={<tr>
                  <th
                    className="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-center text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    {j`Name`->string}
                  </th>
                  <th
                    className="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-center text-xs font-semibold text-gray-600 uppercase tracking-wider">
                    {j`value`->string}
                  </th>
                </tr>}>
                {
                  let variables =
                    trace.variables->Belt.Option.getWithDefault(Js.Json.parseExn("{}"))

                  variables
                  ->Obj.magic
                  ->Js.Dict.entries
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
                  ->array
                }
              </CollapsableTable>
            </div>
          </div>
          <div>
            {Obj.magic(trace.trace)["data"]["oneGraph"]["executeChain"]["results"]
            ->Belt.Array.map(result => {
              let request = result["request"]

              let hasErrors = try {
                result["result"]->Belt.Array.some(result => {
                  result["errors"]->Js.Null_undefined.toOption->Belt.Option.isSome
                })
              } catch {
              | _ => false
              }
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
                        className={" h-6 w-6 rounded-full object-cover transform hover:scale-125 " ++ (
                          idx > 0 ? "-m-1" : ""
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
                      head={<tr>
                        <th
                          className="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                          {"Name / Status"->string}
                        </th>
                        <th
                          className="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                          {"Value"->string}
                        </th>
                        <th
                          className="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                          {"Logs"->string}
                        </th>
                      </tr>}>
                      {argumentDependencies
                      ->Belt.Array.map(argumentDependency => {
                        let status =
                          argumentDependency["error"]
                          ->Js.Nullable.toOption
                          ->Belt.Option.mapWithDefault(noErrors(), _ => errored())

                        let argumentDependency = Obj.magic(argumentDependency)
                        <tr>
                          <td className="px-5 py-1 border-b border-gray-200 bg-white text-sm w-2/5">
                            {status} {" "->string} {argumentDependency["name"]->string}
                          </td>
                          <td className="px-5 py-1 border-b border-gray-200 bg-white text-sm w-2/5">
                            <pre className="overflow-x-scroll w-full overflow-y-scroll">
                              {argumentDependency["returnValues"]
                              ->Belt.Array.get(0)
                              ->Belt.Option.mapWithDefault("", value => {
                                value->Js.Json.stringifyWithSpace(2)
                              })
                              ->string}
                            </pre>
                          </td>
                          <td className="px-5 py-1 border-b border-gray-200 bg-white text-sm w-2/5">
                            <pre className="overflow-x-scroll overflow-y-scroll">
                              {argumentDependency["logs"]
                              ->Belt.Array.map(output =>
                                output->Obj.magic->Js.Json.stringifyWithSpace(2)
                              )
                              ->Js.Array2.joinWith("\n")
                              ->string}
                            </pre>
                          </td>
                        </tr>
                      })
                      ->array}
                    </CollapsableTable>

              let badges = [hasErrors ? errored() : null, slowRequest ? slow() : null]

              <div className="shadow-lg pt-4 ml-2 mr-2 rounded-lg">
                <div className="block bg-white py-3 border-t pb-4">
                  <div className="px-4 py-2 flex  justify-between">
                    <span className="text-sm font-semibold text-gray-900">
                      {request["id"]->string}
                    </span>
                    <div className="flex">
                      {badges->array}
                      <span className="px-4 text-sm font-semibold text-gray-600">
                        {j`${fakeRequestLength->string_of_int}ms`->string}
                      </span>
                      serviceImages
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
                      />
                    })
                    ->array}
                  </div>
                </div>
              </div>
            })
            ->array}
            <div className="w-full m-4"> {"Raw API Requests"->string} </div>
            {trace.trace.extensions
            ->Belt.Option.flatMap(extensions => extensions.apiRequests)
            ->Belt.Option.getWithDefault([])
            ->Belt.Array.map(apiRequest => {
              let apiRequest = apiRequest->Obj.magic
              let title = `${apiRequest["method"]} ${apiRequest["uri"]}`

              <div className="shadow-lg pt-4 ml-2 mr-2 rounded-lg">
                <div className="block bg-white py-3 border-t pb-4">
                  <div className="px-4 py-2 flex  justify-between">
                    <span className="inline-block  text-sm font-semibold text-gray-900 truncate">
                      {title->string}
                    </span>
                  </div>
                  <ReactJsonView
                    src={apiRequest} collapsed=true name={"apiCall"} displayDataTypes=false
                  />
                </div>
              </div>
            })
            ->array}
          </div>
        </>
      })

    <div className="flex flex-col" style={ReactDOMStyle.make(~height="calc(100vh - 56px)", ())}>
      <div className="flex-1 flex overflow-x-hidden">
        <div
          className="p-6 bg-gray-100 overflow-y-auto"
          style={ReactDOMStyle.make(~width="256px", ())}>
          <nav>
            <h2 className="font-semibold text-gray-600 uppercase tracking-wide">
              {j`Logs`->string}
            </h2>
            {categories->array}
          </nav>
        </div>
        <main className="flex flex-1 bg-gray-200 w-full">
          <div
            style={ReactDOMStyle.make(~width="334px", ())}
            className="overflow-y-auto overflow-hidden"
            onClick={_ => setState(oldState => {...oldState, inspected: None})}>
            <div className="px-4 py-2 flex items-center justify-between border-l border-r border-b">
              <button className="text-sm flex items-center font-semibold text-gray-600">
                <span> {j`Traces`->string} </span>
              </button>
              <button className="text-sm flex items-center font-semibold text-gray-600" />
            </div>
            <div className="pb-4">
              <div className="mt-3">
                <span
                  className="-mx-3 text-sm font-medium flex items-center justify-between bg-gray-200 rounded-lg">
                  <input
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
                    className="focus:bg-gray-200 focus:text-gray-900 focus:placeholder-gray-700 pl-4 pr-4 py-2 leading-none block w-full bg-gray-900 rounded-lg text-sm placeholder-gray-400 text-white focus:border-none focus:outline-none outline-none"
                    placeholder="Search"
                  />
                </span>
              </div>
              {filteredTracesList->array}
            </div>
          </div>
          <div
            style={ReactDOMStyle.make(~maxWidth="850px", ())}
            className="flex flex-col flex-1 w-auto inline-block overflow-y-auto overflow-hidden bg-gray-100">
            {inspectedTrace}
          </div>
        </main>
      </div>
    </div>
  }
}

type inspectable = Package | Chain(Chain.t) | Edit({chain: Chain.t, trace: option<Chain.Trace.t>})

type state = {inspected: inspectable, chains: array<Chain.t>, package: info}

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

    let chain =
      initialChains
      ->Belt.Array.get(0)
      ->Belt.Option.getWithDefault(Chain.makeEmptyChain("new_chain"))

    let traces =
      Chain.Trace.loadFromLocalStorage()->Belt.Array.keep(trace => Some(trace.chainId) == chain.id)
    // let trace = traces->Belt.Array.reverse->Belt.Array.get(0)

    let package: info = {
      name: "bushido-fns",
      version: "1.0.1",
      chains: initialChains,
    }

    {
      inspected: Package,
      //Edit({chain: chain, trace: trace}),
      chains: initialChains,
      package: package,
    }
  })

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
      onSaveChain={(newChain: Chain.t) => {
        setState(oldState => {
          newChain->Chain.saveToLocalStorage

          let inspected = switch oldState.inspected {
          | Edit({trace}) => Edit({chain: newChain, trace: trace})
          | _ => Edit({chain: newChain, trace: None})
          }
          {
            ...oldState,
            chains: oldState.chains->Belt.Array.map(oldChain => {
              Js.log3("Looking to save chain: ", oldChain.id, newChain.id)
              oldChain.id == newChain.id ? newChain : oldChain
            }),
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
          chains: oldState.chains->Belt.Array.map(oldChain => {
            oldChain == chain ? newChain : oldChain
          }),
        })
      }}
    />
  | Package =>
    <PackageEditor
      schema
      package=state.package
      chains=state.chains
      onDeleteChain={targetChain => {
        targetChain->Chain.deleteFromLocalStorage
        setState(oldState => {
          ...oldState,
          chains: oldState.chains->Belt.Array.keep(chain => chain.id != targetChain.id),
          inspected: Package,
        })
      }}
      onCreateChain={newChain => {
        newChain->Chain.saveToLocalStorage
        setState(oldState => {
          ...oldState,
          chains: oldState.chains->Belt.Array.concat([newChain]),
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
      className="p-4  text-white"
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
        navButton(
          ~onClick=_ => (),
          ~onDoubleClick={
            _ => {
              let newName = Utils.prompt("Rename chain", ~default=Some(chain.name))
              switch newName {
              | None | Some("") => ()
              | Some(newName) =>
                setState(oldState => {
                  oldState
                })
              }
            }
          },
          <strong> {(" >" ++ chain.name)->string} </strong>,
        )
      }}
    </nav>
  }
  <> {makeNav(state.inspected)} {content} </>
}
