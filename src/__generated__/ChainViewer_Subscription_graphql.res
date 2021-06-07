/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type enum_OneGraphSourceLanguageEnum = private [>
    | #TYPESCRIPT
    ]
  
  type enum_OneGraphSourceLanguageEnum_input = [
    | #TYPESCRIPT
    ]
  
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
    studioChainUpdate: response_oneGraph_studioChainUpdate,
  }
   and response_oneGraph_studioChainUpdate = {
    chain: response_oneGraph_studioChainUpdate_chain,
  }
   and response_oneGraph_studioChainUpdate_chain = {
    name: string,
    description: option<string>,
    libraryScript: response_oneGraph_studioChainUpdate_chain_libraryScript,
    createdAt: string,
    updatedAt: string,
    actions: array<response_oneGraph_studioChainUpdate_chain_actions>,
  }
   and response_oneGraph_studioChainUpdate_chain_libraryScript = {
    filename: string,
    language: enum_OneGraphSourceLanguageEnum,
    concurrentSource: option<string>,
    textualSource: option<string>,
  }
   and response_oneGraph_studioChainUpdate_chain_actions = {
    id: string,
    name: string,
    description: option<string>,
    graphqlOperation: string,
    privacy: enum_OneGraphGraphQLBlockPrivacyEnum,
    script: response_oneGraph_studioChainUpdate_chain_actions_script,
  }
   and response_oneGraph_studioChainUpdate_chain_actions_script = {
    filename: string,
    language: enum_OneGraphSourceLanguageEnum,
    concurrentSource: option<string>,
    textualSource: option<string>,
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
      json`{"__root":{"oneGraph_studioChainUpdate_chain_actions_description":{"n":""},"oneGraph_studioChainUpdate_chain_libraryScript_textualSource":{"n":""},"oneGraph_studioChainUpdate_chain_actions_script_concurrentSource":{"n":""},"oneGraph_studioChainUpdate_chain_libraryScript_concurrentSource":{"n":""},"oneGraph_studioChainUpdate_chain_actions_script_textualSource":{"n":""},"oneGraph_studioChainUpdate_chain_description":{"n":""}}}`
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
  external oneGraphSourceLanguageEnum_toString:
  enum_OneGraphSourceLanguageEnum => string = "%identity"
  external oneGraphSourceLanguageEnum_input_toString:
  enum_OneGraphSourceLanguageEnum_input => string = "%identity"
  external oneGraphGraphQLBlockPrivacyEnum_toString:
  enum_OneGraphGraphQLBlockPrivacyEnum => string = "%identity"
  external oneGraphGraphQLBlockPrivacyEnum_input_toString:
  enum_OneGraphGraphQLBlockPrivacyEnum_input => string = "%identity"
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
v1 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "description",
  "storageKey": null
},
v3 = [
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
],
v4 = [
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
        "args": [
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
              (v1/*: any*/),
              (v2/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphSourceFile",
                "kind": "LinkedField",
                "name": "libraryScript",
                "plural": false,
                "selections": (v3/*: any*/),
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
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "id",
                    "storageKey": null
                  },
                  (v1/*: any*/),
                  (v2/*: any*/),
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
                    "selections": (v3/*: any*/),
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
];
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "ChainViewer_Subscription",
    "selections": (v4/*: any*/),
    "type": "Subscription",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ChainViewer_Subscription",
    "selections": (v4/*: any*/)
  },
  "params": {
    "cacheID": "49eb48920dfe80e12068059da31e7583",
    "id": null,
    "metadata": {},
    "name": "ChainViewer_Subscription",
    "operationKind": "subscription",
    "text": "subscription ChainViewer_Subscription(\n  $chainId: String!\n) {\n  oneGraph {\n    studioChainUpdate(input: {chainId: $chainId}) {\n      chain {\n        name\n        description\n        libraryScript {\n          filename\n          language\n          concurrentSource\n          textualSource\n        }\n        createdAt\n        updatedAt\n        actions {\n          id\n          name\n          description\n          graphqlOperation\n          privacy\n          script {\n            filename\n            language\n            concurrentSource\n            textualSource\n          }\n        }\n      }\n    }\n  }\n}\n"
  }
};
})() `)


