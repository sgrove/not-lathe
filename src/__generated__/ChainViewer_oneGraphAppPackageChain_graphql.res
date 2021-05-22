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
  
  type rec fragment_libraryScript = {
    filename: string,
    language: enum_OneGraphSourceLanguageEnum,
    concurrentSource: option<string>,
    textualSource: option<string>,
  }
   and fragment_actions = {
    id: string,
    name: string,
    description: option<string>,
    graphQLOperation: string,
    privacy: enum_OneGraphGraphQLBlockPrivacyEnum,
    script: option<fragment_actions_script>,
  }
   and fragment_actions_script = {
    filename: string,
    language: enum_OneGraphSourceLanguageEnum,
    concurrentSource: option<string>,
    textualSource: option<string>,
  }
  
  
  type fragment = {
    id: string,
    name: string,
    description: option<string>,
    libraryScript: option<fragment_libraryScript>,
    createdAt: string,
    updatedAt: string,
    actions: array<fragment_actions>,
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"libraryScript":{"n":""},"actions_description":{"n":""},"actions_script_textualSource":{"n":""},"actions_script":{"n":""},"description":{"n":""},"libraryScript_concurrentSource":{"n":""},"actions_script_concurrentSource":{"n":""},"libraryScript_textualSource":{"n":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #ChainViewer_oneGraphAppPackageChain]> => fragmentRef = "%identity"


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
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "ChainViewer_oneGraphAppPackageChain",
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
          "name": "graphQLOperation",
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
  "type": "OneGraphAppPackageChain",
  "abstractKey": null
};
})() `)


