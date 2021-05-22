module OneGraphAppPackageChainVariableFragment = %relay(`
  fragment ComputedVariableInspector_oneGraphAppPackageChainActionVariable on OneGraphStudioChainActionVariable {
    id
  }
`)

@react.component
let make = (~variableRef) => {
  let variable = OneGraphAppPackageChainVariableFragment.use(variableRef)

  //   let setArgDep = makeNewArgDep => {
  //     onArgDepUpdated(makeNewArgDep(argDep))
  //   }

  open React
  <div>
    <form>
      {variable.id->string}
      // <label className="m-0">
      //   <div className="flex rounded-md shadow-sm">
      //     <span
      //       className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
      //       {"fromRequests:"->string}
      //     </span>
      //     <select
      //       className="block w-full text-gray-500 px-3 border border-gray-300 bg-white border-l-0 rounded-md shadow-sm focus:outline-none focus:ring-blue-300 focus:border-blue-300 sm:text-sm rounded-l-none"
      //       value={""}
      //       onChange={event => {
      //         let targetReqId = ReactEvent.Form.target(event)["value"]
      //         let alreadyDependent =
      //           argDep.fromRequestIds->Belt.Array.some(reqId => reqId == targetReqId)
      //         let newFromRequestIds = switch alreadyDependent {
      //         | false => argDep.fromRequestIds->Belt.Array.concat([targetReqId])
      //         | true => argDep.fromRequestIds->Belt.Array.keep(reqId => reqId != targetReqId)
      //         }
      //         setArgDep(oldArgDep => {...oldArgDep, fromRequestIds: newFromRequestIds})
      //       }}>
      //       <option key="" value={""}> {""->string} </option>
      //       {otherRequests
      //       ->Belt.Array.map(req =>
      //         <option key={req.id} value={req.id}>
      //           {((argDependentOnOtherReq(req) ? "v " : "") ++ req.id)->string}
      //         </option>
      //       )
      //       ->array}
      //     </select>
      //   </div>
      // </label>
      // <label className="m-0">
      //   <div className="flex rounded-md shadow-sm">
      //     <span
      //       className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
      //       {"functionFromScript:"->string}
      //     </span>
      //     <select
      //       className="block w-full px-3 text-gray-500 border border-gray-300 bg-white border-l-0 rounded-md shadow-sm focus:outline-none focus:ring-blue-300 focus:border-blue-300 sm:text-sm rounded-l-none"
      //       value={argDep.functionFromScript}
      //       onChange={event => {
      //         let functionFromScript = ReactEvent.Form.target(event)["value"]
      //         switch functionFromScript {
      //         | "NEW_FUNCTION" =>
      //           switch Debug.prompt("Function name: ") {
      //           | None => ()
      //           | Some(functionName) => onFunctionCreated(request)
      //           }
      //         | _ =>
      //           setArgDep(oldArgDep => {...oldArgDep, functionFromScript: functionFromScript})
      //         }
      //       }}>
      //       <option value=""> {""->string} </option>
      //       {scriptFunctions
      //       ->Belt.Array.map(functionName => {
      //         <option value={functionName}> {functionName->string} </option>
      //       })
      //       ->array}
      //       <option value="NEW_FUNCTION"> {"[Create new function]"->string} </option>
      //     </select>
      //   </div>
      // </label>
      // <label className="m-0">
      //   <div className="flex rounded-md shadow-sm">
      //     <span
      //       className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500 text-sm">
      //       {"Value Preview:"->string}
      //     </span>
      //   </div>
      // </label>
    </form>
  </div>
}
