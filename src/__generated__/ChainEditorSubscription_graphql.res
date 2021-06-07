/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec response_oneGraph = {
    studioChainUpdate: response_oneGraph_studioChainUpdate,
  }
   and response_oneGraph_studioChainUpdate = {
    chain: response_oneGraph_studioChainUpdate_chain,
  }
   and response_oneGraph_studioChainUpdate_chain = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ChainEditor_chain]>
  }
  
  
  type response = {
    oneGraph: response_oneGraph,
  }
  type rawResponse = response
  type variables = {
    chainId: string,
  }
}

module Internal = {
  type responseRaw
  let responseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"oneGraph_studioChainUpdate_chain":{"f":""}}}`
    )
  
  let responseConverterMap = ()
  let convertResponse = v => v->RescriptRelay.convertObj(
    responseConverter, 
    responseConverterMap, 
    Js.undefined
  )
  type rawResponseRaw = responseRaw
  let convertRawResponse = convertResponse
  let variablesConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{}`
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
  let makeVariables = (
    ~chainId
  ): variables => {
    chainId: chainId
  }
}
type relayOperationNode
type operationType = RescriptRelay.subscriptionNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "chainId"
  }
],
v1 = [
  {
    "fields": [
      {
        "kind": "Variable",
        "name": "chainId",
        "variableName": "chainId"
      }
    ],
    "kind": "ObjectValue",
    "name": "input"
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
},
v5 = [
  (v2/*: any*/),
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "filename",
    "storageKey": null
  },
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "language",
    "storageKey": null
  },
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "concurrentSource",
    "storageKey": null
  },
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "textualSource",
    "storageKey": null
  }
];
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "ChainEditorSubscription",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "OneGraphSubscriptionRoot",
        "kind": "LinkedField",
        "name": "oneGraph",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": (v1/*: any*/),
            "concreteType": "OneGraphStudioChainUpdatedEventSubscriptionPayload",
            "kind": "LinkedField",
            "name": "studioChainUpdate",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphAppPackageChain",
                "kind": "LinkedField",
                "name": "chain",
                "plural": false,
                "selections": [
                  {
                    "args": null,
                    "kind": "FragmentSpread",
                    "name": "ChainEditor_chain"
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
    "type": "Subscription",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ChainEditorSubscription",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "OneGraphSubscriptionRoot",
        "kind": "LinkedField",
        "name": "oneGraph",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": (v1/*: any*/),
            "concreteType": "OneGraphStudioChainUpdatedEventSubscriptionPayload",
            "kind": "LinkedField",
            "name": "studioChainUpdate",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphAppPackageChain",
                "kind": "LinkedField",
                "name": "chain",
                "plural": false,
                "selections": [
                  (v2/*: any*/),
                  (v3/*: any*/),
                  (v4/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "OneGraphSourceFile",
                    "kind": "LinkedField",
                    "name": "libraryScript",
                    "plural": false,
                    "selections": (v5/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "createdAt",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "updatedAt",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "OneGraphStudioChainAction",
                    "kind": "LinkedField",
                    "name": "actions",
                    "plural": true,
                    "selections": [
                      (v2/*: any*/),
                      (v3/*: any*/),
                      (v4/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "graphqlOperation",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "graphqlOperationKind",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "privacy",
                        "storageKey": null
                      },
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
                        "name": "services",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "OneGraphSourceFile",
                        "kind": "LinkedField",
                        "name": "script",
                        "plural": false,
                        "selections": (v5/*: any*/),
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
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "4ff9daeba6e5c133303cd73eca6261b0",
    "id": null,
    "metadata": {},
    "name": "ChainEditorSubscription",
    "operationKind": "subscription",
    "text": "subscription ChainEditorSubscription(\n  $chainId: String!\n) {\n  oneGraph {\n    studioChainUpdate(input: {chainId: $chainId}) {\n      chain {\n        ...ChainEditor_chain\n      }\n    }\n  }\n}\n\nfragment ActionForm_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  actionVariables: variables {\n    id\n    name\n    graphqlType\n  }\n}\n\nfragment ActionGraphQLEditor_chainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  graphqlOperation\n  services\n}\n\nfragment ActionInspector_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  upstreamActionIds\n  graphqlOperation\n  actionVariables: variables {\n    id\n    name\n    ...VariableInspector_oneGraphStudioChainActionVariable\n  }\n  ...ActionForm_oneGraphStudioChainAction\n}\n\nfragment ChainCanvas_chain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    description\n    graphqlOperation\n    graphqlOperationKind\n    upstreamActionIds\n    ...NodeLabel_action\n  }\n}\n\nfragment ChainEditor_chain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    id\n    filename\n    language\n    concurrentSource\n    textualSource\n    ...ScriptEditor_source\n  }\n  createdAt\n  updatedAt\n  actions {\n    id\n    name\n    description\n    graphqlOperation\n    graphqlOperationKind\n    privacy\n    upstreamActionIds\n    services\n    script {\n      id\n      filename\n      language\n      concurrentSource\n      textualSource\n      ...ScriptEditor_source\n    }\n    ...ActionGraphQLEditor_chainAction\n  }\n  ...ChainCanvas_chain\n  ...Inspector_chain\n  ...ConnectionVisualizer_chainActions\n  ...Compiler_chain\n}\n\nfragment ChainInspector_packageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n    ...ActionInspector_oneGraphStudioChainAction\n  }\n  ...InspectorOverview_oneGraphAppPackageChain\n}\n\nfragment Compiler_chain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    id\n    filename\n    language\n    textualSource\n  }\n  actions {\n    id\n    name\n    graphqlOperationKind\n    graphqlOperation\n    script {\n      id\n      filename\n      language\n      textualSource\n    }\n    actionVariables: variables {\n      id\n      name\n      computeMethod: method\n      graphqlType\n    }\n  }\n}\n\nfragment ComputedVariableInspector_chainActionVariable on OneGraphStudioChainActionVariable {\n  id\n}\n\nfragment ConnectionVisualizer_chainActions on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    upstreamActionIds\n    actionVariables: variables {\n      id\n      name\n      graphqlType\n    }\n  }\n}\n\nfragment InspectorOverview_oneGraphAppPackageChain on OneGraphAppPackageChain {\n  id\n  description\n  actions {\n    id\n    name\n    upstreamActionIds\n    actionVariables: variables {\n      ...VariableInspector_oneGraphStudioChainActionVariable\n    }\n  }\n}\n\nfragment Inspector_SubInspector_packageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n    ...ActionInspector_oneGraphStudioChainAction\n  }\n}\n\nfragment Inspector_chain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n  }\n  ...Inspector_SubInspector_packageChain\n  ...ChainInspector_packageChain\n}\n\nfragment NodeLabel_action on OneGraphStudioChainAction {\n  id\n  name\n  services\n}\n\nfragment ScriptEditor_source on OneGraphSourceFile {\n  id\n  filename\n  language\n  concurrentSource\n  textualSource\n}\n\nfragment VariableInspector_oneGraphStudioChainActionVariable on OneGraphStudioChainActionVariable {\n  id\n  name\n  graphqlType\n  description\n  ifList\n  ifMissing\n  maxRecur\n  computeMethod: method\n  probePath\n  ...ComputedVariableInspector_chainActionVariable\n}\n"
  }
};
})() `)


