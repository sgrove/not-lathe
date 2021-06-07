module Fragment = %relay(`
  fragment ActionInspector_oneGraphStudioChainAction on OneGraphStudioChainAction {
    id
    name
    description
    upstreamActionIds
    graphqlOperation
    actionVariables: variables {
      id
      name
      ...VariableInspector_oneGraphStudioChainActionVariable
    }
    ...ActionForm_oneGraphStudioChainAction
  }
`)

module RemoveActionDependencyIds = %relay(`
  mutation ActionInspector_RemoveActionDependencyIdsMutation(
    $input: OneGraphRemoveActionDependencyIdsInput!
  ) {
    oneGraph {
      removeActionDependencyIds(input: $input) {
        action {
          ...ActionInspector_oneGraphStudioChainAction
        }
      }
    }
  }
`)

let tsdef = (
  ~schema,
  request: ActionInspector_oneGraphStudioChainAction_graphql.Types.fragment,
) => {
  let ast = request.graphqlOperation->GraphQLJs.parse
  let definition = ast.definitions[0]

  let typeScriptType =
    schema->GraphQLJs.Mock.typeScriptForOperation(definition, ~fragmentDefinitions=Js.Dict.empty())

  j`"${request.name}": ${typeScriptType}`
}

@react.component
let make = (
  ~actionRef,
  ~schema,
  ~actionNameIdPairs: array<(string, string)>,
  ~onInspectAction: (~actionId: string) => unit,
  ~onInspectActionCode: (~actionId: string) => unit,
  ~onExecuteAction: (
    ~actionId: string,
    ~variables: Js.Dict.t<'c>,
    ~authToken: option<string>,
  ) => unit,
) => {
  let action = Fragment.use(actionRef)
  let (removeDependencyId, _isRemovingDependencyId) = RemoveActionDependencyIds.use()

  // Temp data
  let definition = GraphQLJs.parse(action.graphqlOperation).definitions[0]
  let chainFragmentsDoc = ""
  let definitionResultData = Js.Dict.empty()

  open React

  let (mockedEvalResults, setMockedEvalResults) = useState(() => None)
  let domRef = React.useRef(Js.Nullable.null)
  let (openedTab, setOpenedTab) = React.useState(() => #inspector)

  let upstreamActions = action.upstreamActionIds->Belt.Array.keepMap(upstreamActionId => {
    let upstreamAction = actionNameIdPairs->Belt.Array.getBy(((id, _)) => id == upstreamActionId)

    upstreamAction->Belt.Option.map(((_, upstreamActionName)) => {
      <article key={action.id ++ upstreamActionId} className="m-2">
        <div className={"flex justify-between items-center cursor-pointer p-1 rounded-sm"}>
          <span
            className="font-semibold text-sm font-mono pl-2"
            style={ReactDOMStyle.make(~color=Comps.colors["green-4"], ())}
            onClick={_ => onInspectAction(~actionId=upstreamActionId)}>
            {upstreamActionName->string}
          </span>
          <Comps.Button
            className="og-secodary-button"
            onClick={event => {
              event->ReactEvent.Mouse.stopPropagation
              event->ReactEvent.Mouse.preventDefault
              let _result: RescriptRelay.Disposable.t = removeDependencyId(
                ~variables={
                  input: {
                    actionId: action.id,
                    removeActionDependencyIds: [upstreamActionId],
                  },
                },
                (),
              )
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
              ->Belt.SortArray.stableSortBy((a, b) => String.compare(a.name, b.name))
              ->Belt.Array.map(variable => {
                <VariableInspector
                  key={variable.id} variableRef={variable.fragmentRefs} actionId={action.id}
                />
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
        <ActionForm schema={schema} actionRef={action.fragmentRefs} onExecuteAction />
        <Comps.Pre>
          {Some({"cachedResult": "nothing here"})
          ->Belt.Option.mapWithDefault("Nothing", json =>
            Obj.magic(json)->Js.Json.stringifyWithSpace(2)
          )
          ->string}
        </Comps.Pre>
      </Comps.CollapsableSection>
    }}
    <Comps.Pre> {action->tsdef(~schema)->string} </Comps.Pre>
  </div>
}
