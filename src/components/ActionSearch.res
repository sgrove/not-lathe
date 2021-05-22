module Query = %relay(`
  query ActionSearchQuery {
    oneGraph {
      studio {
        actions {
          id
          name
          services
          ...ActionSearch_oneGraphStudioChainAction
        }
      }
    }
  }
`)

module Action = {
  module OneGraphStudioChainActionFragment = %relay(`
  fragment ActionSearch_oneGraphStudioChainAction on OneGraphStudioChainAction {
    id
    name
    services
  }
`)

  @react.component
  let make = (~fragmentRefs, ~onInspect, ~onAdd) => {
    let action = OneGraphStudioChainActionFragment.use(fragmentRefs)

    open React
    <div
      key={action.name}
      className="block-search-item flex justify-start cursor-grab text-gray-700 items-center hover:text-blue-400 rounded-md px-2 my-2"
      draggable=true
      onDragStart={event => {
        let dataTransfer = Obj.magic(event)["dataTransfer"]
        dataTransfer["effectAllowed"] = "copyLink"
        dataTransfer["setData"]("text", action.id)
      }}
      onDoubleClick={_ => {
        onAdd(action)
      }}
      onClick={_ => onInspect(action)}>
      <div
        style={
          let color = "B20D5D"
          // switch Card.Query {
          // | Card.Query => "1BBE83"
          // | Card.Mutation => "B20D5D"
          // | Subscription => "F2C94C"
          // | Fragment => "F2C94C"
          // | Compute => Comps.colors["gray-10"]
          // }

          ReactDOMStyle.make(
            ~background=j`radial-gradient(ellipse at center, #${color} 0%, #${color} 30%, transparent 30%)`,
            ~width="10px",
            ~height="10px",
            ~backgroundRepeat="repeat-x",
            (),
          )
        }
      />
      <div
        style={ReactDOMStyle.make(~color="#F2F2F2", ())}
        className="flex-grow font-medium px-2 py-2 truncate">
        {action.name->string}
      </div>
      <div style={ReactDOMStyle.make(~minWidth="40px", ())} className="px-2 rounded-r-md py-2">
        {action.services
        ->Belt.Array.keepMap(service =>
          service
          ->Utils.serviceImageUrl
          ->Belt.Option.map(((url, friendlyServiceName)) =>
            <img
              key={friendlyServiceName}
              alt=friendlyServiceName
              title=friendlyServiceName
              style={ReactDOMStyle.make(
                ~pointerEvents="none",
                ~opacity="0.80",
                ~border="2px",
                ~borderStyle="solid",
                ~borderColor=Comps.colors["gray-6"],
                (),
              )}
              width="24px"
              src=url
              className="rounded-full"
            />
          )
        )
        ->array}
      </div>
    </div>
  }
}

type state = {
  search: option<string>,
  results: array<ActionSearchQuery_graphql.Types.response_oneGraph_studio_actions>,
}

@val external alert: string => unit = "alert"

