module Fragment = %relay(`
  fragment ActionForm_oneGraphStudioChainAction on OneGraphStudioChainAction {
    id
    name
    actionVariables: variables {
      id
      name
      graphqlType
    }
  }
`)

@react.component
let make = (~schema, ~actionRef, ~onExecuteAction) => {
  let action = Fragment.use(actionRef)

  open React
  let (formVariables, setFormVariables) = useState(() => Js.Dict.empty())
  let (currentAuthToken, setCurrentAuthToken) = useState(() => None)
  let connectionDrag = useContext(ConnectionContext.context)

  let inputs = action.actionVariables->Belt.Array.map(({name, graphqlType}) => {
    let def: GraphQLJs.variableDefinition = {
      variable: {
        name: {
          value: name,
          kind: "Name",
          loc: None,
        },
      },
      typ: graphqlType->GraphQLJs.parseType->Obj.magic,
    }

    GraphQLForm.formInput(
      schema,
      def,
      setFormVariables,
      GraphQLForm.formInputOptions(
        ~labelClassname="text-underline pl-2 m-2 mt-0 mb-0 font-thin text-sm font-mono",
        ~defaultValue=?None,
        ~onMouseUp={
          event => {
            let element = ReactEvent.Mouse.target(event)->Obj.magic
            let clientX = event->ReactEvent.Mouse.clientX
            let clientY = event->ReactEvent.Mouse.clientY
            let mouseClientPosition = (clientX, clientY)
            switch connectionDrag.value {
            | ConnectionContext.StartedSource({sourceActionId, sourceDom}) =>
              let newConnectionDrag = ConnectionContext.Completed({
                sourceDom: sourceDom,
                sourceActionId: sourceActionId,
                target: Input({inputDom: element}),
                windowPosition: mouseClientPosition,
              })

              connectionDrag.onPotentialVariableSourceConnect(~connectionDrag=newConnectionDrag)
            | _ => ()
            }
          }
        },
        (),
      ),
    )
  })

  let form =
    <form
      className={switch connectionDrag.value {
      | StartedSource(_) => "drag-enabled"
      | _ => ""
      } ++ " flex flex-col"}
      onSubmit={event => {
        event->ReactEvent.Form.preventDefault
        event->ReactEvent.Form.stopPropagation
        onExecuteAction(~actionId=action.id, ~variables=formVariables, ~authToken=currentAuthToken)
        ()
      }}>
      {inputs->Belt.Array.length > 0 ? {inputs->React.array} : React.null}
      <Comps.Select
        className="w-full select-button comp-select my-4 mx-2"
        onChange={event => {
          let value = ReactEvent.Form.target(event)["value"]
          let token = switch value {
          | "TEMP" => None
          | other => Some(other)
          }

          setCurrentAuthToken(_ => token)
        }}>
        <option value="TEMP"> {"Use current scratchpad auth"->string} </option>
        // {authTokens
        // ->Belt.Array.map(token => {
        //   <option value={token.accessToken}> {token.displayedToken->string} </option>
        // })
        // ->array}
      </Comps.Select>
      <Comps.Button className="w-full" type_="submit"> {"Execute"->React.string} </Comps.Button>
    </form>

  <> {form} <Comps.Pre> {formVariables->Obj.magic->Debug.JSON.stringify->string} </Comps.Pre> </>
}
