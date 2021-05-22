/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec fragment_actions = {
    id: string,
    name: string,
    description: option<string>,
    graphQLOperation: string,
    upstreamActionIds: array<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #NodeLabel_oneGraphStudioChainAction]>
  }
  type fragment = {
    id: string,
    actions: array<fragment_actions>,
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"actions":{"f":""},"actions_description":{"n":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #ChainCanvas_oneGraphAppPackageChain]> => fragmentRef = "%identity"


module Utils = {

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
  "name": "ChainCanvas_oneGraphAppPackageChain",
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
          "name": "description",
          "storageKey": null
        },
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
          "name": "upstreamActionIds",
          "storageKey": null
        },
        {
          "args": null,
          "kind": "FragmentSpread",
          "name": "NodeLabel_oneGraphStudioChainAction"
        }
      ],
      "storageKey": null
    }
  ],
  "type": "OneGraphAppPackageChain",
  "abstractKey": null
};
})() `)