@react.component
let make = (
  ~onAdd: ActionSearch_oneGraphStudioChainAction_graphql.Types.fragment => unit,
  ~onInspect: ActionSearch_oneGraphStudioChainAction_graphql.Types.fragment => unit,
  ~onCreate,
  ~onClose,
) => {
  let data = Query.use(~variables=(), ())
  let actions = data.oneGraph.studio.actions

  open React

  let inputRef = React.useRef(Js.Nullable.null)

  ReactHotKeysHook.useHotkeys(
    ~keys="/",
    ~callback=(event, _handler) => {
      inputRef.current
      ->Js.Nullable.toOption
      ->Belt.Option.forEach(inputRef => {
        event->ReactEvent.Keyboard.preventDefault
        Obj.magic(inputRef)["focus"]()
      })
    },
    ~options=ReactHotKeysHook.options(),
    ~deps=None,
  )

  let (state, setState) = useState(() => {
    search: None,
    results: actions->Belt.SortArray.stableSortBy((a, b) =>
      String.compare(a.name->Js.String2.toLocaleLowerCase, b.name->Js.String2.toLocaleLowerCase)
    ),
  })

  let searchActions = (
    actions: array<ActionSearchQuery_graphql.Types.response_oneGraph_studio_actions>,
    term,
  ) =>
    actions
    ->Belt.Array.keep(action => {
      let titleMatch =
        action.name
        ->Js.String2.match_(term->Js.Re.fromStringWithFlags(~flags="ig"))
        ->Belt.Option.isSome

      let servicesMatch =
        action.services->Belt.Array.some(service =>
          service
          ->Js.String2.match_(term->Js.Re.fromStringWithFlags(~flags="ig"))
          ->Belt.Option.isSome
        )

      titleMatch || servicesMatch
    })
    ->Js.Array2.sortInPlaceWith((a, b) =>
      String.compare(a.name->Js.String2.toLocaleLowerCase, b.name->Js.String2.toLocaleLowerCase)
    )

  useEffect1(() => {
    switch state.search {
    | None => ()
    | Some(term) =>
      let results = actions->searchActions(term)
      setState(oldState => {...oldState, results: results})
    }
    None
  }, [actions->Belt.Array.length])

  <div
    className="flex w-full m-0 h-full block select-none"
    style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-9"], ())}>
    <div className="w-full max-h-full">
      <Comps.Header
        style={ReactDOMStyle.make(
          ~display="flex",
          ~justifyContent="space-between",
          ~marginRight="6px",
          (),
        )}>
        {"Action Library"->React.string}
        <span className="text-white cursor-pointer" onClick={_ => onClose()}>
          {j`⨂`->React.string}
        </span>
      </Comps.Header>
      <div
        className="rounded-lg px-3 py-2 overflow-y-hidden"
        style={ReactDOMStyle.make(~height="calc(100% - 40px)", ())}>
        <div
          className="flex items-center rounded-md inline-block"
          style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}>
          <div className="pl-2"> <Icons.Search color={Comps.colors["gray-4"]} /> </div>
          <input
            ref={ReactDOM.Ref.domRef(inputRef)}
            className="w-full rounded-md text-gray-200 leading-tight focus:outline-none py-2 px-2 border-0 text-white"
            style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}
            id="search"
            spellCheck=false
            type_="text"
            placeholder="Search for actions"
            onKeyDown={event => {
              let key = event->ReactEvent.Keyboard.key
              switch key {
              | "Escape" =>
                let target = ReactEvent.Keyboard.target(event)
                target["value"] = ""
                let () = target["blur"]()
                setState(_oldState => {search: None, results: actions})
              | _ => ()
              }
            }}
            onChange={event => {
              let query = ReactEvent.Form.target(event)["value"]
              let search = switch query {
              | "" => None
              | other => Some(other)
              }

              let results = switch search {
              | None => actions
              | Some(term) => actions->searchActions(term)
              }

              setState(_oldState => {search: search, results: results})
            }}
          />
          <div className="flex items-center rounded-md inline ">
            <Comps.Select
              style={ReactDOMStyle.make(~width="3ch", ~backgroundImage="none", ())}
              value="never"
              onChange={event => {
                let kind = switch ReactEvent.Form.target(event)["value"] {
                | "query" => Some(#query)
                | "mutation" => Some(#mutation)
                | "subscription" => Some(#subscription)
                | "compute" => Some(#compute)
                | _ => None
                }

                kind->Belt.Option.forEach(kind => onCreate(kind))
              }}>
              <option value="+"> {"+"->React.string} </option>
              <option value="query"> {"+ New Query Action"->React.string} </option>
              <option value="mutation"> {"+ New Mutation Action"->React.string} </option>
              <option value="subscription"> {"+ New Subscription Action"->React.string} </option>
              <option value="compute"> {"+ New Compute Action"->React.string} </option>
            </Comps.Select>

            // <button className="p-2 hover:bg-blue-200 rounded-md" >
            //   {"+"->React.string}
            // </button>
          </div>
        </div>
        <div className="py-3 text-sm h-full overflow-y-scroll">
          {switch state.search {
          | None => actions
          | Some(_) => state.results
          }
          ->Belt.Array.copy
          ->Js.Array2.sortInPlaceWith((a, b) =>
            String.compare(
              a.name->Js.String2.toLocaleLowerCase,
              b.name->Js.String2.toLocaleLowerCase,
            )
          )
          ->Belt.Array.map((
            action: ActionSearchQuery_graphql.Types.response_oneGraph_studio_actions,
          ) => {
            <Action
              fragmentRefs={action.fragmentRefs}
              onInspect
              onAdd={action => {
                onAdd(action)
                inputRef.current
                ->Js.Nullable.toOption
                ->Belt.Option.forEach(dom => {
                  Obj.magic(dom)["value"] = ""
                  setState(oldState => {...oldState, search: None})
                })
              }}
            />
          })
          ->array}
        </div>
      </div>
    </div>
  </div>
}
