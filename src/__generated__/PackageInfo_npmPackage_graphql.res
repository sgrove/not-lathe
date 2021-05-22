/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec fragment_downloads = {
    lastMonth: option<fragment_downloads_lastMonth>,
  }
   and fragment_downloads_lastMonth = {
    downloadCount: int,
  }
  
  
  type fragment = {
    name: option<string>,
    description: option<string>,
    id: option<string>,
    downloads: fragment_downloads,
  }
}

module Internal = {
  type fragmentRaw
  let fragmentConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"name":{"n":""},"id":{"n":""},"description":{"n":""},"downloads_lastMonth":{"n":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #PackageInfo_npmPackage]> => fragmentRef = "%identity"


module Utils = {

}
type relayOperationNode
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


let node: operationType = %raw(json` {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "PackageInfo_npmPackage",
  "selections": [
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
      "name": "id",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "NpmPackageDownloadData",
      "kind": "LinkedField",
      "name": "downloads",
      "plural": false,
      "selections": [
        {
          "alias": null,
          "args": null,
          "concreteType": "NpmPackageDownloadPeriodData",
          "kind": "LinkedField",
          "name": "lastMonth",
          "plural": false,
          "selections": [
            {
              "alias": "downloadCount",
              "args": null,
              "kind": "ScalarField",
              "name": "count",
              "storageKey": null
            }
          ],
          "storageKey": null
        }
      ],
      "storageKey": null
    }
  ],
  "type": "NpmPackage",
  "abstractKey": null
} `)


