/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type enum_OneGraphStudioChainActionVariableMethodArgEnum = private [>
    | #COMPUTED
    | #DIRECT
    ]
  
  type enum_OneGraphStudioChainActionVariableMethodArgEnum_input = [
    | #COMPUTED
    | #DIRECT
    ]
  
  type enum_OneGraphStudioChainActionVariableIfMissingArgEnum = private [>
    | #ALLOW
    | #ERROR
    | #SKIP
    ]
  
  type enum_OneGraphStudioChainActionVariableIfMissingArgEnum_input = [
    | #ALLOW
    | #ERROR
    | #SKIP
    ]
  
  type enum_OneGraphStudioChainActionVariableIfListArgEnum = private [>
    | #ALL
    | #EACH
    | #FIRST
    | #LAST
    ]
  
  type enum_OneGraphStudioChainActionVariableIfListArgEnum_input = [
    | #ALL
    | #EACH
    | #FIRST
    | #LAST
    ]
  
  type enum_OneGraphStudioChainActionOperationKindArgEnum = private [>
    | #COMPUTE
    | #FRAGMENT
    | #MUTATION
    | #QUERY
    | #SUBSCRIPTION
    ]
  
  type enum_OneGraphStudioChainActionOperationKindArgEnum_input = [
    | #COMPUTE
    | #FRAGMENT
    | #MUTATION
    | #QUERY
    | #SUBSCRIPTION
    ]
  
  type rec response_oneGraph = {
    createChainAction: option<response_oneGraph_createChainAction>,
  }
   and response_oneGraph_createChainAction = {
    chain: option<response_oneGraph_createChainAction_chain>,
  }
   and response_oneGraph_createChainAction_chain = {
    id: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ChainEditor_chain]>
  }
   and oneGraphCreateChainActionInput = {
    variables: array<oneGraphCreateChainActionSubVariableInput>,
    services: array<string>,
    graphqlOperationKind: [
    | #COMPUTE
    | #FRAGMENT
    | #MUTATION
    | #QUERY
    | #SUBSCRIPTION
    ],
    graphqlOperation: string,
    description: option<string>,
    name: string,
    chainId: string,
  }
   and oneGraphCreateChainActionSubVariableInput = {
    probePath: array<string>,
    @as("method") method_: [
    | #COMPUTED
    | #DIRECT
    ],
    maxRecur: int,
    ifList: [
    | #ALL
    | #EACH
    | #FIRST
    | #LAST
    ],
    ifMissing: [
    | #ALLOW
    | #ERROR
    | #SKIP
    ],
    graphqlType: string,
    description: option<string>,
    name: string,
  }
  
  
  type response = {
    oneGraph: response_oneGraph,
  }
  type rawResponse = response
  type variables = {
    input: oneGraphCreateChainActionInput,
  }
}

