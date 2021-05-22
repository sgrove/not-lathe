/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec fragment_actionVariables = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #VariableInspector_oneGraphStudioChainActionVariable]>
  }
  type fragment = {
    id: string,
    name: string,
    description: option<string>,
    upstreamActionIds: array<string>,
    graphQLOperation: string,
    actionVariables: array<fragment_actionVariables>,
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"actionVariables":{"f":""},"description":{"n":""}}}`
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


let node: operationType = %raw(json` {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "ActionInspector_oneGraphStudioChainAction",
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "id",
      "storageKey": null
    },
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
      "name": "upstreamActionIds",
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
  "type": "OneGraphStudioChainAction",
  "abstractKey": null
} `)


