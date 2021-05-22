/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec response_oneGraph = {
    studio: response_oneGraph_studio,
  }
   and response_oneGraph_studio = {
    actions: array<response_oneGraph_studio_actions>,
  }
   and response_oneGraph_studio_actions = {
    id: string,
    name: string,
    services: array<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ActionSearch_oneGraphStudioChainAction]>
  }
  
  
  type response = {
    oneGraph: response_oneGraph,
  }
  type rawResponse = response
  type refetchVariables = unit
  let makeRefetchVariables = (
  ) => ()
  
  type variables = unit
}

module Internal = {
  type wrapResponseRaw
  let wrapResponseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"oneGraph_studio_actions":{"f":""}}}`
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
      json`{"__root":{"oneGraph_studio_actions":{"f":""}}}`
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
      json`{}`
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

}
type relayOperationNode
type operationType = RescriptRelay.queryNode<relayOperationNode>


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
},
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "services",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "ActionSearchQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "OneGraphServiceQuery",
        "kind": "LinkedField",
        "name": "oneGraph",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "OneGraphStudio",
            "kind": "LinkedField",
            "name": "studio",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphStudioChainAction",
                "kind": "LinkedField",
                "name": "actions",
                "plural": true,
                "selections": [
                  (v0/*: any*/),
                  (v1/*: any*/),
                  (v2/*: any*/),
                  {
                    "args": null,
                    "kind": "FragmentSpread",
                    "name": "ActionSearch_oneGraphStudioChainAction"
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
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "ActionSearchQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "OneGraphServiceQuery",
        "kind": "LinkedField",
        "name": "oneGraph",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "OneGraphStudio",
            "kind": "LinkedField",
            "name": "studio",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphStudioChainAction",
                "kind": "LinkedField",
                "name": "actions",
                "plural": true,
                "selections": [
                  (v0/*: any*/),
                  (v1/*: any*/),
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
    ]
  },
  "params": {
    "cacheID": "598b90c920f41cfda02962fd2ba32acc",
    "id": null,
    "metadata": {},
    "name": "ActionSearchQuery",
    "operationKind": "query",
    "text": "query ActionSearchQuery {\n  oneGraph {\n    studio {\n      actions {\n        id\n        name\n        services\n        ...ActionSearch_oneGraphStudioChainAction\n      }\n    }\n  }\n}\n\nfragment ActionSearch_oneGraphStudioChainAction on OneGraphStudioChainAction {\n  id\n  name\n  services\n}\n"
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