module Internal = {
  type wrapResponseRaw
  let wrapResponseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"oneGraph_createChainAction_chain":{"f":"","n":""},"oneGraph_createChainAction":{"n":""}}}`
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
      json`{"__root":{"oneGraph_createChainAction_chain":{"f":"","n":""},"oneGraph_createChainAction":{"n":""}}}`
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
      json`{"__root":{"input":{"r":"OneGraphCreateChainActionInput"}},"OneGraphCreateChainActionInput":{"description":{"n":""},"variables":{"r":"OneGraphCreateChainActionSubVariableInput"}},"OneGraphCreateChainActionSubVariableInput":{"description":{"n":""}}}`
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
  external oneGraphStudioChainActionVariableMethodArgEnum_toString:
  enum_OneGraphStudioChainActionVariableMethodArgEnum => string = "%identity"
  external oneGraphStudioChainActionVariableMethodArgEnum_input_toString:
  enum_OneGraphStudioChainActionVariableMethodArgEnum_input => string = "%identity"
  external oneGraphStudioChainActionVariableIfMissingArgEnum_toString:
  enum_OneGraphStudioChainActionVariableIfMissingArgEnum => string = "%identity"
  external oneGraphStudioChainActionVariableIfMissingArgEnum_input_toString:
  enum_OneGraphStudioChainActionVariableIfMissingArgEnum_input => string = "%identity"
  external oneGraphStudioChainActionVariableIfListArgEnum_toString:
  enum_OneGraphStudioChainActionVariableIfListArgEnum => string = "%identity"
  external oneGraphStudioChainActionVariableIfListArgEnum_input_toString:
  enum_OneGraphStudioChainActionVariableIfListArgEnum_input => string = "%identity"
  external oneGraphStudioChainActionOperationKindArgEnum_toString:
  enum_OneGraphStudioChainActionOperationKindArgEnum => string = "%identity"
  external oneGraphStudioChainActionOperationKindArgEnum_input_toString:
  enum_OneGraphStudioChainActionOperationKindArgEnum_input => string = "%identity"
  
  let make_oneGraphCreateChainActionSubVariableInput = (
    ~probePath,
    ~method_,
    ~maxRecur,
    ~ifList,
    ~ifMissing,
    ~graphqlType,
    ~description=?,
    ~name,
    ()
  ): oneGraphCreateChainActionSubVariableInput => {
    probePath: probePath,
    method_: method_,
    maxRecur: maxRecur,
    ifList: ifList,
    ifMissing: ifMissing,
    graphqlType: graphqlType,
    description: description,
    name: name
  }
  
  
  let make_oneGraphCreateChainActionInput = (
    ~variables,
    ~services,
    ~graphqlOperationKind,
    ~graphqlOperation,
    ~description=?,
    ~name,
    ~chainId,
    ()
  ): oneGraphCreateChainActionInput => {
    variables: variables,
    services: services,
    graphqlOperationKind: graphqlOperationKind,
    graphqlOperation: graphqlOperation,
    description: description,
    name: name,
    chainId: chainId
  }
  
  let makeVariables = (
    ~input
  ): variables => {
    input: input
  }
  let make_response_oneGraph_createChainAction_chain = (
    ~id,
    ~fragmentRefs
  ): response_oneGraph_createChainAction_chain => {
    id: id,
    fragmentRefs: fragmentRefs
  }
  let make_response_oneGraph_createChainAction = (
    ~chain=?,
    ()
  ): response_oneGraph_createChainAction => {
    chain: chain
  }
  let make_response_oneGraph = (
    ~createChainAction=?,
    ()
  ): response_oneGraph => {
    createChainAction: createChainAction
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
    "name": "ChainEditor_createChainActionMutation",
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
            "concreteType": "OneGraphCreateChainActionResponsePayload",
            "kind": "LinkedField",
            "name": "createChainAction",
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
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ChainEditor_createChainActionMutation",
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
            "concreteType": "OneGraphCreateChainActionResponsePayload",
            "kind": "LinkedField",
            "name": "createChainAction",
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
    "cacheID": "c6cf0b5071316abe28389a88f216232e",
    "id": null,
    "metadata": {},
    "name": "ChainEditor_createChainActionMutation",
    "operationKind": "mutation",
    "text": "mutation ChainEditor_createChainActionMutation(\n  $input: OneGraphCreateChainActionInput!\n) {\n  oneGraph {\n    createChainAction(input: $input) {\n      chain {\n        id\n        ...ChainEditor_chain\n      }\n    }\n  }\n}\n\nfragment ActionForm_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  actionVariables: variables {\n    id\n    name\n    graphqlType\n  }\n}\n\nfragment ActionGraphQLEditor_chainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  graphqlOperation\n  services\n}\n\nfragment ActionInspector_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  upstreamActionIds\n  graphqlOperation\n  actionVariables: variables {\n    id\n    name\n    ...VariableInspector_oneGraphStudioChainActionVariable\n  }\n  ...ActionForm_oneGraphStudioChainAction\n}\n\nfragment ChainCanvas_chain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    description\n    graphqlOperation\n    graphqlOperationKind\n    upstreamActionIds\n    ...NodeLabel_action\n  }\n}\n\nfragment ChainEditor_chain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    id\n    filename\n    language\n    concurrentSource\n    textualSource\n    ...ScriptEditor_source\n  }\n  createdAt\n  updatedAt\n  actions {\n    id\n    name\n    description\n    graphqlOperation\n    graphqlOperationKind\n    privacy\n    upstreamActionIds\n    services\n    script {\n      id\n      filename\n      language\n      concurrentSource\n      textualSource\n      ...ScriptEditor_source\n    }\n    ...ActionGraphQLEditor_chainAction\n  }\n  ...ChainCanvas_chain\n  ...Inspector_chain\n  ...ConnectionVisualizer_chainActions\n  ...Compiler_chain\n}\n\nfragment ChainInspector_packageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n    ...ActionInspector_oneGraphStudioChainAction\n  }\n  ...InspectorOverview_oneGraphAppPackageChain\n}\n\nfragment Compiler_chain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    id\n    filename\n    language\n    textualSource\n  }\n  actions {\n    id\n    name\n    graphqlOperationKind\n    graphqlOperation\n    script {\n      id\n      filename\n      language\n      textualSource\n    }\n    actionVariables: variables {\n      id\n      name\n      computeMethod: method\n      graphqlType\n    }\n  }\n}\n\nfragment ComputedVariableInspector_chainActionVariable on OneGraphStudioChainActionVariable {\n  id\n}\n\nfragment ConnectionVisualizer_chainActions on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    upstreamActionIds\n    actionVariables: variables {\n      id\n      name\n      graphqlType\n    }\n  }\n}\n\nfragment InspectorOverview_oneGraphAppPackageChain on OneGraphAppPackageChain {\n  id\n  description\n  actions {\n    id\n    name\n    upstreamActionIds\n    actionVariables: variables {\n      ...VariableInspector_oneGraphStudioChainActionVariable\n    }\n  }\n}\n\nfragment Inspector_SubInspector_packageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n    ...ActionInspector_oneGraphStudioChainAction\n  }\n}\n\nfragment Inspector_chain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n  }\n  ...Inspector_SubInspector_packageChain\n  ...ChainInspector_packageChain\n}\n\nfragment NodeLabel_action on OneGraphStudioChainAction {\n  id\n  name\n  services\n}\n\nfragment ScriptEditor_source on OneGraphSourceFile {\n  id\n  filename\n  language\n  concurrentSource\n  textualSource\n}\n\nfragment VariableInspector_oneGraphStudioChainActionVariable on OneGraphStudioChainActionVariable {\n  id\n  name\n  graphqlType\n  description\n  ifList\n  ifMissing\n  maxRecur\n  computeMethod: method\n  probePath\n  ...ComputedVariableInspector_chainActionVariable\n}\n"
  }
};
})() `)


