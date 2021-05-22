module OneGraphAppPackageChainFragment = %relay(`
  fragment Inspector_oneGraphAppPackageChain on OneGraphAppPackageChain {
    id
    actions {
      id
      name
      graphQLOperationKind
    }
    ...Inspector_SubInspector_packageChain
    ...ChainInspector_packageChain
  }
`)

@deriving(abstract)
type formInputOptions = {
  @optional
  labelClassname: string,
  @optional
  inputClassName: string,
  @optional
  defaultValue: Js.Json.t,
  @optional
  onMouseUp: ReactEvent.Mouse.t => unit,
}

@module("../GraphQLForm.js")
external formInput: (
  GraphQLJs.schema,
  GraphQLJs.variableDefinition,
  'setFormVariablesFn,
  formInputOptions,
) => React.element = "formInput"

let forceablySetInputValue = (node, value) => {
  let helper = %raw(`function(node, value) {
  // only process the change on elements we know have a value setter in their constructor
const inputTypes =  [
    window.HTMLInputElement,
    window.HTMLSelectElement,
    window.HTMLTextAreaElement,
]

  if ( inputTypes.indexOf(node.__proto__.constructor) >-1 ) {

        const setValue = Object.getOwnPropertyDescriptor(node.__proto__, 'value').set;
        const event = new Event('input', { bubbles: true });

        setValue.call(node, value);
        node.dispatchEvent(event);

    }}`)

  helper(node, value)
}

type inspectable =
  | Nothing
  | Action(string)
  | RequestArgument({actionId: string, variableId: string})

type mockRequestValueVariable = {
  name: string,
  value: Js.Json.t,
}

let transformAndExecuteChain = (chain, ~schema, ~oneGraphAuth, ~variables) => {
  let webhookUrl = Compiler.Exports.webhookUrlForAppId(~appId=oneGraphAuth->OneGraphAuth.appId)

  let compiled = chain->Compiler.transformChain(~schema, ~webhookUrl)

  let targetChain = compiled.chains->Belt.Array.getUnsafe(0)

  let promise = OneGraphRe.fetchOneGraph(
    oneGraphAuth,
    compiled.operationDoc,
    Some(targetChain.operationName),
    variables,
  )

  promise
}

// let transformAndExecuteChainSubscription = (
//   chain,
//   ~schema,
//   ~subscriptionClient: OneGraphSubscriptionClient.t,
//   ~variables,
//   ~onData,
//   ~onError,
//   ~onClosed,
// ) => {
//   let webhookUrl = webhookUrlForAppId(~appId=oneGraphAuth->OneGraphAuth.appId)
//   let compiled = chain->Compiler.transformChain(~schema, ~appId)

//   let targetChain = compiled.chains->Belt.Array.getUnsafe(0)

//   let payload: OneGraphSubscriptionClient.operationOptions<'a, 'b> = {
//     query: compiled.operationDoc,
//     operationName: targetChain.operationName,
//     variables: variables,
//     context: None,
//   }

//   Js.log(targetChain.operationName)
//   Js.log(compiled.operationDoc)
//   Js.log(variables)

//   subscriptionClient
//   ->OneGraphSubscriptionClient.request(payload)
//   ->OneGraphSubscriptionClient.subscribe(~onData, ~onError, ~onClosed)
// }

module SubInspectorFragment = %relay(`
  fragment Inspector_SubInspector_packageChain on OneGraphAppPackageChain {
    id
    actions {
      id
      name
      graphQLOperationKind
      ...ActionInspector_oneGraphStudioChainAction
    }
  }
`)

