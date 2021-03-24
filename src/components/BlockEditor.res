module GraphiQLExplorer = {
  @module("graphiql-explorer") @react.component
  external make: (
    ~schema: GraphQLJs.schema,
    ~explorerIsOpen: bool,
    ~query: string,
    ~width: string=?,
    ~height: string=?,
    ~onEdit: string => unit=?,
  ) => React.element = "default"
}

@react.component
let make = (~schema: GraphQLJs.schema, ~block as initialBlock: Card.block, ~onClose, ~onSave) => {
  let (block, setBlock) = React.useState(() => initialBlock)

  React.useEffect1(() => {
    setBlock(_ => initialBlock)
    None
  }, [initialBlock.body])

  let updateBlock = newOperationDoc => {
    let opDoc = newOperationDoc->GraphQLJs.parse
    let title =
      opDoc->GraphQLJs.operationNames->Belt.Array.get(0)->Belt.Option.getWithDefault("Untitled")

    setBlock(oldBlock => {...oldBlock, body: newOperationDoc, title: title})
  }

  let explorer = switch block.kind {
  | Compute => React.null
  | _ =>
    <div className="graphiql-container w-full">
      <GraphiQLExplorer
        schema
        width="100%"
        height="100%"
        query={block.body}
        explorerIsOpen=true
        onEdit={updateBlock}
      />
    </div>
  }

  let editor =
    <BsReactMonaco.Editor
      height="100%"
      className="flex-grow h-full"
      theme="vs-dark"
      language="graphql"
      value={block.body}
      options={
        "minimap": {"enabled": false},
      }
      onChange={(newOperationDoc, _) => updateBlock(newOperationDoc)}
    />
  open React
  <div className="flex w-full flex-col">
    <div className="flex flex-grow flex-row h-full"> {explorer} {editor} </div>
    <div className="w-full ml-auto flex">
      <Comps.Button
      // className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded flex-grow"
        className="flex-grow" onClick={_ => onSave(~initial=block, ~modified=block)}>
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
