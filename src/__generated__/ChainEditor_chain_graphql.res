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
  
  type enum_OneGraphStudioChainActionOperationKindEnum = private [>
    | #COMPUTE
    | #FRAGMENT
    | #MUTATION
    | #QUERY
    | #SUBSCRIPTION
    ]
  
  type enum_OneGraphStudioChainActionOperationKindEnum_input = [
    | #COMPUTE
    | #FRAGMENT
    | #MUTATION
    | #QUERY
    | #SUBSCRIPTION
    ]
  
  type rec fragment_libraryScript = {
    id: string,
    filename: string,
    language: enum_OneGraphSourceLanguageEnum,
    concurrentSource: option<string>,
    textualSource: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ScriptEditor_source]>
  }
   and fragment_actions = {
    id: string,
    name: string,
    description: option<string>,
    graphqlOperation: string,
    graphqlOperationKind: enum_OneGraphStudioChainActionOperationKindEnum,
    privacy: enum_OneGraphGraphQLBlockPrivacyEnum,
    upstreamActionIds: array<string>,
    services: array<string>,
    script: fragment_actions_script,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ActionGraphQLEditor_chainAction]>
  }
   and fragment_actions_script = {
    id: string,
    filename: string,
    language: enum_OneGraphSourceLanguageEnum,
    concurrentSource: option<string>,
    textualSource: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ScriptEditor_source]>
  }
  
  
  type fragment = {
    id: string,
    name: string,
    description: option<string>,
    libraryScript: fragment_libraryScript,
    createdAt: string,
    updatedAt: string,
    actions: array<fragment_actions>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ChainCanvas_chain | #Inspector_chain | #ConnectionVisualizer_chainActions | #Compiler_chain]>
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"":{"f":""},"libraryScript":{"f":""},"actions":{"f":""},"actions_description":{"n":""},"actions_script":{"f":""},"actions_script_textualSource":{"n":""},"description":{"n":""},"libraryScript_concurrentSource":{"n":""},"actions_script_concurrentSource":{"n":""},"libraryScript_textualSource":{"n":""}}}`
    )
  
  let fragmentConverterMap = ()
  let convertFragment = v => v->RescriptRelay.convertObj(
    fragmentConverter, 
    fragmentConverterMap, 
    Js.undefined
  )
}
type t
type fragmentRef
external getFragmentRef:
  RescriptRelay.fragmentRefs<[> | #ChainEditor_chain]> => fragmentRef = "%identity"


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
  external oneGraphStudioChainActionOperationKindEnum_toString:
  enum_OneGraphStudioChainActionOperationKindEnum => string = "%identity"
  external oneGraphStudioChainActionOperationKindEnum_input_toString:
  enum_OneGraphStudioChainActionOperationKindEnum_input => string = "%identity"
}
type relayOperationNode
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
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
  (v0/*: any*/),
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
  {
    "args": null,
    "kind": "FragmentSpread",
    "name": "ScriptEditor_source"
  }
];
return {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "ChainEditor_chain",
  "selections": [
    (v0/*: any*/),
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
        (v0/*: any*/),
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
          "selections": (v3/*: any*/),
          "storageKey": null
        },
        {
          "args": null,
          "kind": "FragmentSpread",
          "name": "ActionGraphQLEditor_chainAction"
        }
      ],
      "storageKey": null
    },
    {
      "args": null,
      "kind": "FragmentSpread",
      "name": "ChainCanvas_chain"
    },
    {
      "args": null,
      "kind": "FragmentSpread",
      "name": "Inspector_chain"
    },
    {
      "args": null,
      "kind": "FragmentSpread",
      "name": "ConnectionVisualizer_chainActions"
    },
    {
      "args": null,
      "kind": "FragmentSpread",
      "name": "Compiler_chain"
    }
  ],
  "type": "OneGraphAppPackageChain",
  "abstractKey": null
};
})() `)


