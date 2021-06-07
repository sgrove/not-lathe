/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec fragment_actionVariables = {
    id: string,
    name: string,
    graphqlType: string,
  }
  type fragment = {
    id: string,
    name: string,
    actionVariables: array<fragment_actionVariables>,
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{}`
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
  RescriptRelay.fragmentRefs<[> | #ActionForm_oneGraphStudioChainAction]> => fragmentRef = "%identity"


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
},
v1 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
};
return {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "ActionForm_oneGraphStudioChainAction",
  "selections": [
    (v0/*: any*/),
    (v1/*: any*/),
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
  "type": "OneGraphStudioChainAction",
  "abstractKey": null
};
})() `)


