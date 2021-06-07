/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type enum_OneGraphStudioChainActionVariableMethodEnum = private [>
    | #COMPUTED
    | #DIRECT
    ]
  
  type enum_OneGraphStudioChainActionVariableMethodEnum_input = [
    | #COMPUTED
    | #DIRECT
    ]
  
  type enum_OneGraphSourceLanguageEnum = private [>
    | #TYPESCRIPT
    ]
  
  type enum_OneGraphSourceLanguageEnum_input = [
    | #TYPESCRIPT
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
    textualSource: option<string>,
  }
   and fragment_actions = {
    id: string,
    name: string,
    graphqlOperationKind: enum_OneGraphStudioChainActionOperationKindEnum,
    graphqlOperation: string,
    script: fragment_actions_script,
    actionVariables: array<fragment_actions_actionVariables>,
  }
   and fragment_actions_script = {
    id: string,
    filename: string,
    language: enum_OneGraphSourceLanguageEnum,
    textualSource: option<string>,
  }
   and fragment_actions_actionVariables = {
    id: string,
    name: string,
    computeMethod: enum_OneGraphStudioChainActionVariableMethodEnum,
    graphqlType: string,
  }
  
  
  type fragment = {
    id: string,
    name: string,
    description: option<string>,
    libraryScript: fragment_libraryScript,
    actions: array<fragment_actions>,
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"actions_script_textualSource":{"n":""},"description":{"n":""},"libraryScript_textualSource":{"n":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #Compiler_chain]> => fragmentRef = "%identity"


module Utils = {
  @@ocaml.warning("-33")
  open Types
  external oneGraphStudioChainActionVariableMethodEnum_toString:
  enum_OneGraphStudioChainActionVariableMethodEnum => string = "%identity"
  external oneGraphStudioChainActionVariableMethodEnum_input_toString:
  enum_OneGraphStudioChainActionVariableMethodEnum_input => string = "%identity"
  external oneGraphSourceLanguageEnum_toString:
  enum_OneGraphSourceLanguageEnum => string = "%identity"
  external oneGraphSourceLanguageEnum_input_toString:
  enum_OneGraphSourceLanguageEnum_input => string = "%identity"
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
v2 = [
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
    "name": "textualSource",
    "storageKey": null
  }
];
return {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "Compiler_chain",
  "selections": [
    (v0/*: any*/),
    (v1/*: any*/),
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "description",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "OneGraphSourceFile",
      "kind": "LinkedField",
      "name": "libraryScript",
      "plural": false,
      "selections": (v2/*: any*/),
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
          "name": "graphqlOperation",
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "OneGraphSourceFile",
          "kind": "LinkedField",
          "name": "script",
          "plural": false,
          "selections": (v2/*: any*/),
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
            (v0/*: any*/),
            (v1/*: any*/),
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
              "name": "graphqlType",
              "storageKey": null
            }
          ],
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


