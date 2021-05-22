/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec response_npm = {
    package: option<response_npm_package>,
  }
   and response_npm_package = {
    downloads: response_npm_package_downloads,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PackageInfo_npmPackage]>
  }
   and response_npm_package_downloads = {
    lastMonth: option<response_npm_package_downloads_lastMonth>,
  }
   and response_npm_package_downloads_lastMonth = {
    count: int,
  }
  
  
  type response = {
    npm: response_npm,
  }
  type rawResponse = response
  type refetchVariables = {
    name: option<string>,
  }
  let makeRefetchVariables = (
    ~name=?,
    ()
  ): refetchVariables => {
    name: name
  }
  
  type variables = {
    name: option<string>,
  }
}

module Internal = {
  type wrapResponseRaw
  let wrapResponseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"npm_package_downloads_lastMonth":{"n":""},"npm_package":{"f":"","n":""}}}`
    )
  
  let wrapResponseConverterMap = ()
  let convertWrapResponse = v => v->RescriptRelay.convertObj(
    wrapResponseConverter, 
    wrapResponseConverterMap, 
    Js.null
  )
  type responseRaw
  let responseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"npm_package_downloads_lastMonth":{"n":""},"npm_package":{"f":"","n":""}}}`
    )
  
  let responseConverterMap = ()
  let convertResponse = v => v->RescriptRelay.convertObj(
    responseConverter, 
    responseConverterMap, 
    Js.undefined
  )
  type wrapRawResponseRaw = wrapResponseRaw
  let convertWrapRawResponse = convertWrapResponse
  type rawResponseRaw = responseRaw
  let convertRawResponse = convertResponse
  let variablesConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"name":{"n":""}}}`
    )
  
  let variablesConverterMap = ()
  let convertVariables = v => v->RescriptRelay.convertObj(
    variablesConverter, 
    variablesConverterMap, 
    Js.undefined
  )
}

type queryRef

module Utils = {
  @@ocaml.warning("-33")
  open Types
  let makeVariables = (
    ~name=?,
    ()
  ): variables => {
    name: name
  }
}
type relayOperationNode
type operationType = RescriptRelay.queryNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": "graphql",
    "kind": "LocalArgument",
    "name": "name"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "name",
    "variableName": "name"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "count",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "RelayTestQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "NpmQuery",
        "kind": "LinkedField",
        "name": "npm",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": (v1/*: any*/),
            "concreteType": "NpmPackage",
            "kind": "LinkedField",
            "name": "package",
            "plural": false,
            "selections": [
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
                      (v2/*: any*/)
                    ],
                    "storageKey": null
                  }
                ],
                "storageKey": null
              },
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "PackageInfo_npmPackage"
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "RelayTestQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "NpmQuery",
        "kind": "LinkedField",
        "name": "npm",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": (v1/*: any*/),
            "concreteType": "NpmPackage",
            "kind": "LinkedField",
            "name": "package",
            "plural": false,
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
                      },
                      (v2/*: any*/)
                    ],
                    "storageKey": null
                  }
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "6d7912ac0841d350012d02b04a7a978b",
    "id": null,
    "metadata": {},
    "name": "RelayTestQuery",
    "operationKind": "query",
    "text": "query RelayTestQuery(\n  $name: String = \"graphql\"\n) {\n  npm {\n    package(name: $name) {\n      ...PackageInfo_npmPackage\n      downloads {\n        lastMonth {\n          count\n        }\n      }\n    }\n  }\n}\n\nfragment PackageInfo_npmPackage on NpmPackage {\n  name\n  description\n  id\n  downloads {\n    lastMonth {\n      downloadCount: count\n    }\n  }\n}\n"
  }
};
})() `)

include RescriptRelay.MakeLoadQuery({
    type variables = Types.variables
    type loadedQueryRef = queryRef
    type response = Types.response
    type node = relayOperationNode
    let query = node
    let convertVariables = Internal.convertVariables
  });
