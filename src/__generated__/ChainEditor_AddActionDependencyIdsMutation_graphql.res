/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec response_oneGraph = {
    addActionDependencyIds: option<response_oneGraph_addActionDependencyIds>,
  }
   and response_oneGraph_addActionDependencyIds = {
    action: response_oneGraph_addActionDependencyIds_action,
  }
   and response_oneGraph_addActionDependencyIds_action = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ActionInspector_oneGraphStudioChainAction]>
  }
   and oneGraphAddActionDependencyIdsInput = {
    addActionDependencyIds: array<string>,
    actionId: string,
  }
  
  
  type response = {
    oneGraph: response_oneGraph,
  }
  type rawResponse = response
  type variables = {
    input: oneGraphAddActionDependencyIdsInput,
  }
}

module Internal = {
  type wrapResponseRaw
  let wrapResponseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"oneGraph_addActionDependencyIds_action":{"f":""},"oneGraph_addActionDependencyIds":{"n":""}}}`
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
      json`{"__root":{"oneGraph_addActionDependencyIds_action":{"f":""},"oneGraph_addActionDependencyIds":{"n":""}}}`
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
      json`{"__root":{"input":{"r":"OneGraphAddActionDependencyIdsInput"}}}`
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
  let make_oneGraphAddActionDependencyIdsInput = (
    ~addActionDependencyIds,
    ~actionId
  ): oneGraphAddActionDependencyIdsInput => {
    addActionDependencyIds: addActionDependencyIds,
    actionId: actionId
  }
  
  let makeVariables = (
    ~input
  ): variables => {
    input: input
  }
  let make_response_oneGraph_addActionDependencyIds_action = (
  ) => ()
  let make_response_oneGraph_addActionDependencyIds = (
    ~action
  ): response_oneGraph_addActionDependencyIds => {
    action: action
  }
  let make_response_oneGraph = (
    ~addActionDependencyIds=?,
    ()
  ): response_oneGraph => {
    addActionDependencyIds: addActionDependencyIds
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
    "name": "ChainEditor_AddActionDependencyIdsMutation",
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
            "concreteType": "OneGraphAddActionDependencyIdsResponsePayload",
            "kind": "LinkedField",
            "name": "addActionDependencyIds",
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
    "name": "ChainEditor_AddActionDependencyIdsMutation",
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
            "concreteType": "OneGraphAddActionDependencyIdsResponsePayload",
            "kind": "LinkedField",
            "name": "addActionDependencyIds",
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
    "cacheID": "5c25b72c44d9b9cef9ad7a98b1bed58f",
    "id": null,
    "metadata": {},
    "name": "ChainEditor_AddActionDependencyIdsMutation",
    "operationKind": "mutation",
    "text": "mutation ChainEditor_AddActionDependencyIdsMutation(\n  $input: OneGraphAddActionDependencyIdsInput!\n) {\n  oneGraph {\n    addActionDependencyIds(input: $input) {\n      action {\n        ...ActionInspector_oneGraphStudioChainAction\n      }\n    }\n  }\n}\n\nfragment ActionForm_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  actionVariables: variables {\n    id\n    name\n    graphqlType\n  }\n}\n\nfragment ActionInspector_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  upstreamActionIds\n  graphqlOperation\n  actionVariables: variables {\n    id\n    name\n    ...VariableInspector_oneGraphStudioChainActionVariable\n  }\n  ...ActionForm_oneGraphStudioChainAction\n}\n\nfragment ComputedVariableInspector_chainActionVariable on OneGraphStudioChainActionVariable {\n  id\n}\n\nfragment VariableInspector_oneGraphStudioChainActionVariable on OneGraphStudioChainActionVariable {\n  id\n  name\n  graphqlType\n  description\n  ifList\n  ifMissing\n  maxRecur\n  computeMethod: method\n  probePath\n  ...ComputedVariableInspector_chainActionVariable\n}\n"
  }
};
})() `)


