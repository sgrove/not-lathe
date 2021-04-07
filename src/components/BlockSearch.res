type state = {
  search: option<string>,
  results: array<Card.block>,
}

@val external alert: string => unit = "alert"

@react.component
let make = (
  ~onAdd: Card.block => unit,
  ~onInspect: Card.block => unit,
  ~blocks: array<Card.block>,
  ~onCreate,
) => {
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
    results: blocks->Belt.SortArray.stableSortBy((a, b) =>
      String.compare(a.title->Js.String2.toLocaleLowerCase, b.title->Js.String2.toLocaleLowerCase)
    ),
  })

  let searchBlocks = (blocks: array<Card.block>, term) =>
    blocks
    ->Belt.Array.keep(block => {
      let titleMatch =
        block.title
        ->Js.String2.match_(term->Js.Re.fromStringWithFlags(~flags="ig"))
        ->Belt.Option.isSome

      let servicesMatch =
        block.services->Belt.Array.some(service =>
          service
          ->Js.String2.match_(term->Js.Re.fromStringWithFlags(~flags="ig"))
          ->Belt.Option.isSome
        )

      titleMatch || servicesMatch
    })
    ->Js.Array2.sortInPlaceWith((a, b) =>
      String.compare(a.title->Js.String2.toLocaleLowerCase, b.title->Js.String2.toLocaleLowerCase)
    )

  useEffect1(() => {
    switch state.search {
    | None => ()
    | Some(term) =>
      let results = blocks->searchBlocks(term)
      setState(oldState => {...oldState, results: results})
    }
    None
  }, [blocks->Belt.Array.length])

  <div
    className="flex w-full m-0 h-full block select-none"
    style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-9"], ())}>
    <div className="w-full max-h-full">
      <Comps.Header> {"Block Library"->React.string} </Comps.Header>
      <div
        className="rounded-lg px-3 py-2 overflow-y-hidden"
        style={ReactDOMStyle.make(~height="calc(100% - 40px)", ())}>
        <div
          className="flex items-center  rounded-md inline-block"
          style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}>
          <div className="pl-2"> <Icons.Search color={Comps.colors["gray-4"]} /> </div>
          <input
            ref={ReactDOM.Ref.domRef(inputRef)}
            className="w-full rounded-md text-gray-200 leading-tight focus:outline-none py-2 px-2 border-0 text-white"
            style={ReactDOMStyle.make(~backgroundColor=Comps.colors["gray-7"], ())}
            id="search"
            spellCheck=false
            type_="text"
            placeholder="Search for blocks"
            onKeyDown={event => {
              let key = event->ReactEvent.Keyboard.key
              switch key {
              | "Escape" =>
                let target = ReactEvent.Keyboard.target(event)
                target["value"] = ""
                let () = target["blur"]()
                setState(_oldState => {search: None, results: blocks})
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
              | None => blocks
              | Some(term) => blocks->searchBlocks(term)
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
              <option value="query"> {"+ New Query Block"->React.string} </option>
              <option value="mutation"> {"+ New Mutation Block"->React.string} </option>
              <option value="subscription"> {"+ New Subscription Block"->React.string} </option>
              <option value="compute"> {"+ New Compute Block"->React.string} </option>
            </Comps.Select>

            // <button className="p-2 hover:bg-blue-200 rounded-md" >
            //   {"+"->React.string}
            // </button>
          </div>
        </div>
        <div className="py-3 text-sm h-full overflow-y-scroll">
          {switch state.search {
          | None => blocks
          | Some(_) => state.results
          }
          ->Belt.Array.copy
          ->Js.Array2.sortInPlaceWith((a, b) =>
            String.compare(
              a.title->Js.String2.toLocaleLowerCase,
              b.title->Js.String2.toLocaleLowerCase,
            )
          )
          ->Belt.Array.map((block: Card.block) => {
            <div
              key={block.title}
              className="block-search-item flex justify-start cursor-grab text-gray-700 items-center hover:text-blue-400 rounded-md px-2 my-2"
              draggable=true
              onDragStart={event => {
                let dataTransfer = Obj.magic(event)["dataTransfer"]
                dataTransfer["effectAllowed"] = "copyLink"
                dataTransfer["setData"]("text", block.id->Uuid.toString)
              }}
              onDoubleClick={_ => {
                onAdd(block)
                inputRef.current
                ->Js.Nullable.toOption
                ->Belt.Option.forEach(dom => {
                  Obj.magic(dom)["value"] = ""
                  setState(oldState => {...oldState, search: None})
                })
              }}
              onClick={_ => onInspect(block)}>
              <div
                style={
                  let color = switch block.kind {
                  | Query => "1BBE83"
                  | Mutation => "B20D5D"
                  | Subscription => "F2C94C"
                  | Fragment => "F2C94C"
                  | Compute => Comps.colors["gray-10"]
                  }

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
                {block.title->string}
              </div>
              <div
                style={ReactDOMStyle.make(~minWidth="40px", ())} className="px-2 rounded-r-md py-2">
                {block.services
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
          })
          ->array}
        </div>
      </div>
    </div>
  </div>
}
