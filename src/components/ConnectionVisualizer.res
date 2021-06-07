module Fragment = %relay(`
  fragment ConnectionVisualizer_chainActions on OneGraphAppPackageChain {
    id
    actions {
      id
      name
      upstreamActionIds
      actionVariables: variables {
        id
        name
        graphqlType
      }
    }
  }
`)

//  {switch state.connectionDragState {
//             | Empty => null
//             | StartedTarget({target: Variable(_), sourceDom}) =>
//               <DragConnectorLine)
//                 source=sourceDom
//                 invert={true}
//                 onDragEnd={() => {
//                   setState(oldState => {
//                     {...oldState, connectionDragState: Empty}
//                   })
//                 }}
//               />
//             | StartedSource({sourceDom}) =>
//               <DragConnectorLine
//                 source=sourceDom
//                 invert={false}
//                 onDragEnd={() => {
//                   setState(oldState => {
//                     {...oldState, connectionDragState: Empty}
//                   })
//                 }}
//               />
//             | StartedTarget({target: Input(_)}) =>
//               setState(oldState => {
//                 ...oldState,
//                 connectionDragState: Empty,
//               })
//               null
//             | _ => // TODO!
//               null
//             }}

type connectionIntent =
  | Clear
  | ActionToAction
  | ActionToVariable({
      variable: ConnectionVisualizer_chainActions_graphql.Types.fragment_actions_actionVariables,
    })

