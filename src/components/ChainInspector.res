module Fragment = %relay(`
    fragment ChainInspector_packageChain on OneGraphAppPackageChain {
      id
      actions {
        id
        name
        graphqlOperationKind
        ...ActionInspector_oneGraphStudioChainAction
      }
      ...InspectorOverview_oneGraphAppPackageChain
    }
`)

@react.component
let make = (
  ~chainExecutionResults: option<Js.Json.t>,
  ~onLogin: string => unit,
  ~onInspectAction: (~actionId: string) => unit,
  ~oneGraphAuth,
  ~onClose,
  ~nothingRef as fragmentRefs,
) => {
  let chain = Fragment.use(fragmentRefs)

  open React

  // let webhookUrl = Compiler.Exports.webhookUrlForAppId(~appId=oneGraphAuth->OneGraphAuth.appId)
  // let compiledOperation = chain->Chain.compileOperationDoc(~schema, ~webhookUrl)

  let missingAuthServices =
    chainExecutionResults
    ->Belt.Option.map(ChainResultsHelpers.findMissingAuthServicesFromChainResult)
    ->Belt.Option.getWithDefault([])

  // let authButtons = missingAuthServices->Belt.Array.map(service => {
  //   <Comps.Button
  //     key={service}
  //     onClick={_ => {
  //       onLogin(service)
  //     }}>
  //     {("Log into " ++ service)->React.string}
  //   </Comps.Button>
  // })

  // let targetChain = compiledOperation.chains->Belt.Array.get(0)

  let (formVariables, setFormVariables) = React.useState(() => Js.Dict.empty())
  let (openedTab, setOpenedTab) = React.useState(() => #chat)
  let (rawJsonVariables, setRawJsonVariables) = React.useState(() => "")

  let isSubscription =
    chain.actions->Belt.Array.some(request => request.graphqlOperationKind == #SUBSCRIPTION)

  let isChainViable = chain.actions->Belt.Array.length > 0

  let (currentAuthToken, setCurrentAuthToken) = useState(() => None)

  let inspectorTab =
    <>
      <InspectorOverview
        fragmentRefs={chain.fragmentRefs} onInspectAction onDeleteAction={_ => ()}
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
      <Comps.Button onClick={_ => {onClose()}}> {"Exit"->string} </Comps.Button>
      <Comps.CollapsableSection defaultOpen=false title={"Internal Debug info"->React.string}>
        <Comps.Pre selectAll=true> {chain->Debug.Relay.stringify->React.string} </Comps.Pre>
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
          setOpenedTab(_ => #general)
        }}
        className={"flex justify-center flex-grow cursor-pointer p-1 outline-none " ++ {
          openedTab == #general ? " inspector-tab-active" : " inspector-tab-inactive"
        }}>
        <Icons.Link
          className=""
          width="24px"
          height="24px"
          color={openedTab == #general ? Comps.colors["blue-1"] : Comps.colors["gray-6"]}
        />
        <span className="mx-2"> {"Chain"->React.string} </span>
      </button>
      <button
        onClick={_ => {
          setOpenedTab(_ => #chat)
        }}
        className={"flex justify-center flex-grow cursor-pointer p-1 rounded-sm outline-none " ++ {
          openedTab == #chat ? " inspector-tab-active" : " inspector-tab-inactive"
        }}>
        <Icons.Chats
          width="24px"
          height="24px"
          color={openedTab == #chat ? Comps.colors["blue-1"] : Comps.colors["gray-6"]}
        />
        <span className="mx-2"> {"Chat"->React.string} </span>
      </button>
    </div>
    {switch openedTab {
    | #general => inspectorTab
    | #chat => <ChannelChat channelId={chain.id} />
    }}
    <Comps.Pre> {"tst"->string} </Comps.Pre>
  </>
}
