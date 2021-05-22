/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec response_npm = {
    allPublishActivity: option<response_npm_allPublishActivity>,
  }
   and response_npm_allPublishActivity = {
    package: response_npm_allPublishActivity_package,
  }
   and response_npm_allPublishActivity_package = {
    __typename: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PackageInfo_npmPackage]>
  }
  
  
  type response = {
    npm: response_npm,
  }
  type rawResponse = response
  type variables = unit
}

module Internal = {
  type responseRaw
  let responseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"npm_allPublishActivity":{"n":""},"npm_allPublishActivity_package":{"f":""}}}`
    )
  
  let responseConverterMap = ()
  let convertResponse = v => v->RescriptRelay.convertObj(
    responseConverter, 
    responseConverterMap, 
    Js.undefined
  )
  type rawResponseRaw = responseRaw
  let convertRawResponse = convertResponse
  let variablesConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{}`
    )
  
  let variablesConverterMap = ()
  let convertVariables = v => v->RescriptRelay.convertObj(
    variablesConverter, 
    variablesConverterMap, 
    Js.undefined
  )
}


module Utils = {

}
type relayOperationNode
type operationType = RescriptRelay.subscriptionNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "PackageActivity2Subscription",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "NpmSubscriptionRoot",
        "kind": "LinkedField",
        "name": "npm",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "NpmNewPackagePublishedSubscriptionPayload",
            "kind": "LinkedField",
            "name": "allPublishActivity",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "NpmPackage",
                "kind": "LinkedField",
                "name": "package",
                "plural": false,
                "selections": [
                  (v0/*: any*/),
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
        "storageKey": null
      }
    ],
    "type": "Subscription",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "PackageActivity2Subscription",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "NpmSubscriptionRoot",
        "kind": "LinkedField",
        "name": "npm",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "NpmNewPackagePublishedSubscriptionPayload",
            "kind": "LinkedField",
            "name": "allPublishActivity",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "NpmPackage",
                "kind": "LinkedField",
                "name": "package",
                "plural": false,
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
    "cacheID": "1afffa95994f8d7b1cf08f189457dd1c",
    "id": null,
    "metadata": {},
    "name": "PackageActivity2Subscription",
    "operationKind": "subscription",
    "text": "subscription PackageActivity2Subscription {\n  npm {\n    allPublishActivity {\n      package {\n        __typename\n        ...PackageInfo_npmPackage\n      }\n    }\n  }\n}\n\nfragment PackageInfo_npmPackage on NpmPackage {\n  name\n  description\n  id\n  downloads {\n    lastMonth {\n      downloadCount: count\n    }\n  }\n}\n"
  }
};
})() `)


