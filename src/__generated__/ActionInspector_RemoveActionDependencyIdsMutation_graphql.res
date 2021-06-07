/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec response_oneGraph = {
    removeActionDependencyIds: option<response_oneGraph_removeActionDependencyIds>,
  }
   and response_oneGraph_removeActionDependencyIds = {
    action: response_oneGraph_removeActionDependencyIds_action,
  }
   and response_oneGraph_removeActionDependencyIds_action = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ActionInspector_oneGraphStudioChainAction]>
  }
   and oneGraphRemoveActionDependencyIdsInput = {
    removeActionDependencyIds: array<string>,
    actionId: string,
  }
  
  
  type response = {
    oneGraph: response_oneGraph,
  }
  type rawResponse = response
  type variables = {
    input: oneGraphRemoveActionDependencyIdsInput,
  }
}

module Internal = {
  type wrapResponseRaw
  let wrapResponseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"oneGraph_removeActionDependencyIds_action":{"f":""},"oneGraph_removeActionDependencyIds":{"n":""}}}`
    )
  
  let wrapResponseConverterMap = ()
  let convertWrapResponse = v => v->RescriptRelay.convertObj(
    wrapResponseConverter, 
    wrapResponseConverterMap, 
    Js.null
  )
  type responseRaw
  let responseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"oneGraph_removeActionDependencyIds_action":{"f":""},"oneGraph_removeActionDependencyIds":{"n":""}}}`
    )
  
  let responseConverterMap = ()
  let convertResponse = v => v->RescriptRelay.convertObj(
    responseConverter, 
    responseConverterMap, 
    Js.undefined
  )
  type wrapRawResponseRaw = wrapResponseRaw
  let convertWrapRawResponse = convertWrapResponse
  type rawResponseRaw = responseRaw
  let convertRawResponse = convertResponse
  let variablesConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"input":{"r":"OneGraphRemoveActionDependencyIdsInput"}}}`
    )
  
  let variablesConverterMap = ()
  let convertVariables = v => v->RescriptRelay.convertObj(
    variablesConverter, 
    variablesConverterMap, 
    Js.undefined
  )
}


module Utils = {
  @@ocaml.warning("-33")
  open Types
  let make_oneGraphRemoveActionDependencyIdsInput = (
    ~removeActionDependencyIds,
    ~actionId
  ): oneGraphRemoveActionDependencyIdsInput => {
    removeActionDependencyIds: removeActionDependencyIds,
    actionId: actionId
  }
  
  let makeVariables = (
    ~input
  ): variables => {
    input: input
  }
  let make_response_oneGraph_removeActionDependencyIds_action = (
  ) => ()
  let make_response_oneGraph_removeActionDependencyIds = (
    ~action
  ): response_oneGraph_removeActionDependencyIds => {
    action: action
  }
  let make_response_oneGraph = (
    ~removeActionDependencyIds=?,
    ()
  ): response_oneGraph => {
    removeActionDependencyIds: removeActionDependencyIds
  }
  let makeOptimisticResponse = (
    ~oneGraph
  ): rawResponse => {
    oneGraph: oneGraph
  }
}
type relayOperationNode
type operationType = RescriptRelay.mutationNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "input"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "input",
    "variableName": "input"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "description",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "ActionInspector_RemoveActionDependencyIdsMutation",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "OneGraphMutation",
        "kind": "LinkedField",
        "name": "oneGraph",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": (v1/*: any*/),
            "concreteType": "OneGraphRemoveActionDependencyIdsResponsePayload",
            "kind": "LinkedField",
            "name": "removeActionDependencyIds",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphStudioChainAction",
                "kind": "LinkedField",
                "name": "action",
                "plural": false,
                "selections": [
                  {
                    "args": null,
                    "kind": "FragmentSpread",
                    "name": "ActionInspector_oneGraphStudioChainAction"
                  }
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ],
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ActionInspector_RemoveActionDependencyIdsMutation",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "OneGraphMutation",
        "kind": "LinkedField",
        "name": "oneGraph",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": (v1/*: any*/),
            "concreteType": "OneGraphRemoveActionDependencyIdsResponsePayload",
            "kind": "LinkedField",
            "name": "removeActionDependencyIds",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphStudioChainAction",
                "kind": "LinkedField",
                "name": "action",
                "plural": false,
                "selections": [
                  (v2/*: any*/),
                  (v3/*: any*/),
                  (v4/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "upstreamActionIds",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "graphqlOperation",
                    "storageKey": null
                  },
                  {
                    "alias": "actionVariables",
                    "args": null,
                    "concreteType": "OneGraphStudioChainActionVariable",
                    "kind": "LinkedField",
                    "name": "variables",
                    "plural": true,
                    "selections": [
                      (v2/*: any*/),
                      (v3/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "graphqlType",
                        "storageKey": null
                      },
                      (v4/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "ifList",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "ifMissing",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "maxRecur",
                        "storageKey": null
                      },
                      {
                        "alias": "computeMethod",
                        "args": null,
                        "kind": "ScalarField",
                        "name": "method",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "probePath",
                        "storageKey": null
                      }
                    ],
                    "storageKey": null
                  }
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "33b94b2106d055eff526b209841f926f",
    "id": null,
    "metadata": {},
    "name": "ActionInspector_RemoveActionDependencyIdsMutation",
    "operationKind": "mutation",
    "text": "mutation ActionInspector_RemoveActionDependencyIdsMutation(\n  $input: OneGraphRemoveActionDependencyIdsInput!\n) {\n  oneGraph {\n    removeActionDependencyIds(input: $input) {\n      action {\n        ...ActionInspector_oneGraphStudioChainAction\n      }\n    }\n  }\n}\n\nfragment ActionForm_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  actionVariables: variables {\n    id\n    name\n    graphqlType\n  }\n}\n\nfragment ActionInspector_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  upstreamActionIds\n  graphqlOperation\n  actionVariables: variables {\n    id\n    name\n    ...VariableInspector_oneGraphStudioChainActionVariable\n  }\n  ...ActionForm_oneGraphStudioChainAction\n}\n\nfragment ComputedVariableInspector_chainActionVariable on OneGraphStudioChainActionVariable {\n  id\n}\n\nfragment VariableInspector_oneGraphStudioChainActionVariable on OneGraphStudioChainActionVariable {\n  id\n  name\n  graphqlType\n  description\n  ifList\n  ifMissing\n  maxRecur\n  computeMethod: method\n  probePath\n  ...ComputedVariableInspector_chainActionVariable\n}\n"
  }
};
})() `)