@react.component
let make = (~chainRef) => {
  let chain = Fragment.use(chainRef)
  open React
  let connectionDrag = useContext(ConnectionContext.context)
  let clearConnectionDrag = () => {
    Js.log2("Clearing connection drag, was ", connectionDrag.value)
    connectionDrag.onPotentialVariableSourceConnect(~connectionDrag=Empty)
  }
  switch connectionDrag.value {
  | Empty => null
  | CompletedPendingVariable({targetActionId, windowPosition: (x, y)} as dragInfo) =>
    let action = chain.actions->Belt.Array.getBy(action => action.id == targetActionId)

    switch action {
    | None =>
      clearConnectionDrag()
      null
    | Some(action) =>
      let variableDependencies = action.actionVariables->Belt.SortArray.stableSortBy((a, b) => {
        String.compare(a.name, b.name)
      })

      let onClick = (intent: connectionIntent) => {
        switch intent {
        | Clear =>
          connectionDrag.onPotentialVariableSourceConnect(~connectionDrag=ConnectionContext.Empty)
        | ActionToAction =>
          open ConnectionContext
          let newConnectionDrag = Completed({
            sourceActionId: dragInfo.sourceActionId,
            sourceDom: dragInfo.sourceDom,
            windowPosition: (x, y),
            target: Action({targetActionId: action.id}),
          })

          connectionDrag.onPotentialActionSourceConnect(~connectionDrag=newConnectionDrag)
        | ActionToVariable({variable}) =>
          let variableTarget: ConnectionContext.variableTarget = {
            actionId: targetActionId,
            variableId: variable.id,
          }

          let newConnectionDrag = ConnectionContext.Completed({
            sourceActionId: dragInfo.sourceActionId,
            sourceDom: dragInfo.sourceDom,
            windowPosition: (x, y),
            target: Variable(variableTarget),
          })

          connectionDrag.onPotentialVariableSourceConnect(~connectionDrag=newConnectionDrag)
        }
      }
      <PopUpPicker
        top=y
        left=x
        onClose={() => {
          onClick(Clear)
        }}>
        <div
          className="cursor-pointer graphql-structure-preview-entry"
          onClick={_ => onClick(ActionToAction)}>
          {"Connect source to target"->string}
        </div>
        <span style={ReactDOMStyle.make(~color=Comps.colors["gray-2"], ())}>
          {"Or, directly connect destination variable: "->string}
        </span>
        <ul>
          {variableDependencies
          ->Belt.Array.map(variableDependency => {
            <li
              className="cursor-pointer graphql-structure-preview-entry"
              onClick={_ => onClick(ActionToVariable({variable: variableDependency}))}
              key=variableDependency.name>
              {("$" ++ variableDependency.name)->string}
            </li>
          })
          ->array}
        </ul>
      </PopUpPicker>
    }
  //   | CompletedWithTypeMismatch({
  //       sourceRequest,
  //       variableTarget,
  //       windowPosition: (x, y),
  //       potentialFunctionMatches,
  //       dataPath,
  //       path,
  //       targetVariableType,
  //       sourceType,
  //     }) =>
  //     let onClick: option<string> => unit = name => {
  //       setState(oldState => {
  //         let targetVariableDependency = variableTarget.variableDependency

  //         let newRequests = oldState.chain.requests->Belt.Array.map(request => {
  //           switch variableTarget.targetRequest.id == request.id {
  //           | false => request
  //           | true =>
  //             let varDeps = request.variableDependencies->Belt.Array.map(varDep => {
  //               switch varDep.name == targetVariableDependency.name {
  //               | true =>
  //                 let dependency = Chain.ArgumentDependency({
  //                   name: targetVariableDependency.name,
  //                   ifMissing: #SKIP,
  //                   ifList: #FIRST,
  //                   fromRequestIds: request.dependencyRequestIds,
  //                   functionFromScript: "TBD",
  //                   maxRecur: None,
  //                 })

  //                 {...varDep, dependency: dependency}

  //               | false =>
  //                 let dependency = switch varDep.dependency {
  //                 | ArgumentDependency(argDep) =>
  //                   let newArgDep = {
  //                     ...argDep,
  //                     fromRequestIds: argDep.fromRequestIds
  //                     ->Belt.Array.concat([sourceRequest.id])
  //                     ->Utils.String.distinctStrings,
  //                   }

  //                   Chain.ArgumentDependency(newArgDep)
  //                 | other => other
  //                 }
  //                 let varDep = {...varDep, dependency: dependency}

  //                 varDep
  //               }
  //             })

  //             {
  //               ...request,
  //               variableDependencies: varDeps,
  //               dependencyRequestIds: request.dependencyRequestIds
  //               ->Belt.Array.concat([sourceRequest.id])
  //               ->Utils.String.distinctStrings,
  //             }
  //           }
  //         })

  //         let request = newRequests->Belt.Array.getBy(request => {
  //           variableTarget.targetRequest.id == request.id
  //         })

  //         let script = request->Belt.Option.mapWithDefault(oldState.chain.script, request => {
  //           let returnProperties = request.variableDependencies->Belt.Array.keepMap(varDep => {
  //             switch varDep.dependency {
  //             | ArgumentDependency(_) => Some((varDep.name, varDep.name))
  //             | _ => None
  //             }
  //           })

  //           Inspector.ensureRequestFunctionExists(
  //             ~returnProperties,
  //             ~script=oldState.chain.script,
  //             ~request,
  //             (),
  //           )
  //         })

  //         let parsed = try {
  //           Some(TypeScript.createSourceFile(~name="main.ts", ~source=script, ~target=99, true))
  //         } catch {
  //         | _ => None
  //         }

  //         let lineNumbers = request->Belt.Option.flatMap(request => {
  //           let names = request->Chain.requestScriptNames

  //           let target = parsed->Belt.Option.flatMap(parsed =>
  //             parsed
  //             ->TypeScript.findFnPos(names.functionName)
  //             ->Belt.Option.map(({start, firstStatementStart}) => {
  //               let {line} = parsed->TypeScript.getLineAndCharacterOfPosition(start)
  //               let firstStatementLine = firstStatementStart->Belt.Option.mapWithDefault(
  //                 line,
  //                 firstStatementStart => {
  //                   let {line} = parsed->TypeScript.getLineAndCharacterOfPosition(firstStatementStart)
  //                   line
  //                 },
  //               )

  //               (line, firstStatementLine)
  //             })
  //           )
  //           target
  //         })

  //         let re = Js.Re.fromStringWithFlags(~flags="g", "\\[.+\\]")
  //         let inputName = dataPath[dataPath->Js.Array2.length - 1]->Js.String2.replaceByRe(re, "")

  //         let binding = // Should we use the last item, or the targetVariable name?
  //         // dataPath[dataPath->Js.Array2.length - 1]->Js.String2.replaceByRe(re, "")
  //         targetVariableDependency.name

  //         let nullableTargetVariableType =
  //           targetVariableType->Belt.Option.map(typ =>
  //             typ
  //             ->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("!", ~flags="g"), "")
  //             ->namedGraphQLScalarTypeScriptType
  //           )

  //         let nullablePrintedType =
  //           sourceType->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("!", ~flags="g"), "")

  //         let defaultCoercerName = j`${nullablePrintedType}To${nullableTargetVariableType
  //           ->Belt.Option.getWithDefault("Unknown")
  //           ->Utils.String.capitalizeFirstLetter}`

  //         let coercerName = switch name {
  //         | None =>
  //           Utils.prompt(
  //             "Coercer function name: ",
  //             ~default=Some(defaultCoercerName->Utils.String.safeCamelize),
  //           )
  //           ->Js.Nullable.toOption
  //           ->Belt.Option.getWithDefault(defaultCoercerName)
  //         | Some(name) => name
  //         }->Utils.String.safeCamelize

  //         let coercerExists = switch name {
  //         | Some("INTERNAL_PASSTHROUGH") => true
  //         | _ =>
  //           parsed
  //           ->Belt.Option.flatMap(parsed => parsed->TypeScript.findFnPos(coercerName))
  //           ->Belt.Option.isSome
  //         }

  //         let newScript = lineNumbers->Belt.Option.map(((_fnLineNumber, fnBodyLineNumber)) => {
  //           let newBinding = switch name {
  //           | Some("INTERNAL_PASSTHROUGH") =>
  //             j`\tlet ${binding} = ${dataPath->Js.Array2.joinWith("?.")}`
  //           | _ => j`\tlet ${binding} = ${coercerName}(${dataPath->Js.Array2.joinWith("?.")})`
  //           }

  //           let temp = script->Js.String2.split("\n")

  //           let _ =
  //             temp->Js.Array2.spliceInPlace(~pos=fnBodyLineNumber + 1, ~remove=0, ~add=[newBinding])

  //           let inputType = request->Belt.Option.mapWithDefault(nullablePrintedType, request => {
  //             let names = request->Chain.requestScriptNames
  //             let typePath = path->Belt.Array.joinWith("", step => {
  //               step->Js.String2.endsWith("[0]")
  //                 ? {
  //                     let step = step->Js.String2.replace("[0]", "")
  //                     j`["${step}"][0]`
  //                   }
  //                 : j`["${step}"]`
  //             })
  //             let typ = `${names.inputTypeName}${typePath}`
  //             typ
  //           })

  //           let signatureReturnType =
  //             nullableTargetVariableType->Belt.Option.mapWithDefault("", t => j`: ${t}`)

  //           let newFunctionDefinition = j`function ${coercerName}(${inputName} : ${inputType}) ${signatureReturnType} {
  //     /* TODO: Convert ${inputName} => ${binding} */
  //     return ${inputName}
  //   }`

  //           coercerExists
  //             ? temp->Js.Array2.joinWith("\n")
  //             : temp->Js.Array2.joinWith("\n") ++ "\n\n" ++ newFunctionDefinition
  //         })

  //         let parsed = newScript->Belt.Option.flatMap(newScript =>
  //           try {
  //             Some(TypeScript.createSourceFile(~name="main.ts", ~source=newScript, ~target=99, true))
  //           } catch {
  //           | _ => None
  //           }
  //         )

  //         let functionObjectLiteralReturn = request->Belt.Option.flatMap(request => {
  //           let names = request->Chain.requestScriptNames

  //           parsed->Belt.Option.flatMap(parsed =>
  //             parsed->TypeScript.findLastReturnObjectPos(
  //               ~functionName=names.functionName,
  //               ~properyName=binding,
  //             )
  //           )
  //         })

  //         let shouldInsertPropertyInReturn =
  //           functionObjectLiteralReturn->Belt.Option.mapWithDefault(false, return =>
  //             return.property->Belt.Option.isNone
  //           )

  //         let newScript = newScript->Belt.Option.map(newScript =>
  //           functionObjectLiteralReturn->Belt.Option.mapWithDefault(
  //             newScript,
  //             returnObjectPositions => {
  //               shouldInsertPropertyInReturn
  //                 ? {
  //                     Debug.assignToWindowForDeveloperDebug(~name="tNewScript", newScript)
  //                     let head =
  //                       newScript->Js.String2.slice(
  //                         ~from=0,
  //                         ~to_=returnObjectPositions.objectPosition.start + 2,
  //                       )

  //                     let tail =
  //                       newScript->Js.String2.slice(
  //                         ~from=returnObjectPositions.objectPosition.start + 2,
  //                         ~to_=newScript->Js.String2.length,
  //                       )

  //                     j`${head} ${binding}: ${binding},${tail}`
  //                   }
  //                 : newScript
  //             },
  //           )
  //         )

  //         let newChain = {
  //           ...oldState.chain,
  //           script: newScript->Belt.Option.getWithDefault(script),
  //           requests: newRequests,
  //         }

  //         {...oldState, chain: newChain, connectionDrag: Empty}
  //       })
  //     }

  //     let onClose = () => {
  //       setState(oldState => {...oldState, connectionDrag: Empty})
  //     }

  //     <PopUpPicker top=y left=x onClose>
  //       <span style={ReactDOMStyle.make(~color=Comps.colors["gray-2"], ())}>
  //         {"Type mismatch, choose coercer: "->string}
  //       </span>
  //       <ul>
  //         <li
  //           className="cursor-pointer graphql-structure-preview-entry"
  //           key="INTERNAL_PASSTHROUGH"
  //           onClick={_ => onClick(Some("INTERNAL_PASSTHROUGH"))}>
  //           {"Passthrough"->string}
  //         </li>
  //         {potentialFunctionMatches
  //         ->Belt.Array.map((fn: TypeScript.simpleFunctionType) => {
  //           <li
  //             className="cursor-pointer graphql-structure-preview-entry"
  //             onClick={_ => onClick(Some(fn.name))}
  //             key=fn.name>
  //             {fn.name->string}
  //           </li>
  //         })
  //         ->array}
  //         <li
  //           className="cursor-pointer graphql-structure-preview-entry"
  //           key="createNew"
  //           onClick={_ => onClick(None)}>
  //           {"Create new function"->string}
  //         </li>
  //       </ul>
  //     </PopUpPicker>
  //   | Completed({sourceRequest, target: Script({scriptPosition}), windowPosition: (x, y)}) =>
  //     let chainFragmentsDoc =
  //       state.chain.blocks
  //       ->Belt.Array.keepMap(block => {
  //         switch block.kind {
  //         | Fragment => Some(block.body)
  //         | _ => None
  //         }
  //       })
  //       ->Js.Array2.joinWith("\n\n")

  //     let parsedOperation = sourceRequest.operation.body->GraphQLJs.parse
  //     let definition = parsedOperation.definitions->Belt.Array.getExn(0)

  //     let onClose = () =>
  //       setState(oldState => {
  //         ...oldState,
  //         connectionDrag: Empty,
  //       })

  //     <PopUpPicker top=y left=x onClose>
  //       <Inspector.GraphQLPreview
  //         requestId=sourceRequest.id
  //         schema
  //         definition
  //         fragmentDefinitions={GraphQLJs.Mock.gatherFragmentDefinitions({
  //           "operationDoc": chainFragmentsDoc,
  //         })}
  //         targetGqlType="[String]"
  //         onClose={() => {
  //           setState(oldState => {...oldState, connectionDrag: Empty})
  //         }}
  //         definitionResultData
  //         onCopy={payload => {
  //           let {path} = payload
  //           let dataPath = ["payload"]->Belt.Array.concat(path)
  //           let re = Js.Re.fromStringWithFlags(~flags="g", "\\[.+\\]")
  //           let binding = switch dataPath {
  //           | [] => "unknown"
  //           | [field]
  //           | [_, field] => field
  //           | other =>
  //             let parent = other[other->Js.Array2.length - 2]
  //             let field = other[other->Js.Array2.length - 1]->Utils.String.capitalizeFirstLetter
  //             `${parent}${field}`
  //           }->Js.String2.replaceByRe(re, "")

  //           setState(oldState => {
  //             let parsed = try {
  //               Some(
  //                 TypeScript.createSourceFile(
  //                   ~name="main.ts",
  //                   ~source=oldState.chain.script,
  //                   ~target=99,
  //                   true,
  //                 ),
  //               )
  //             } catch {
  //             | _ => None
  //             }

  //             let lineNumber = parsed->Belt.Option.map(parsed =>
  //               try {
  //                 let position =
  //                   parsed->TypeScript.getPositionOfLineAndCharacter(
  //                     scriptPosition.lineNumber - 1,
  //                     scriptPosition.column - 1,
  //                   )

  //                 let parsedPosition =
  //                   parsed
  //                   ->TypeScript.findPositionOfFirstLineOfContainingFunctionForPosition(position)
  //                   ->Belt.Option.getExn

  //                 let lineAndCharacter =
  //                   parsed->TypeScript.getLineAndCharacterOfPosition(parsedPosition)

  //                 lineAndCharacter.line + 1
  //               } catch {
  //               | e =>
  //                 Js.Console.warn2("Exn trying to find smart position", e)
  //                 scriptPosition.lineNumber - 1
  //               }
  //             )

  //             let assignmentExpressionRange = parsed->Belt.Option.flatMap(parsed => {
  //               let position =
  //                 parsed->TypeScript.getPositionOfLineAndCharacter(
  //                   scriptPosition.lineNumber - 1,
  //                   scriptPosition.column - 1,
  //                 )
  //               parsed->TypeScript.findContainingDeclaration(position)
  //             })

  //             let newScript = switch (assignmentExpressionRange, lineNumber) {
  //             | (Some({name, start, end}), _) =>
  //               let newBinding = j`${name} = ${dataPath->Js.Array2.joinWith("?.")}`

  //               oldState.chain.script->Utils.String.replaceRange(
  //                 ~start=start + 1,
  //                 ~end,
  //                 ~by=newBinding,
  //               )
  //             | (_, Some(lineNumber)) =>
  //               let newBinding = j`\tlet ${binding} = ${dataPath->Js.Array2.joinWith("?.")}`

  //               let temp = oldState.chain.script->Js.String2.split("\n")

  //               let _ = temp->Js.Array2.spliceInPlace(~pos=lineNumber, ~remove=0, ~add=[newBinding])
  //               temp->Js.Array2.joinWith("\n")
  //             | _ => oldState.chain.script
  //             }

  //             let newChain = {...oldState.chain, script: newScript}

  //             {
  //               ...oldState,
  //               chain: newChain,
  //               connectionDrag: Empty,
  //             }
  //           })
  //         }}
  //       />
  //     </PopUpPicker>
  //   | Completed({sourceRequest, target: Input({inputDom}), windowPosition: (x, y)}) =>
  //     let chainFragmentsDoc =
  //       state.chain.blocks
  //       ->Belt.Array.keepMap(block => {
  //         switch block.kind {
  //         | Fragment => Some(block.body)
  //         | _ => None
  //         }
  //       })
  //       ->Js.Array2.joinWith("\n\n")

  //     let parsedOperation = sourceRequest.operation.body->GraphQLJs.parse
  //     let definition = parsedOperation.definitions->Belt.Array.getExn(0)

  //     let onClose = () =>
  //       setState(oldState => {
  //         ...oldState,
  //         connectionDrag: Empty,
  //       })

  //     <PopUpPicker top=y left=x onClose>
  //       <Inspector.GraphQLPreview
  //         requestId=sourceRequest.id
  //         schema
  //         definition
  //         fragmentDefinitions={GraphQLJs.Mock.gatherFragmentDefinitions({
  //           "operationDoc": chainFragmentsDoc,
  //         })}
  //         targetGqlType="[String]"
  //         onClose={() => {
  //           setState(oldState => {...oldState, connectionDrag: Empty})
  //         }}
  //         definitionResultData
  //         onCopy={payload => {
  //           let {displayedData} = payload

  //           let _ = try {
  //             inputDom->Inspector.forceablySetInputValue(displayedData)
  //           } catch {
  //           | _ => ()
  //           }

  //           setState(oldState => {
  //             ...oldState,
  //             connectionDrag: Empty,
  //           })
  //         }}
  //       />
  //     </PopUpPicker>
  //   | Completed({
  //       sourceRequest,
  //       sourceDom,
  //       target: Variable(
  //         {variableDependency: targetVariableDependency, targetRequest} as variabletarget,
  //       ),
  //       windowPosition: (x, y) as windowPosition,
  //     }) =>
  //     let chainFragmentsDoc =
  //       state.chain.blocks
  //       ->Belt.Array.keepMap(block => {
  //         switch block.kind {
  //         | Fragment => Some(block.body)
  //         | _ => None
  //         }
  //       })
  //       ->Js.Array2.joinWith("\n\n")

  //     let parsedOperation = sourceRequest.operation.body->GraphQLJs.parse
  //     let definition = parsedOperation.definitions->Belt.Array.getExn(0)

  //     let targetParsedOperation = targetRequest.operation.body->GraphQLJs.parse
  //     let targetDefinition = targetParsedOperation.definitions->Belt.Array.getExn(0)
  //     let targetVariables = targetDefinition->GraphQLUtils.getOperationVariables

  //     let targetVariableType =
  //       targetVariables
  //       ->Belt.Array.getBy(((variableName, _)) => {
  //         targetVariableDependency.name == variableName
  //       })
  //       ->Belt.Option.map(((_, typ)) => typ)

  //     let onClose = () =>
  //       setState(oldState => {
  //         ...oldState,
  //         connectionDrag: Empty,
  //       })

  //     <PopUpPicker top=y left=x onClose>
  //       <Inspector.GraphQLPreview
  //         requestId=sourceRequest.id
  //         schema
  //         definition
  //         fragmentDefinitions={GraphQLJs.Mock.gatherFragmentDefinitions({
  //           "operationDoc": chainFragmentsDoc,
  //         })}
  //         targetGqlType=?targetVariableType
  //         onClose={() => {
  //           setState(oldState => {...oldState, connectionDrag: Empty})
  //         }}
  //         definitionResultData
  //         onCopy={({printedType, path}) => {
  //           let dataPath = ["payload"]->Belt.Array.concat(path)

  //           let nullableTargetVariableType =
  //             targetVariableType->Belt.Option.map(typ =>
  //               typ->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("!", ~flags="g"), "")
  //             )

  //           let nullablePrintedType =
  //             printedType->Js.String2.replaceByRe(Js.Re.fromStringWithFlags("!", ~flags="g"), "")

  //           let typesMatch = switch (
  //             Some(nullablePrintedType->Js.String2.toLocaleLowerCase),
  //             nullableTargetVariableType->Belt.Option.map(Js.String2.toLocaleLowerCase),
  //           ) {
  //           | (Some(a), Some(b)) if a == b => true
  //           | (Some("string"), Some("id"))
  //           | (Some("id"), Some("string")) => true
  //           | (Some("int"), Some("float"))
  //           | (Some("float"), Some("int")) => true
  //           | (Some("json"), _)
  //           | (_, Some("json")) => true
  //           | _ => false
  //           }

  //           switch typesMatch {
  //           | false =>
  //             setState(oldState => {
  //               let parsed = try {
  //                 Some(
  //                   TypeScript.createSourceFile(
  //                     ~name="main.ts",
  //                     ~source=oldState.chain.script,
  //                     ~target=99,
  //                     true,
  //                   ),
  //                 )
  //               } catch {
  //               | _ => None
  //               }

  //               let newConnectionDrag = parsed->Belt.Option.map(parsed => {
  //                 let fnTypes = parsed->TypeScript.findFunctionTypes

  //                 let existingFnMatches =
  //                   fnTypes
  //                   ->Js.Dict.values
  //                   ->Belt.Array.keep(({firstParamType, returnType}) => {
  //                     let firstParamMatches = switch (
  //                       nullablePrintedType->Js.String2.toLocaleLowerCase,
  //                       firstParamType->Belt.Option.map(Js.String2.toLocaleLowerCase),
  //                     ) {
  //                     | (a, Some(b)) if a == b => true
  //                     | ("int", Some("number"))
  //                     | ("float", Some("number")) => true
  //                     | ("id", Some("string")) => true
  //                     | _ => false
  //                     }

  //                     let returnTypeMatches = switch (
  //                       nullableTargetVariableType->Belt.Option.map(Js.String2.toLocaleLowerCase),
  //                       returnType->Belt.Option.map(Js.String2.toLocaleLowerCase),
  //                     ) {
  //                     | (Some(a), Some(b)) if a == b => true
  //                     | (Some("int"), Some("number"))
  //                     | (Some("float"), Some("number")) => true
  //                     | (Some("id"), Some("string")) => true
  //                     | _ => false
  //                     }

  //                     firstParamMatches && returnTypeMatches
  //                   })
  //                   ->Belt.SortArray.stableSortBy((a, b) => String.compare(a.name, b.name))

  //                 ConnectionContext.CompletedWithTypeMismatch({
  //                   sourceRequest: sourceRequest,
  //                   sourceDom: sourceDom,
  //                   variableTarget: variabletarget,
  //                   windowPosition: windowPosition,
  //                   targetVariableType: targetVariableType,
  //                   sourceType: printedType,
  //                   potentialFunctionMatches: existingFnMatches,
  //                   dataPath: dataPath,
  //                   path: path,
  //                 })
  //               })

  //               {
  //                 ...oldState,
  //                 connectionDrag: newConnectionDrag->Belt.Option.getWithDefault(Empty),
  //               }
  //             })
  //           | true =>
  //             setState(oldState => {
  //               let potentialProbeDependency = Chain.GraphQLProbe({
  //                 name: targetVariableDependency.name,
  //                 ifMissing: #SKIP,
  //                 ifList: #FIRST,
  //                 fromRequestId: sourceRequest.id,
  //                 functionFromScript: "TBD",
  //                 path: dataPath,
  //               })

  //               let newRequests = oldState.chain.requests->Belt.Array.map(request => {
  //                 switch targetRequest.id == request.id {
  //                 | false => request
  //                 | true =>
  //                   let varDeps = request.variableDependencies->Belt.Array.map(varDep => {
  //                     switch varDep.name == targetVariableDependency.name {
  //                     | true => {...varDep, dependency: potentialProbeDependency}

  //                     | false =>
  //                       let dependency = switch varDep.dependency {
  //                       | ArgumentDependency(argDep) =>
  //                         let newArgDep = {
  //                           ...argDep,
  //                           fromRequestIds: argDep.fromRequestIds
  //                           ->Belt.Array.concat([sourceRequest.id])
  //                           ->Utils.String.distinctStrings,
  //                         }

  //                         Chain.ArgumentDependency(newArgDep)
  //                       | other => other
  //                       }
  //                       let varDep = {...varDep, dependency: dependency}

  //                       varDep
  //                     }
  //                   })

  //                   {
  //                     ...request,
  //                     variableDependencies: varDeps,
  //                     dependencyRequestIds: request.dependencyRequestIds
  //                     ->Belt.Array.concat([sourceRequest.id])
  //                     ->Utils.String.distinctStrings,
  //                   }
  //                 }
  //               })

  //               let newScript =
  //                 Inspector.deleteRequestFunctionIfEmpty(
  //                   ~script=oldState.chain.script,
  //                   ~request=targetRequest,
  //                   (),
  //                 )
  //                 ->Belt.Result.getWithDefault(oldState.chain.script)
  //                 ->Js.String2.trim

  //               let newChain = {
  //                 ...oldState.chain,
  //                 script: newScript,
  //                 requests: newRequests,
  //               }

  //               let diagram = diagramFromChain(newChain)

  //               let newTargetRequest = newChain.requests->Belt.Array.getBy(request => {
  //                 targetRequest.id == request.id
  //               })

  //               let inspected = newTargetRequest->Belt.Option.mapWithDefault(
  //                 oldState.inspected,
  //                 newTargetRequest => {
  //                   switch oldState.inspected {
  //                   | Request({request: {id}}) if id == newTargetRequest.id =>
  //                     Request({chain: newChain, request: newTargetRequest})
  //                   | _ => oldState.inspected
  //                   }
  //                 },
  //               )

  //               {
  //                 ...oldState,
  //                 inspected: inspected,
  //                 diagram: diagram,
  //                 chain: newChain,
  //                 connectionDrag: Empty,
  //               }
  //             })
  //           }
  //         }}
  //       />
  //     </PopUpPicker>
  | StartedSource(conDrag) =>
    <DragConnectorLine
      source=conDrag.sourceDom invert={false} onDragEnd={connectionDrag.onDragEnd}
    />
  | StartedTarget({target: Variable(_), sourceDom}) =>
    <DragConnectorLine source=sourceDom invert={true} onDragEnd={connectionDrag.onDragEnd} />
  | _ => null
  }
}
