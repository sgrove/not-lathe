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
  
  type enum_OneGraphStudioChainActionVariableIfMissingEnum = private [>
    | #ALLOW
    | #ERROR
    | #SKIP
    ]
  
  type enum_OneGraphStudioChainActionVariableIfMissingEnum_input = [
    | #ALLOW
    | #ERROR
    | #SKIP
    ]
  
  type enum_OneGraphStudioChainActionVariableIfListEnum = private [>
    | #ALL
    | #EACH
    | #FIRST
    | #LAST
    ]
  
  type enum_OneGraphStudioChainActionVariableIfListEnum_input = [
    | #ALL
    | #EACH
    | #FIRST
    | #LAST
    ]
  
  type fragment = {
    id: string,
    name: string,
    graphqlType: string,
    description: option<string>,
    ifList: enum_OneGraphStudioChainActionVariableIfListEnum,
    ifMissing: enum_OneGraphStudioChainActionVariableIfMissingEnum,
    maxRecur: int,
    computeMethod: enum_OneGraphStudioChainActionVariableMethodEnum,
    probePath: array<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ComputedVariableInspector_oneGraphAppPackageChainActionVariable]>
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"":{"f":""},"description":{"n":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #VariableInspector_oneGraphStudioChainActionVariable]> => fragmentRef = "%identity"


module Utils = {
  @@ocaml.warning("-33")
  open Types
  external oneGraphStudioChainActionVariableMethodEnum_toString:
  enum_OneGraphStudioChainActionVariableMethodEnum => string = "%identity"
  external oneGraphStudioChainActionVariableMethodEnum_input_toString:
  enum_OneGraphStudioChainActionVariableMethodEnum_input => string = "%identity"
  external oneGraphStudioChainActionVariableIfMissingEnum_toString:
  enum_OneGraphStudioChainActionVariableIfMissingEnum => string = "%identity"
  external oneGraphStudioChainActionVariableIfMissingEnum_input_toString:
  enum_OneGraphStudioChainActionVariableIfMissingEnum_input => string = "%identity"
  external oneGraphStudioChainActionVariableIfListEnum_toString:
  enum_OneGraphStudioChainActionVariableIfListEnum => string = "%identity"
  external oneGraphStudioChainActionVariableIfListEnum_input_toString:
  enum_OneGraphStudioChainActionVariableIfListEnum_input => string = "%identity"
}
type relayOperationNode
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


let node: operationType = %raw(json` {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "VariableInspector_oneGraphStudioChainActionVariable",
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
      "name": "graphqlType",
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
      "name": "ifList",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "ifMissing",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "maxRecur",
      "storageKey": null
    },
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
      "name": "probePath",
      "storageKey": null
    },
    {
      "args": null,
      "kind": "FragmentSpread",
      "name": "ComputedVariableInspector_oneGraphAppPackageChainActionVariable"
    }
  ],
  "type": "OneGraphStudioChainActionVariable",
  "abstractKey": null
} `)


