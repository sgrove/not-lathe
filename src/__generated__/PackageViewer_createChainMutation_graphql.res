/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec response_oneGraph = {
    createChain: option<response_oneGraph_createChain>,
  }
   and response_oneGraph_createChain = {
    chain: response_oneGraph_createChain_chain,
    package: option<response_oneGraph_createChain_package>,
  }
   and response_oneGraph_createChain_chain = {
    id: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ChainViewer_chain | #ChainEditor_chain]>
  }
   and response_oneGraph_createChain_package = {
    id: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PackageViewer_package]>
  }
   and oneGraphCreateChainInput = {
    description: option<string>,
    name: string,
    packageId: string,
  }
  
  
  type response = {
    oneGraph: response_oneGraph,
  }
  type rawResponse = response
  type variables = {
    input: oneGraphCreateChainInput,
  }
}

module Internal = {
  type wrapResponseRaw
  let wrapResponseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"oneGraph_createChain":{"n":""},"oneGraph_createChain_chain":{"f":""},"oneGraph_createChain_package":{"f":"","n":""}}}`
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
      json`{"__root":{"oneGraph_createChain":{"n":""},"oneGraph_createChain_chain":{"f":""},"oneGraph_createChain_package":{"f":"","n":""}}}`
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
      json`{"__root":{"input":{"r":"OneGraphCreateChainInput"}},"OneGraphCreateChainInput":{"description":{"n":""}}}`
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
  let make_oneGraphCreateChainInput = (
    ~description=?,
    ~name,
    ~packageId,
    ()
  ): oneGraphCreateChainInput => {
    description: description,
    name: name,
    packageId: packageId
  }
  
  let makeVariables = (
    ~input
  ): variables => {
    input: input
  }
  let make_response_oneGraph_createChain_package = (
    ~id,
    ~fragmentRefs
  ): response_oneGraph_createChain_package => {
    id: id,
    fragmentRefs: fragmentRefs
  }
  let make_response_oneGraph_createChain_chain = (
    ~id,
    ~fragmentRefs
  ): response_oneGraph_createChain_chain => {
    id: id,
    fragmentRefs: fragmentRefs
  }
  let make_response_oneGraph_createChain = (
    ~chain,
    ~package=?,
    ()
  ): response_oneGraph_createChain => {
    chain: chain,
    package: package
  }
  let make_response_oneGraph = (
    ~createChain=?,
    ()
  ): response_oneGraph => {
    createChain: createChain
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
  },
  (v2/*: any*/)
],
v6 = {
  "alias": null,
  "args": null,
  "concreteType": "OneGraphSourceFile",
  "kind": "LinkedField",
  "name": "libraryScript",
  "plural": false,
  "selections": (v5/*: any*/),
  "storageKey": null
},
v7 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "createdAt",
  "storageKey": null
},
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "updatedAt",
  "storageKey": null
},
v9 = {
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
      "name": "privacy",
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
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "PackageViewer_createChainMutation",
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
            "concreteType": "OneGraphCreateChainResponsePayload",
            "kind": "LinkedField",
            "name": "createChain",
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
                    "name": "ChainViewer_chain"
                  },
                  {
                    "args": null,
                    "kind": "FragmentSpread",
                    "name": "ChainEditor_chain"
                  }
                ],
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphAppPackage",
                "kind": "LinkedField",
                "name": "package",
                "plural": false,
                "selections": [
                  (v2/*: any*/),
                  {
                    "args": null,
                    "kind": "FragmentSpread",
                    "name": "PackageViewer_package"
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
    "name": "PackageViewer_createChainMutation",
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
            "concreteType": "OneGraphCreateChainResponsePayload",
            "kind": "LinkedField",
            "name": "createChain",
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
                  (v6/*: any*/),
                  (v7/*: any*/),
                  (v8/*: any*/),
                  (v9/*: any*/)
                ],
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphAppPackage",
                "kind": "LinkedField",
                "name": "package",
                "plural": false,
                "selections": [
                  (v2/*: any*/),
                  (v4/*: any*/),
                  (v3/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "version",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "OneGraphAppPackageChain",
                    "kind": "LinkedField",
                    "name": "chains",
                    "plural": true,
                    "selections": [
                      (v2/*: any*/),
                      (v3/*: any*/),
                      (v4/*: any*/),
                      (v6/*: any*/),
                      (v7/*: any*/),
                      (v8/*: any*/),
                      (v9/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "OneGraphAccessToken",
                        "kind": "LinkedField",
                        "name": "authToken",
                        "plural": false,
                        "selections": [
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "obscuredToken",
                            "storageKey": null
                          },
                          (v3/*: any*/),
                          {
                            "alias": null,
                            "args": null,
                            "concreteType": "OneGraphUserAuth",
                            "kind": "LinkedField",
                            "name": "userAuths",
                            "plural": true,
                            "selections": [
                              {
                                "alias": null,
                                "args": null,
                                "kind": "ScalarField",
                                "name": "service",
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
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "c773f83b16cba20660ddfcac818c6225",
    "id": null,
    "metadata": {},
    "name": "PackageViewer_createChainMutation",
    "operationKind": "mutation",
    "text": "mutation PackageViewer_createChainMutation(\n  $input: OneGraphCreateChainInput!\n) {\n  oneGraph {\n    createChain(input: $input) {\n      chain {\n        id\n        ...ChainViewer_chain\n        ...ChainEditor_chain\n      }\n      package {\n        id\n        ...PackageViewer_package\n      }\n    }\n  }\n}\n\nfragment ActionForm_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  actionVariables: variables {\n    id\n    name\n    graphqlType\n  }\n}\n\nfragment ActionGraphQLEditor_chainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  graphqlOperation\n  services\n}\n\nfragment ActionInspector_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  upstreamActionIds\n  graphqlOperation\n  actionVariables: variables {\n    id\n    name\n    ...VariableInspector_oneGraphStudioChainActionVariable\n  }\n  ...ActionForm_oneGraphStudioChainAction\n}\n\nfragment ChainCanvas_chain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    description\n    graphqlOperation\n    graphqlOperationKind\n    upstreamActionIds\n    ...NodeLabel_action\n  }\n}\n\nfragment ChainEditor_chain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    id\n    filename\n    language\n    concurrentSource\n    textualSource\n    ...ScriptEditor_source\n  }\n  createdAt\n  updatedAt\n  actions {\n    id\n    name\n    description\n    graphqlOperation\n    graphqlOperationKind\n    privacy\n    upstreamActionIds\n    services\n    script {\n      id\n      filename\n      language\n      concurrentSource\n      textualSource\n      ...ScriptEditor_source\n    }\n    ...ActionGraphQLEditor_chainAction\n  }\n  ...ChainCanvas_chain\n  ...Inspector_chain\n  ...ConnectionVisualizer_chainActions\n  ...Compiler_chain\n}\n\nfragment ChainInspector_packageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n    ...ActionInspector_oneGraphStudioChainAction\n  }\n  ...InspectorOverview_oneGraphAppPackageChain\n}\n\nfragment ChainViewer_chain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    filename\n    language\n    concurrentSource\n    textualSource\n  }\n  createdAt\n  updatedAt\n  actions {\n    id\n    name\n    description\n    graphqlOperation\n    privacy\n    script {\n      filename\n      language\n      concurrentSource\n      textualSource\n    }\n  }\n}\n\nfragment Compiler_chain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    id\n    filename\n    language\n    textualSource\n  }\n  actions {\n    id\n    name\n    graphqlOperationKind\n    graphqlOperation\n    script {\n      id\n      filename\n      language\n      textualSource\n    }\n    actionVariables: variables {\n      id\n      name\n      computeMethod: method\n      graphqlType\n    }\n  }\n}\n\nfragment ComputedVariableInspector_chainActionVariable on OneGraphStudioChainActionVariable {\n  id\n}\n\nfragment ConnectionVisualizer_chainActions on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    upstreamActionIds\n    actionVariables: variables {\n      id\n      name\n      graphqlType\n    }\n  }\n}\n\nfragment InspectorOverview_oneGraphAppPackageChain on OneGraphAppPackageChain {\n  id\n  description\n  actions {\n    id\n    name\n    upstreamActionIds\n    actionVariables: variables {\n      ...VariableInspector_oneGraphStudioChainActionVariable\n    }\n  }\n}\n\nfragment Inspector_SubInspector_packageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n    ...ActionInspector_oneGraphStudioChainAction\n  }\n}\n\nfragment Inspector_chain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n  }\n  ...Inspector_SubInspector_packageChain\n  ...ChainInspector_packageChain\n}\n\nfragment NodeLabel_action on OneGraphStudioChainAction {\n  id\n  name\n  services\n}\n\nfragment PackageViewer_package on OneGraphAppPackage {\n  description\n  id\n  name\n  version\n  chains {\n    ...ChainViewer_chain\n    ...ChainEditor_chain\n    id\n    name\n    authToken {\n      obscuredToken\n      name\n      userAuths {\n        service\n      }\n    }\n  }\n}\n\nfragment ScriptEditor_source on OneGraphSourceFile {\n  id\n  filename\n  language\n  concurrentSource\n  textualSource\n}\n\nfragment VariableInspector_oneGraphStudioChainActionVariable on OneGraphStudioChainActionVariable {\n  id\n  name\n  graphqlType\n  description\n  ifList\n  ifMissing\n  maxRecur\n  computeMethod: method\n  probePath\n  ...ComputedVariableInspector_chainActionVariable\n}\n"
  }
};
})() `)


