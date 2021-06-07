/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec response_oneGraph = {
    app: response_oneGraph_app,
  }
   and response_oneGraph_app = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PackageList_oneGraphApp]>
  }
   and response_me = {
    oneGraph: option<response_me_oneGraph>,
  }
   and response_me_oneGraph = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PackageViewer_authTokens]>
  }
  
  
  type response = {
    oneGraph: response_oneGraph,
    me: response_me,
  }
  type rawResponse = response
  type refetchVariables = {
    appId: option<string>,
  }
  let makeRefetchVariables = (
    ~appId=?,
    ()
  ): refetchVariables => {
    appId: appId
  }
  
  type variables = {
    appId: string,
  }
}

module Internal = {
  type wrapResponseRaw
  let wrapResponseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"oneGraph_app":{"f":""},"me_oneGraph":{"f":"","n":""}}}`
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
      json`{"__root":{"oneGraph_app":{"f":""},"me_oneGraph":{"f":"","n":""}}}`
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
      json`{}`
    )
  
  let variablesConverterMap = ()
  let convertVariables = v => v->RescriptRelay.convertObj(
    variablesConverter, 
    variablesConverterMap, 
    Js.undefined
  )
}

type queryRef

module Utils = {
  @@ocaml.warning("-33")
  open Types
  let makeVariables = (
    ~appId
  ): variables => {
    appId: appId
  }
}
type relayOperationNode
type operationType = RescriptRelay.queryNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "appId"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "appId"
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
  "name": "description",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
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
  "kind": "ScalarField",
  "name": "obscuredToken",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "StudioQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "OneGraphServiceQuery",
        "kind": "LinkedField",
        "name": "oneGraph",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": (v1/*: any*/),
            "concreteType": "OneGraphApp",
            "kind": "LinkedField",
            "name": "app",
            "plural": false,
            "selections": [
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "PackageList_oneGraphApp"
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "Viewer",
        "kind": "LinkedField",
        "name": "me",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "OneGraphUser",
            "kind": "LinkedField",
            "name": "oneGraph",
            "plural": false,
            "selections": [
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "PackageViewer_authTokens"
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "StudioQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "OneGraphServiceQuery",
        "kind": "LinkedField",
        "name": "oneGraph",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": (v1/*: any*/),
            "concreteType": "OneGraphApp",
            "kind": "LinkedField",
            "name": "app",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphAppPackage",
                "kind": "LinkedField",
                "name": "packages",
                "plural": true,
                "selections": [
                  (v2/*: any*/),
                  (v3/*: any*/),
                  (v4/*: any*/),
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
                      (v4/*: any*/),
                      (v3/*: any*/),
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
                          (v4/*: any*/),
                          (v3/*: any*/),
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
                              (v4/*: any*/),
                              {
                                "alias": null,
                                "args": null,
                                "kind": "ScalarField",
                                "name": "graphqlType",
                                "storageKey": null
                              },
                              (v3/*: any*/),
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
                      },
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "OneGraphAccessToken",
                        "kind": "LinkedField",
                        "name": "authToken",
                        "plural": false,
                        "selections": [
                          (v6/*: any*/),
                          (v4/*: any*/),
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
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "Viewer",
        "kind": "LinkedField",
        "name": "me",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "OneGraphUser",
            "kind": "LinkedField",
            "name": "oneGraph",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphAccessToken",
                "kind": "LinkedField",
                "name": "personalTokens",
                "plural": true,
                "selections": [
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "token",
                    "storageKey": null
                  },
                  (v6/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "expireDate",
                    "storageKey": null
                  },
                  (v4/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "appId",
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
    "cacheID": "8a684ac85ef03a19ae1f5a21ba875f6f",
    "id": null,
    "metadata": {},
    "name": "StudioQuery",
    "operationKind": "query",
    "text": "query StudioQuery(\n  $appId: String!\n) {\n  oneGraph {\n    app(id: $appId) {\n      ...PackageList_oneGraphApp\n    }\n  }\n  me {\n    oneGraph {\n      ...PackageViewer_authTokens\n    }\n  }\n}\n\nfragment ActionForm_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  actionVariables: variables {\n    id\n    name\n    graphqlType\n  }\n}\n\nfragment ActionGraphQLEditor_chainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  graphqlOperation\n  services\n}\n\nfragment ActionInspector_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  upstreamActionIds\n  graphqlOperation\n  actionVariables: variables {\n    id\n    name\n    ...VariableInspector_oneGraphStudioChainActionVariable\n  }\n  ...ActionForm_oneGraphStudioChainAction\n}\n\nfragment ChainCanvas_chain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    description\n    graphqlOperation\n    graphqlOperationKind\n    upstreamActionIds\n    ...NodeLabel_action\n  }\n}\n\nfragment ChainEditor_chain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    id\n    filename\n    language\n    concurrentSource\n    textualSource\n    ...ScriptEditor_source\n  }\n  createdAt\n  updatedAt\n  actions {\n    id\n    name\n    description\n    graphqlOperation\n    graphqlOperationKind\n    privacy\n    upstreamActionIds\n    services\n    script {\n      id\n      filename\n      language\n      concurrentSource\n      textualSource\n      ...ScriptEditor_source\n    }\n    ...ActionGraphQLEditor_chainAction\n  }\n  ...ChainCanvas_chain\n  ...Inspector_chain\n  ...ConnectionVisualizer_chainActions\n  ...Compiler_chain\n}\n\nfragment ChainInspector_packageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n    ...ActionInspector_oneGraphStudioChainAction\n  }\n  ...InspectorOverview_oneGraphAppPackageChain\n}\n\nfragment ChainViewer_chain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    filename\n    language\n    concurrentSource\n    textualSource\n  }\n  createdAt\n  updatedAt\n  actions {\n    id\n    name\n    description\n    graphqlOperation\n    privacy\n    script {\n      filename\n      language\n      concurrentSource\n      textualSource\n    }\n  }\n}\n\nfragment Compiler_chain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    id\n    filename\n    language\n    textualSource\n  }\n  actions {\n    id\n    name\n    graphqlOperationKind\n    graphqlOperation\n    script {\n      id\n      filename\n      language\n      textualSource\n    }\n    actionVariables: variables {\n      id\n      name\n      computeMethod: method\n      graphqlType\n    }\n  }\n}\n\nfragment ComputedVariableInspector_chainActionVariable on OneGraphStudioChainActionVariable {\n  id\n}\n\nfragment ConnectionVisualizer_chainActions on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    upstreamActionIds\n    actionVariables: variables {\n      id\n      name\n      graphqlType\n    }\n  }\n}\n\nfragment InspectorOverview_oneGraphAppPackageChain on OneGraphAppPackageChain {\n  id\n  description\n  actions {\n    id\n    name\n    upstreamActionIds\n    actionVariables: variables {\n      ...VariableInspector_oneGraphStudioChainActionVariable\n    }\n  }\n}\n\nfragment Inspector_SubInspector_packageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n    ...ActionInspector_oneGraphStudioChainAction\n  }\n}\n\nfragment Inspector_chain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphqlOperationKind\n  }\n  ...Inspector_SubInspector_packageChain\n  ...ChainInspector_packageChain\n}\n\nfragment NodeLabel_action on OneGraphStudioChainAction {\n  id\n  name\n  services\n}\n\nfragment PackageList_oneGraphApp on OneGraphApp {\n  packages {\n    id\n    ...PackageViewer_package\n  }\n}\n\nfragment PackageViewer_authTokens on OneGraphUser {\n  personalTokens {\n    token\n    obscuredToken\n    expireDate\n    name\n    appId\n  }\n}\n\nfragment PackageViewer_package on OneGraphAppPackage {\n  description\n  id\n  name\n  version\n  chains {\n    ...ChainViewer_chain\n    ...ChainEditor_chain\n    id\n    name\n    authToken {\n      obscuredToken\n      name\n      userAuths {\n        service\n      }\n    }\n  }\n}\n\nfragment ScriptEditor_source on OneGraphSourceFile {\n  id\n  filename\n  language\n  concurrentSource\n  textualSource\n}\n\nfragment VariableInspector_oneGraphStudioChainActionVariable on OneGraphStudioChainActionVariable {\n  id\n  name\n  graphqlType\n  description\n  ifList\n  ifMissing\n  maxRecur\n  computeMethod: method\n  probePath\n  ...ComputedVariableInspector_chainActionVariable\n}\n"
  }
};
})() `)

include RescriptRelay.MakeLoadQuery({
    type variables = Types.variables
    type loadedQueryRef = queryRef
    type response = Types.response
    type node = relayOperationNode
    let query = node
    let convertVariables = Internal.convertVariables
  });
