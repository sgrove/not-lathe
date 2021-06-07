module Fragment = %relay(`
  fragment ActionGraphQLEditor_chainAction on OneGraphStudioChainAction {
    id
    name
    description
    graphqlOperation
    services
  }
`)

module GraphiQLExplorer = {
  @module("@sgrove/graphiql-explorer") @react.component
  external make: (
    ~schema: GraphQLJs.schema,
    ~explorerIsOpen: bool,
    ~query: string,
    ~width: string=?,
    ~height: string=?,
    ~onEdit: string => unit=?,
    ~availableFragments: array<GraphQLJs.graphqlOperationDefinition>=?,
  ) => React.element = "default"
}

type actionKind = [#COMPUTE | #MUTATION | #QUERY | #SUBSCRIPTION | #FRAGMENT]

type editableAction = {
  id: string,
  name: string,
  graphqlOperation: string,
  kind: actionKind,
}

let makeBlankAction = (kind): editableAction => {
  let body = switch kind {
  | #QUERY => "query Untitled { __typename }"
  | #FRAGMENT => "fragment UntitledFragment on Query { __typename }"
  | #MUTATION => "mutation Untitled { __typename }"
  | #SUBSCRIPTION => "subscription Untitled { __typename }"
  | #COMPUTE => `# Fields on ComputeType will turn into variables for you to compute
# based on other blocks or user input
type ComputeType {
  name: String!
}`
  }

  {
    name: "Untitled",
    id: Uuid.v4()->Uuid.toString,
    graphqlOperation: body,
    kind: kind,
  }
}

@react.component
let make = (~schema: GraphQLJs.schema, ~onClose, ~onSave, ~availableFragments, ~actionRef) => {
  let initialAction = Fragment.use(actionRef)

  let (action, setAction) = React.useState(() => {
    let block = makeBlankAction(#QUERY)
    let final = {
      ...block,
      id: initialAction.id,
      graphqlOperation: initialAction.graphqlOperation,
      name: initialAction.name,
    }

    final
  })

  React.useEffect2(() => {
    setAction(_ => {
      let block = makeBlankAction(#QUERY)
      let final = {
        ...block,
        id: initialAction.id,
        graphqlOperation: initialAction.graphqlOperation,
        name: initialAction.name,
      }
      Js.log4("Action Change detected: ", block, action, final)
      final
    })
    None
  }, (initialAction.id, initialAction.graphqlOperation))

  let updateBlock = newOperationDoc => {
    let opDoc = newOperationDoc->GraphQLJs.parse
    let title =
      opDoc->GraphQLJs.operationNames->Belt.Array.get(0)->Belt.Option.getWithDefault("Untitled")

    setAction(oldBlock => {...oldBlock, graphqlOperation: newOperationDoc, name: title})
  }

  let explorer =
    <div className="graphiql-container w-full">
      <GraphiQLExplorer
        schema
        width="100%"
        height="100%"
        query={action.graphqlOperation}
        explorerIsOpen=true
        onEdit={updateBlock}
        availableFragments
      />
    </div>

  let editor =
    <BsReactMonaco.Editor
      height="100%"
      className="flex-grow h-full"
      theme="vs-dark"
      language="graphql"
      value={action.graphqlOperation}
      options={
        "minimap": {"enabled": false},
      }
      onChange={(newOperationDoc, _) => updateBlock(newOperationDoc)}
    />
  open React

  ReactHotKeysHook.useHotkeys(
    ~keys="esc",
    ~callback=(event, _handler) => {
      event->ReactEvent.Keyboard.preventDefault
      event->ReactEvent.Keyboard.stopPropagation
      onClose()
    },
    ~options=ReactHotKeysHook.options(),
    ~deps=None,
  )

  <div className="flex w-full flex-col">
    <div className="flex flex-grow flex-row h-full"> {explorer} {editor} </div>
    <div className="w-full ml-auto flex">
      <Comps.Button
      // className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded flex-grow"
        className="flex-grow" onClick={_ => onSave(~initial=action, ~modified=action)}>
        {j`Save`->string}
      </Comps.Button>
      <Comps.Button
      // className="bg-transparent hover:bg-gray-500 text-blue-700 font-semibold hover:text-white py-2 px-4 border border-blue-500 hover:border-transparent rounded flex-grow"
        className="flex-grow" onClick={_ => onClose()}>
        {j`Cancel`->string}
      </Comps.Button>
    </div>
  </div>
}

module Creator = {
  @react.component
  let make = (~schema: GraphQLJs.schema, ~onClose, ~onSave, ~availableFragments) => {
    let (action, setAction) = React.useState(() => makeBlankAction(#QUERY))

    let updateBlock = newOperationDoc => {
      let opDoc = newOperationDoc->GraphQLJs.parse
      let title =
        opDoc->GraphQLJs.operationNames->Belt.Array.get(0)->Belt.Option.getWithDefault("Untitled")

      setAction(oldBlock => {...oldBlock, graphqlOperation: newOperationDoc, name: title})
    }

    let explorer =
      <div className="graphiql-container w-full">
        <GraphiQLExplorer
          schema
          width="100%"
          height="100%"
          query={action.graphqlOperation}
          explorerIsOpen=true
          onEdit={updateBlock}
          availableFragments
        />
      </div>

    let editor =
      <BsReactMonaco.Editor
        height="100%"
        className="flex-grow h-full"
        theme="vs-dark"
        language="graphql"
        value={action.graphqlOperation}
        options={
          "minimap": {"enabled": false},
        }
        onChange={(newOperationDoc, _) => updateBlock(newOperationDoc)}
      />
    open React

    ReactHotKeysHook.useHotkeys(
      ~keys="esc",
      ~callback=(event, _handler) => {
        event->ReactEvent.Keyboard.preventDefault
        event->ReactEvent.Keyboard.stopPropagation
        onClose()
      },
      ~options=ReactHotKeysHook.options(),
      ~deps=None,
    )

    <div className="flex w-full flex-col">
      <div className="flex flex-grow flex-row h-full"> {explorer} {editor} </div>
      <div className="w-full ml-auto flex">
        <Comps.Button
        // className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded flex-grow"
          className="flex-grow" onClick={_ => onSave(~initial=action, ~modified=action)}>
          {j`Save`->string}
        </Comps.Button>
        <Comps.Button
        // className="bg-transparent hover:bg-gray-500 text-blue-700 font-semibold hover:text-white py-2 px-4 border border-blue-500 hover:border-transparent rounded flex-grow"
          className="flex-grow" onClick={_ => onClose()}>
          {j`Cancel`->string}
        </Comps.Button>
      </div>
    </div>
  }
}
