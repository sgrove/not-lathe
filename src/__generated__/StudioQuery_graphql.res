/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type enum_OneGraphGraphQLBlockPrivacyEnum = private [>
    | #APP
    | #HIDDEN
    | #PUBLIC
    ]
  
  type enum_OneGraphGraphQLBlockPrivacyEnum_input = [
    | #APP
    | #HIDDEN
    | #PUBLIC
    ]
  
  type rec response_oneGraph = {
    app: response_oneGraph_app,
    studio: response_oneGraph_studio,
  }
   and response_oneGraph_app = {
    id: string,
    name: string,
    description: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PackageList_oneGraphApp]>
  }
   and response_oneGraph_studio = {
    actions: array<response_oneGraph_studio_actions>,
  }
   and response_oneGraph_studio_actions = {
    id: string,
    name: string,
    description: option<string>,
    graphQLOperation: string,
    privacy: enum_OneGraphGraphQLBlockPrivacyEnum,
  }
   and response_me = {
    oneGraph: option<response_me_oneGraph>,
  }
   and response_me_oneGraph = {
    personalTokens: option<array<response_me_oneGraph_personalTokens>>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PackageViewer_authTokens]>
  }
   and response_me_oneGraph_personalTokens = {
    obscuredToken: string,
    expireDate: int,
    name: option<string>,
    appId: string,
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
      json`{"__root":{"me_oneGraph_personalTokens":{"n":""},"oneGraph_studio_actions_description":{"n":""},"oneGraph_app":{"f":""},"me_oneGraph_personalTokens_name":{"n":""},"me_oneGraph":{"f":"","n":""}}}`
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
      json`{"__root":{"me_oneGraph_personalTokens":{"n":""},"oneGraph_studio_actions_description":{"n":""},"oneGraph_app":{"f":""},"me_oneGraph_personalTokens_name":{"n":""},"me_oneGraph":{"f":"","n":""}}}`
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
  external oneGraphGraphQLBlockPrivacyEnum_toString:
  enum_OneGraphGraphQLBlockPrivacyEnum => string = "%identity"
  external oneGraphGraphQLBlockPrivacyEnum_input_toString:
  enum_OneGraphGraphQLBlockPrivacyEnum_input => string = "%identity"
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
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "graphQLOperation",
  "storageKey": null
},
v6 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "privacy",
  "storageKey": null
},
v7 = {
  "alias": null,
  "args": null,
  "concreteType": "OneGraphStudio",
  "kind": "LinkedField",
  "name": "studio",
  "plural": false,
  "selections": [
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
        (v5/*: any*/),
        (v6/*: any*/)
      ],
      "storageKey": null
    }
  ],
  "storageKey": null
},
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "obscuredToken",
  "storageKey": null
},
v9 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "expireDate",
  "storageKey": null
},
v10 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "appId",
  "storageKey": null
},
v11 = [
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
];
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
              (v2/*: any*/),
              (v3/*: any*/),
              (v4/*: any*/),
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "PackageList_oneGraphApp"
              }
            ],
            "storageKey": null
          },
          (v7/*: any*/)
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
                  (v8/*: any*/),
                  (v9/*: any*/),
                  (v3/*: any*/),
                  (v10/*: any*/)
                ],
                "storageKey": null
              },
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
              (v2/*: any*/),
              (v3/*: any*/),
              (v4/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphAppPackage",
                "kind": "LinkedField",
                "name": "packages",
                "plural": true,
                "selections": [
                  (v4/*: any*/),
                  (v2/*: any*/),
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
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "OneGraphSourceFile",
                        "kind": "LinkedField",
                        "name": "libraryScript",
                        "plural": false,
                        "selections": (v11/*: any*/),
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
                          (v5/*: any*/),
                          (v6/*: any*/),
                          {
                            "alias": null,
                            "args": null,
                            "concreteType": "OneGraphSourceFile",
                            "kind": "LinkedField",
                            "name": "script",
                            "plural": false,
                            "selections": (v11/*: any*/),
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
                            "kind": "ScalarField",
                            "name": "upstreamActionIds",
                            "storageKey": null
                          },
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "graphQLOperationKind",
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
                      },
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "OneGraphAccessToken",
                        "kind": "LinkedField",
                        "name": "authToken",
                        "plural": false,
                        "selections": [
                          (v8/*: any*/),
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
          },
          (v7/*: any*/)
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
                  (v8/*: any*/),
                  (v9/*: any*/),
                  (v3/*: any*/),
                  (v10/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "token",
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
    "cacheID": "feb1ba1a48eba6c6b8c785c1d6700920",
    "id": null,
    "metadata": {},
    "name": "StudioQuery",
    "operationKind": "query",
    "text": "query StudioQuery(\n  $appId: String!\n) {\n  oneGraph {\n    app(id: $appId) {\n      id\n      name\n      description\n      ...PackageList_oneGraphApp\n    }\n    studio {\n      actions {\n        id\n        name\n        description\n        graphQLOperation\n        privacy\n      }\n    }\n  }\n  me {\n    oneGraph {\n      personalTokens {\n        obscuredToken\n        expireDate\n        name\n        appId\n      }\n      ...PackageViewer_authTokens\n    }\n  }\n}\n\nfragment ActionGraphQLEditor_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  graphQLOperation\n  services\n}\n\nfragment ActionInspector_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  description\n  upstreamActionIds\n  graphQLOperation\n  actionVariables: variables {\n    ...VariableInspector_oneGraphStudioChainActionVariable\n  }\n}\n\nfragment ChainCanvas_oneGraphAppPackageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    description\n    graphQLOperation\n    upstreamActionIds\n    ...NodeLabel_oneGraphStudioChainAction\n  }\n}\n\nfragment ChainEditor_oneGraphAppPackageChain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    id\n    filename\n    language\n    concurrentSource\n    textualSource\n    ...ScriptEditor_source\n  }\n  createdAt\n  updatedAt\n  actions {\n    id\n    name\n    description\n    graphQLOperation\n    privacy\n    script {\n      id\n      filename\n      language\n      concurrentSource\n      textualSource\n      ...ScriptEditor_source\n    }\n    ...ActionGraphQLEditor_oneGraphStudioChainAction\n  }\n  ...ChainCanvas_oneGraphAppPackageChain\n  ...Inspector_oneGraphAppPackageChain\n}\n\nfragment ChainInspector_packageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphQLOperationKind\n    ...ActionInspector_oneGraphStudioChainAction\n  }\n  ...InspectorOverview_oneGraphAppPackageChain\n}\n\nfragment ChainViewer_oneGraphAppPackageChain on OneGraphAppPackageChain {\n  id\n  name\n  description\n  libraryScript {\n    filename\n    language\n    concurrentSource\n    textualSource\n  }\n  createdAt\n  updatedAt\n  actions {\n    id\n    name\n    description\n    graphQLOperation\n    privacy\n    script {\n      filename\n      language\n      concurrentSource\n      textualSource\n    }\n  }\n}\n\nfragment ComputedVariableInspector_oneGraphAppPackageChainActionVariable on OneGraphStudioChainActionVariable {\n  id\n}\n\nfragment InspectorOverview_oneGraphAppPackageChain on OneGraphAppPackageChain {\n  id\n  description\n  actions {\n    id\n    name\n    upstreamActionIds\n    actionVariables: variables {\n      ...VariableInspector_oneGraphStudioChainActionVariable\n    }\n  }\n}\n\nfragment Inspector_SubInspector_packageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphQLOperationKind\n    ...ActionInspector_oneGraphStudioChainAction\n  }\n}\n\nfragment Inspector_oneGraphAppPackageChain on OneGraphAppPackageChain {\n  id\n  actions {\n    id\n    name\n    graphQLOperationKind\n  }\n  ...Inspector_SubInspector_packageChain\n  ...ChainInspector_packageChain\n}\n\nfragment NodeLabel_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  services\n}\n\nfragment PackageList_oneGraphApp on OneGraphApp {\n  packages {\n    ...PackageViewer_oneGraphAppPackage\n  }\n}\n\nfragment PackageViewer_authTokens on OneGraphUser {\n  personalTokens {\n    token\n    obscuredToken\n    expireDate\n    name\n    appId\n  }\n}\n\nfragment PackageViewer_oneGraphAppPackage on OneGraphAppPackage {\n  description\n  id\n  name\n  version\n  chains {\n    ...ChainViewer_oneGraphAppPackageChain\n    ...ChainEditor_oneGraphAppPackageChain\n    id\n    name\n    authToken {\n      obscuredToken\n      name\n      userAuths {\n        service\n      }\n    }\n  }\n}\n\nfragment ScriptEditor_source on OneGraphSourceFile {\n  id\n  filename\n  language\n  concurrentSource\n  textualSource\n}\n\nfragment VariableInspector_oneGraphStudioChainActionVariable on OneGraphStudioChainActionVariable {\n  id\n  name\n  graphqlType\n  description\n  ifList\n  ifMissing\n  maxRecur\n  computeMethod: method\n  probePath\n  ...ComputedVariableInspector_oneGraphAppPackageChainActionVariable\n}\n"
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
