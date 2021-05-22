/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type rec response_oneGraph = {
    updateChainScript: option<response_oneGraph_updateChainScript>,
  }
   and response_oneGraph_updateChainScript = {
    script: response_oneGraph_updateChainScript_script,
  }
   and response_oneGraph_updateChainScript_script = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ScriptEditor_source]>
  }
   and oneGraphUpdateChainScriptInput = {
    source: oneGraphUpdateChainScriptSourceArg,
    id: string,
  }
   and oneGraphUpdateChainScriptSourceArg = {
    concurrentSource: string,
    textualSource: string,
  }
  
  
  type response = {
    oneGraph: response_oneGraph,
  }
  type rawResponse = response
  type variables = {
    input: oneGraphUpdateChainScriptInput,
  }
}

module Internal = {
  type wrapResponseRaw
  let wrapResponseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"oneGraph_updateChainScript":{"n":""},"oneGraph_updateChainScript_script":{"f":""}}}`
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
      json`{"__root":{"oneGraph_updateChainScript":{"n":""},"oneGraph_updateChainScript_script":{"f":""}}}`
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
      json`{"OneGraphUpdateChainScriptInput":{"source":{"r":"OneGraphUpdateChainScriptSourceArg"}},"__root":{"input":{"r":"OneGraphUpdateChainScriptInput"}}}`
    )
  
  let variablesConverterMap = ()
  let convertVariables = v => v->RescriptRelay.convertObj(
    variablesConverter, 
    variablesConverterMap, 
    Js.undefined
  )
}


module Utils = {
  @@ocaml.warning("-33")
  open Types
  let make_oneGraphUpdateChainScriptSourceArg = (
    ~concurrentSource,
    ~textualSource
  ): oneGraphUpdateChainScriptSourceArg => {
    concurrentSource: concurrentSource,
    textualSource: textualSource
  }
  
  
  let make_oneGraphUpdateChainScriptInput = (
    ~source,
    ~id
  ): oneGraphUpdateChainScriptInput => {
    source: source,
    id: id
  }
  
  let makeVariables = (
    ~input
  ): variables => {
    input: input
  }
  let make_response_oneGraph_updateChainScript_script = (
  ) => ()
  let make_response_oneGraph_updateChainScript = (
    ~script
  ): response_oneGraph_updateChainScript => {
    script: script
  }
  let make_response_oneGraph = (
    ~updateChainScript=?,
    ()
  ): response_oneGraph => {
    updateChainScript: updateChainScript
  }
  let makeOptimisticResponse = (
    ~oneGraph
  ): rawResponse => {
    oneGraph: oneGraph
  }
}
type relayOperationNode
type operationType = RescriptRelay.mutationNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "input"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "input",
    "variableName": "input"
  }
];
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "ScriptEditor_OneGraphMutation",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "OneGraphMutation",
        "kind": "LinkedField",
        "name": "oneGraph",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": (v1/*: any*/),
            "concreteType": "OneGraphUpdateChainScriptResponsePayload",
            "kind": "LinkedField",
            "name": "updateChainScript",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphSourceFile",
                "kind": "LinkedField",
                "name": "script",
                "plural": false,
                "selections": [
                  {
                    "args": null,
                    "kind": "FragmentSpread",
                    "name": "ScriptEditor_source"
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
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ScriptEditor_OneGraphMutation",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "OneGraphMutation",
        "kind": "LinkedField",
        "name": "oneGraph",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": (v1/*: any*/),
            "concreteType": "OneGraphUpdateChainScriptResponsePayload",
            "kind": "LinkedField",
            "name": "updateChainScript",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphSourceFile",
                "kind": "LinkedField",
                "name": "script",
                "plural": false,
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
                    "name": "filename",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "language",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "concurrentSource",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "textualSource",
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
    "cacheID": "6ff2dd5bc39cfc264de27e70140fa1f7",
    "id": null,
    "metadata": {},
    "name": "ScriptEditor_OneGraphMutation",
    "operationKind": "mutation",
    "text": "mutation ScriptEditor_OneGraphMutation(\n  $input: OneGraphUpdateChainScriptInput!\n) {\n  oneGraph {\n    updateChainScript(input: $input) {\n      script {\n        ...ScriptEditor_source\n      }\n    }\n  }\n}\n\nfragment ScriptEditor_source on OneGraphSourceFile {\n  id\n  filename\n  language\n  concurrentSource\n  textualSource\n}\n"
  }
};
})() `)


