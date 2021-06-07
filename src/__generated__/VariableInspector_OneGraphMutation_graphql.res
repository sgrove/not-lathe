/* @generated */
%%raw("/* @generated */")
module Types = {
  @@ocaml.warning("-30")
  
  type enum_OneGraphStudioChainActionVariableMethodArgEnum = private [>
    | #COMPUTED
    | #DIRECT
    ]
  
  type enum_OneGraphStudioChainActionVariableMethodArgEnum_input = [
    | #COMPUTED
    | #DIRECT
    ]
  
  type enum_OneGraphStudioChainActionVariableIfMissingArgEnum = private [>
    | #ALLOW
    | #ERROR
    | #SKIP
    ]
  
  type enum_OneGraphStudioChainActionVariableIfMissingArgEnum_input = [
    | #ALLOW
    | #ERROR
    | #SKIP
    ]
  
  type enum_OneGraphStudioChainActionVariableIfListArgEnum = private [>
    | #ALL
    | #EACH
    | #FIRST
    | #LAST
    ]
  
  type enum_OneGraphStudioChainActionVariableIfListArgEnum_input = [
    | #ALL
    | #EACH
    | #FIRST
    | #LAST
    ]
  
  type rec response_oneGraph = {
    updateChainActionVariable: option<response_oneGraph_updateChainActionVariable>,
  }
   and response_oneGraph_updateChainActionVariable = {
    variable: response_oneGraph_updateChainActionVariable_variable,
  }
   and response_oneGraph_updateChainActionVariable_variable = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #VariableInspector_oneGraphStudioChainActionVariable]>
  }
   and oneGraphUpdateChainActionVariableInput = {
    probePath: array<string>,
    maxRecur: int,
    ifList: [
    | #ALL
    | #EACH
    | #FIRST
    | #LAST
    ],
    ifMissing: [
    | #ALLOW
    | #ERROR
    | #SKIP
    ],
    graphqlType: string,
    @as("method") method_: [
    | #COMPUTED
    | #DIRECT
    ],
    description: option<string>,
    name: string,
    id: string,
  }
  
  
  type response = {
    oneGraph: response_oneGraph,
  }
  type rawResponse = response
  type variables = {
    variable: oneGraphUpdateChainActionVariableInput,
  }
}

module Internal = {
  type wrapResponseRaw
  let wrapResponseConverter: 
    Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = 
    %raw(
      json`{"__root":{"oneGraph_updateChainActionVariable_variable":{"f":""},"oneGraph_updateChainActionVariable":{"n":""}}}`
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
      json`{"__root":{"oneGraph_updateChainActionVariable_variable":{"f":""},"oneGraph_updateChainActionVariable":{"n":""}}}`
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
      json`{"OneGraphUpdateChainActionVariableInput":{"description":{"n":""}},"__root":{"variable":{"r":"OneGraphUpdateChainActionVariableInput"}}}`
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
  external oneGraphStudioChainActionVariableMethodArgEnum_toString:
  enum_OneGraphStudioChainActionVariableMethodArgEnum => string = "%identity"
  external oneGraphStudioChainActionVariableMethodArgEnum_input_toString:
  enum_OneGraphStudioChainActionVariableMethodArgEnum_input => string = "%identity"
  external oneGraphStudioChainActionVariableIfMissingArgEnum_toString:
  enum_OneGraphStudioChainActionVariableIfMissingArgEnum => string = "%identity"
  external oneGraphStudioChainActionVariableIfMissingArgEnum_input_toString:
  enum_OneGraphStudioChainActionVariableIfMissingArgEnum_input => string = "%identity"
  external oneGraphStudioChainActionVariableIfListArgEnum_toString:
  enum_OneGraphStudioChainActionVariableIfListArgEnum => string = "%identity"
  external oneGraphStudioChainActionVariableIfListArgEnum_input_toString:
  enum_OneGraphStudioChainActionVariableIfListArgEnum_input => string = "%identity"
  
  let make_oneGraphUpdateChainActionVariableInput = (
    ~probePath,
    ~maxRecur,
    ~ifList,
    ~ifMissing,
    ~graphqlType,
    ~method_,
    ~description=?,
    ~name,
    ~id,
    ()
  ): oneGraphUpdateChainActionVariableInput => {
    probePath: probePath,
    maxRecur: maxRecur,
    ifList: ifList,
    ifMissing: ifMissing,
    graphqlType: graphqlType,
    method_: method_,
    description: description,
    name: name,
    id: id
  }
  
  let makeVariables = (
    ~variable
  ): variables => {
    variable: variable
  }
  let make_response_oneGraph_updateChainActionVariable_variable = (
  ) => ()
  let make_response_oneGraph_updateChainActionVariable = (
    ~variable
  ): response_oneGraph_updateChainActionVariable => {
    variable: variable
  }
  let make_response_oneGraph = (
    ~updateChainActionVariable=?,
    ()
  ): response_oneGraph => {
    updateChainActionVariable: updateChainActionVariable
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
    "name": "variable"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "input",
    "variableName": "variable"
  }
];
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "VariableInspector_OneGraphMutation",
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
            "concreteType": "OneGraphUpdateChainActionVariableResponsePayload",
            "kind": "LinkedField",
            "name": "updateChainActionVariable",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphStudioChainActionVariable",
                "kind": "LinkedField",
                "name": "variable",
                "plural": false,
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
    "name": "VariableInspector_OneGraphMutation",
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
            "concreteType": "OneGraphUpdateChainActionVariableResponsePayload",
            "kind": "LinkedField",
            "name": "updateChainActionVariable",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "OneGraphStudioChainActionVariable",
                "kind": "LinkedField",
                "name": "variable",
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
    "cacheID": "96d97d11df5806b9634b4bed551ce80d",
    "id": null,
    "metadata": {},
    "name": "VariableInspector_OneGraphMutation",
    "operationKind": "mutation",
    "text": "mutation VariableInspector_OneGraphMutation(\n  $variable: OneGraphUpdateChainActionVariableInput!\n) {\n  oneGraph {\n    updateChainActionVariable(input: $variable) {\n      variable {\n        ...VariableInspector_oneGraphStudioChainActionVariable\n      }\n    }\n  }\n}\n\nfragment ComputedVariableInspector_chainActionVariable on OneGraphStudioChainActionVariable {\n  id\n}\n\nfragment VariableInspector_oneGraphStudioChainActionVariable on OneGraphStudioChainActionVariable {\n  id\n  name\n  graphqlType\n  description\n  ifList\n  ifMissing\n  maxRecur\n  computeMethod: method\n  probePath\n  ...ComputedVariableInspector_chainActionVariable\n}\n"
  }
};
})() `)


