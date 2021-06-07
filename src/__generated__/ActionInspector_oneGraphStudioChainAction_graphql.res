/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec fragment_actionVariables = {
    id: string,
    name: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #VariableInspector_oneGraphStudioChainActionVariable]>
  }
  type fragment = {
    id: string,
    name: string,
    description: option<string>,
    upstreamActionIds: array<string>,
    graphqlOperation: string,
    actionVariables: array<fragment_actionVariables>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ActionForm_oneGraphStudioChainAction]>
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"":{"f":""},"actionVariables":{"f":""},"description":{"n":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #ActionInspector_oneGraphStudioChainAction]> => fragmentRef = "%identity"


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
  "name": "ActionInspector_oneGraphStudioChainAction",
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
      "kind": "ScalarField",
      "name": "upstreamActionIds",
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
          "args": null,
          "kind": "FragmentSpread",
          "name": "VariableInspector_oneGraphStudioChainActionVariable"
        }
      ],
      "storageKey": null
    },
    {
      "args": null,
      "kind": "FragmentSpread",
      "name": "ActionForm_oneGraphStudioChainAction"
    }
  ],
  "type": "OneGraphStudioChainAction",
  "abstractKey": null
};
})() `)


