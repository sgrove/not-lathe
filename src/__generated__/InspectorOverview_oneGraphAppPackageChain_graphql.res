/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec fragment_actions = {
    id: string,
    name: string,
    upstreamActionIds: array<string>,
    actionVariables: array<fragment_actions_actionVariables>,
  }
   and fragment_actions_actionVariables = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #VariableInspector_oneGraphStudioChainActionVariable]>
  }
  
  
  type fragment = {
    id: string,
    description: option<string>,
    actions: array<fragment_actions>,
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"actions_actionVariables":{"f":""},"description":{"n":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #InspectorOverview_oneGraphAppPackageChain]> => fragmentRef = "%identity"


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
  "name": "InspectorOverview_oneGraphAppPackageChain",
  "selections": [
    (v0/*: any*/),
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
          "name": "upstreamActionIds",
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
            {
              "args": null,
              "kind": "FragmentSpread",
              "name": "VariableInspector_oneGraphStudioChainActionVariable"
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


