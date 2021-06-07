/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
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
  
  type rec fragment_actions = {
    id: string,
    name: string,
    graphqlOperationKind: enum_OneGraphStudioChainActionOperationKindEnum,
  }
  type fragment = {
    id: string,
    actions: array<fragment_actions>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #Inspector_SubInspector_packageChain | #ChainInspector_packageChain]>
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"":{"f":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #Inspector_chain]> => fragmentRef = "%identity"


module Utils = {
  @@ocaml.warning("-33")
  open Types
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
};
return {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "Inspector_chain",
  "selections": [
    (v0/*: any*/),
    {
      "alias": null,
      "args": null,
      "concreteType": "OneGraphStudioChainAction",
      "kind": "LinkedField",
      "name": "actions",
      "plural": true,
      "selections": [
        (v0/*: any*/),
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "name",
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "graphqlOperationKind",
          "storageKey": null
        }
      ],
      "storageKey": null
    },
    {
      "args": null,
      "kind": "FragmentSpread",
      "name": "Inspector_SubInspector_packageChain"
    },
    {
      "args": null,
      "kind": "FragmentSpread",
      "name": "ChainInspector_packageChain"
    }
  ],
  "type": "OneGraphAppPackageChain",
  "abstractKey": null
};
})() `)