module SubInspector = {
  @react.component
  let make = (
    ~inspected: inspectable,
    ~onReset: unit => unit,
    ~schema: GraphQLJs.schema,
    ~onInspectAction: (~actionId: string) => unit,
    ~onInspectActionCode: (~actionId: string) => unit,
    ~requestValueCache: RequestValueCache.t,
    ~onDeleteEdge,
    ~subInspectorRef as fragmentRefs,
  ) => {
    let subInspectorRef = SubInspectorFragment.use(fragmentRefs)
    open React
    ReactHotKeysHook.useHotkeys(
      ~keys="esc",
      ~callback=(event, _handler) => {
        event->ReactEvent.Keyboard.preventDefault
        event->ReactEvent.Keyboard.stopPropagation
        onReset()
      },
      ~options=ReactHotKeysHook.options(),
      ~deps=None,
    )

    <div
      className="w-full text-white border-l border-gray-800"
      style={ReactDOMStyle.make(
        ~backgroundColor="rgb(27,29,31)",
        ~height="calc(100vh - 56px)",
        ~boxShadow="-5px 0 5px rgba(150, 150, 150, 0.25)",
        (),
      )}>
      <nav className="flex flex-row py-1 px-2 mb-2 justify-between">
        <Comps.Header>
          {switch inspected {
          | Nothing => ""
          | Action(actionId) =>
            switch subInspectorRef.actions->Belt.Array.getBy(action => action.id == actionId) {
            | None => "Action"
            | Some(action) => "Action: " ++ action.name
            }
          | RequestArgument(_) => "Request Argument"
          }->string}
        </Comps.Header>
        <span className="text-white cursor-pointer" onClick={_ => onReset()}>
          {j`⨂`->React.string}
        </span>
      </nav>
      <div
        className="overflow-y-scroll"
        style={ReactDOMStyle.make(~height="calc(100vh - 56px - 56px)", ())}>
        {switch inspected {
        | Nothing => null
        | Action(actionId)
        | RequestArgument({actionId}) =>
          let _cachedResult = requestValueCache->RequestValueCache.get(~requestId=actionId)

          let action = subInspectorRef.actions->Belt.Array.getBy(action => action.id == actionId)
          let actionNameIdPairs =
            subInspectorRef.actions->Belt.Array.map(action => (action.id, action.name))

          action->Belt.Option.mapWithDefault(null, action =>
            <ActionInspector
              actionRef={action.fragmentRefs}
              schema
              onInspectAction
              actionNameIdPairs
              onDeleteEdge
              onInspectActionCode
            />
          )
        }}
      </div>
    </div>
  }
}

let springSteps = {
  "from": ReactDOMStyle.make(
    ~position="absolute",
    ~opacity="1",
    ~top="0px",
    ~left="0px",
    ~transform="translateX(100%)",
    ~width="100%",
    (),
  ),
  "enter": ReactDOMStyle.make(
    ~position="absolute",
    ~opacity="1",
    ~top="0px",
    ~left="0px",
    ~transform="translateX(0%)",
    (),
  ),
  "leave": ReactDOMStyle.make(
    ~position="absolute",
    ~opacity="1",
    ~top="0px",
    ~left="0px",
    ~transform="translateY(100%)",
    (),
  ),
}

@react.component
let make = (
  ~inspected: inspectable,
  ~onReset: unit => unit,
  ~schema: GraphQLJs.schema,
  ~chainExecutionResults: option<Js.Json.t>,
  ~onLogin: string => unit,
  ~onInspectActionCode: (~actionId: string) => unit,
  ~requestValueCache,
  ~onDeleteEdge,
  ~onInspectAction: (~actionId: string) => unit,
  ~oneGraphAuth,
  ~onClose,
  ~onPotentialVariableSourceConnect,
  ~fragmentRefs,
) => {
  let chainRef = OneGraphAppPackageChainFragment.use(fragmentRefs)

  open React
  let subInspectorRef = useRef(None)
  let transitions = ReactSpring.useTransition(
    switch inspected {
    | Nothing => false
    | _ => true
    },
    None,
    ReactSpring.lifeCycle(
      ~from=springSteps["from"],
      ~enter=springSteps["enter"],
      ~leave=springSteps["leave"],
      ~unique=true,
      ~ref=subInspectorRef,
      ~config=ReactSpring.config.stiff,
      (),
    ),
  )

  ReactSpring.useChain([subInspectorRef])

  ReactHotKeysHook.useHotkeys(
    ~keys="command+s",
    ~callback=(event, _handler) => {
      event->ReactEvent.Keyboard.preventDefault
      event->ReactEvent.Keyboard.stopPropagation
    },
    ~options=ReactHotKeysHook.options(),
    ~deps=None,
  )

  <div
    className=" text-white border-l border-gray-800"
    style={ReactDOMStyle.make(
      ~backgroundColor="rgb(27,29,31)",
      ~height="calc(100vh - 56px)",
      ~position="relative",
      (),
    )}>
    <nav className="flex flex-row py-1 px-2 mb-2 justify-between">
      <Comps.Header> {"Chain Inspector"->string} </Comps.Header>
    </nav>
    <div
      className="overflow-y-scroll"
      style={ReactDOMStyle.make(~height="calc(100vh - 56px - 56px)", ())}>
      <ChainInspector
        chainExecutionResults
        onLogin
        onInspectAction
        oneGraphAuth
        onClose
        onPotentialVariableSourceConnect
        nothingRef={chainRef.fragmentRefs}
      />
    </div>
    {switch inspected {
    | _ =>
      transitions
      ->Belt.Array.map(element => {
        open ReactSpring
        let props = element->propsGet
        let item = element->itemGet
        switch item {
        | false => null
        | true =>
          <ReactSpring.Animated style={props} key={element->keyGet}>
            <SubInspector
              subInspectorRef={chainRef.fragmentRefs}
              inspected
              onInspectAction
              onReset
              schema
              onInspectActionCode
              requestValueCache
              onDeleteEdge
            />
          </ReactSpring.Animated>
        }
      })
      ->array
    }}
  </div>
}
