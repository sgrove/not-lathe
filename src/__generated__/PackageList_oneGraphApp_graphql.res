/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec fragment_packages = {
    id: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PackageViewer_package]>
  }
  type fragment = {
    packages: array<fragment_packages>,
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"packages":{"f":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #PackageList_oneGraphApp]> => fragmentRef = "%identity"


module Utils = {

}
type relayOperationNode
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


let node: operationType = %raw(json` {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "PackageList_oneGraphApp",
  "selections": [
    {
      "alias": null,
      "args": null,
      "concreteType": "OneGraphAppPackage",
      "kind": "LinkedField",
      "name": "packages",
      "plural": true,
      "selections": [
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "id",
          "storageKey": null
        },
        {
          "args": null,
          "kind": "FragmentSpread",
          "name": "PackageViewer_package"
        }
      ],
      "storageKey": null
    }
  ],
  "type": "OneGraphApp",
  "abstractKey": null
} `)


