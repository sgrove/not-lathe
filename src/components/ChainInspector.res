module Fragment = %relay(`
    fragment ChainInspector_packageChain on OneGraphAppPackageChain {
      id
      actions {
        id
        name
        graphQLOperationKind
        ...ActionInspector_oneGraphStudioChainAction
      }
      ...InspectorOverview_oneGraphAppPackageChain
    }
`)

@react.component
let make = (
  ~chainExecutionResults: option<Js.Json.t>,
  ~onPotentialVariableSourceConnect,
  ~onLogin: string => unit,
  ~onInspectAction: (~actionId: string) => unit,
  ~oneGraphAuth,
  ~onClose,
  ~nothingRef as fragmentRefs,
) => {
  let chainRef = Fragment.use(fragmentRefs)

  open React

  let connectionDrag = useContext(ConnectionContext.context)
  let (potentialConnection, setPotentialConnection) = React.useState(() => Belt.Set.String.empty)

  let webhookUrl = Compiler.Exports.webhookUrlForAppId(~appId=oneGraphAuth->OneGraphAuth.appId)
  // let compiledOperation = chain->Chain.compileOperationDoc(~schema, ~webhookUrl)

  let missingAuthServices =
    chainExecutionResults
    ->Belt.Option.map(ChainResultsHelpers.findMissingAuthServicesFromChainResult)
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

  // let targetChain = compiledOperation.chains->Belt.Array.get(0)

  let (formVariables, setFormVariables) = React.useState(() => Js.Dict.empty())
  let (openedTab, setOpenedTab) = React.useState(() => #inspector)
  let (rawJsonVariables, setRawJsonVariables) = React.useState(() => "")

  let isSubscription =
    chainRef.actions->Belt.Array.some(request => request.graphQLOperationKind == #SUBSCRIPTION)

  let isChainViable = chainRef.actions->Belt.Array.length > 0

  let (currentAuthToken, setCurrentAuthToken) = useState(() => None)

  let inspectorTab =
    <>
      <InspectorOverview
        fragmentRefs={chainRef.fragmentRefs}
        onPotentialVariableSourceConnect
        onInspectAction
        onDeleteAction={_ => ()}
      />
      <br />
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
      // {initialChain == chainRef
      //   ? null
      //   : <Comps.Button onClick={_ => {onSaveChain(chain)}}>
      //       {"Save Changes"->string}
      //     </Comps.Button>}
      <Comps.Button onClick={_ => {onClose()}}> {"Cancel changes and exit"->string} </Comps.Button>
      <Comps.CollapsableSection defaultOpen=false title={"Internal Debug info"->React.string}>
        <Comps.Pre selectAll=true> {chainRef->Debug.Relay.stringify->React.string} </Comps.Pre>
      </Comps.CollapsableSection>
      // <Comps.CollapsableSection defaultOpen=false title={"Compiled Executable Chain"->React.string}>
      //   <Comps.Pre selectAll=true>
      //     {
      //       let compiled = chain->Compiler.transformChain(~schema)
      //       // let script = transformed.script

      //       // let script = Obj.magic(transformed)["script"]

      //       // script->Js.Json.string->Js.Json.stringifyWithSpace(2)->React.string
      //       compiled->Obj.magic->Js.Json.stringifyWithSpace(2)->React.string
      //     }
      //   </Comps.Pre>
      // </Comps.CollapsableSection>
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
    inspectorTab
  </>
}
