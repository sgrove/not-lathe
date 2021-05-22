module OneGraphStudioChainActionFragment = %relay(`
  fragment ActionInspector_oneGraphStudioChainAction on OneGraphStudioChainAction {
    id
    name
    description
    upstreamActionIds
    graphQLOperation
    actionVariables: variables {
      ...VariableInspector_oneGraphStudioChainActionVariable
    }
  }
`)

@react.component
let make = (
  ~actionRef,
  ~schema,
  ~actionNameIdPairs: array<(string, string)>,
  ~onDeleteEdge,
  ~onInspectAction: (~actionId: string) => unit,
  ~onInspectActionCode: (~actionId: string) => unit,
) => {
  let action = OneGraphStudioChainActionFragment.use(actionRef)

  // Temp data
  let definition = GraphQLJs.parse(action.graphQLOperation).definitions[0]
  let chainFragmentsDoc = ""
  let definitionResultData = Js.Dict.empty()

  open React

  let connectionDrag = useContext(ConnectionContext.context)

  let (openedTabs, setOpenedTabs) = useState(() => Belt.Set.String.empty)
  let (mockedEvalResults, setMockedEvalResults) = useState(() => None)
  let (formVariables, setFormVariables) = React.useState(() => Js.Dict.empty())
  let (potentialConnection, setPotentialConnection) = React.useState(() => Belt.Set.String.empty)
  let domRef = React.useRef(Js.Nullable.null)
  let (currentAuthToken, setCurrentAuthToken) = useState(() => None)
  let (openedTab, setOpenedTab) = React.useState(() => #inspector)

  let upstreamActions = action.upstreamActionIds->Belt.Array.keepMap(upstreamActionId => {
    let upstreamAction = actionNameIdPairs->Belt.Array.getBy(((id, _)) => id == upstreamActionId)

    upstreamAction->Belt.Option.map(((actionId, actionName)) => {
      <article key={actionId ++ upstreamActionId} className="m-2">
        <div className={"flex justify-between items-center cursor-pointer p-1 rounded-sm"}>
          <span
            className="font-semibold text-sm font-mono pl-2"
            style={ReactDOMStyle.make(~color=Comps.colors["green-4"], ())}
            onClick={_ => onInspectAction(~actionId)}>
            {actionName->string}
          </span>
          <Comps.Button
            className="og-secodary-button"
            onClick={event => {
              event->ReactEvent.Mouse.stopPropagation
              event->ReactEvent.Mouse.preventDefault
              onDeleteEdge(~targetRequestId=actionId, ~dependencyId=upstreamActionId)
            }}>
            <Icons.Trash color={Comps.colors["gray-4"]} className="inline mr-2" />
            {"Remove Dependency"->string}
          </Comps.Button>
        </div>
      </article>
    })
  })

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
        <span className="mx-2"> {"Action"->React.string} </span>
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
        <span className="mx-2"> {"Try Action"->React.string} </span>
      </button>
    </div>
    {switch openedTab {
    | #inspector => <>
        {action.actionVariables->Belt.Array.length > 0
          ? <Comps.CollapsableSection title={"Variable Settings"->React.string}>
              {action.actionVariables
              ->Belt.Array.map(variable => {
                <VariableInspector variableRef={variable.fragmentRefs} />
              })
              ->array}
            </Comps.CollapsableSection>
          : React.null}
        {action.actionVariables->Belt.Array.length > 0
          ? <Comps.CollapsableSection
              title={<>
                {"Computed Variable Preview"->string}
                <button
                  onClick={event => {
                    event->ReactEvent.Mouse.preventDefault
                    event->ReactEvent.Mouse.stopPropagation
                    ()
                    onInspectActionCode(~actionId=action.id)
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
            </Comps.CollapsableSection>
          : React.null}
        {action.upstreamActionIds->Belt.Array.length > 0
          ? <Comps.CollapsableSection title={"Upstream Actions"->React.string}>
              {upstreamActions->array}
            </Comps.CollapsableSection>
          : React.null}
        <Comps.CollapsableSection title={"GraphQL Structure"->React.string}>
          <div
            className="my-2 mx-4 p-2 rounded-sm text-gray-200 overflow-scroll"
            style={ReactDOMStyle.make(
              ~backgroundColor=Comps.colors["gray-8"],
              ~maxHeight="150px",
              (),
            )}>
            <GraphQLPreview
              requestId=action.id
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
        </Comps.CollapsableSection>
      </>
    | #form =>
      <Comps.CollapsableSection title={"Execute block"->string}>
        {null}
        <Comps.Pre>
          {Some({"cachedResult": "nothing here"})
          ->Belt.Option.mapWithDefault("Nothing", json =>
            Obj.magic(json)->Js.Json.stringifyWithSpace(2)
          )
          ->string}
        </Comps.Pre>
      </Comps.CollapsableSection>
    }}
  </div>
}
