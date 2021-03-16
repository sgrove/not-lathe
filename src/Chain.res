type ifMissing = [
  | #ERROR
  | #ALLOW
  | #SKIP
]

let stringOfIfMissing = x =>
  switch x {
  | #ERROR => "ERROR"
  | #ALLOW => "ALLOW"
  | #SKIP => "SKIP"
  }

let ifMissingOfString = s =>
  switch s {
  | "ERROR" => Ok(#ERROR)
  | "ALLOW" => Ok(#ALLOW)
  | "SKIP" => Ok(#SKIP)
  | other => Error(other)
  }

type ifList = [
  | #FIRST
  | #LAST
  | #ALL
  | #EACH
]

let stringOfIfList = x =>
  switch x {
  | #FIRST => "FIRST"
  | #LAST => "LAST"
  | #ALL => "ALL"
  | #EACH => "EACH"
  }

let ifListOfString = s =>
  switch s {
  | "FIRST" => Ok(#FIRST)
  | "LAST" => Ok(#LAST)
  | "ALL" => Ok(#ALL)
  | "EACH" => Ok(#EACH)
  | other => Error(other)
  }

type requestOperation = Named(string)

type argumentDependency = {
  functionFromScript: string,
  maxRecur: option<int>,
  ifMissing: ifMissing,
  ifList: ifList,
  fromRequestIds: array<string>,
  name: string,
}

type variableValue =
  | JSON(Js.Json.t)
  | Variable(string)

type variableInputs = {
  name: string,
  value: variableValue,
}

type variableDependencyKind =
  | ArgumentDependency(argumentDependency)
  | Direct(variableInputs)

type variableDependency = {name: string, dependency: variableDependencyKind}

type request = {
  id: string,
  variableDependencies: array<variableDependency>,
  operation: Card.block,
  dependencyRequestIds: array<string>,
}

type t = {
  name: string,
  script: string,
  requests: array<request>,
  blocks: array<Card.block>,
}

let base = `mutation ExecuteChainMutation($chain: OneGraphQueryChainInput!) {
  oneGraph {
    executeChain(
      input: $chain
    ) {
      results {
        request {
          id
        }
        result
        argumentDependencies {
          name
          returnValues
          logs {
            level
            body
          }
          error {
            name
            message
            stackString
          }
        }
      }
    }
  }
}`

let makeChain = (~operations) => {
  j`${operations}

${base}`
}

let target = `mutation ExecuteChainMutation(
  $webhookUrl: JSON!
  $chain: OneGraphQueryChainInput!
  $sheetId: JSON!
) {
  oneGraph {
    executeChain(
      input: {
        requests: [
          {
            id: "SlackReactionSubscription"
            operationName: "SlackReactionSubscription"
            variables: [
              { name: "webhookUrl", value: $webhookUrl }
            ]
          }
          {
            id: "AddToDocMutation"
            operationName: "AddToDocMutation"
            argumentDependencies: {
              name: "row"
              ifList: ALL
              fromRequestIds: ["SlackReactionSubscription"]
              functionFromScript: "getRow"
              ifMissing: SKIP
            }
            variables: { name: "sheetId", value: $sheetId }
          }
        ]
        script: "const a = true;"
      }
    ) {
      results {
        request {
          id
        }
        result
        argumentDependencies {
          name
          returnValues
          logs {
            level
            body
          }
          name
        }
      }
    }
  }
}

mutation AddToDocMutation(
  $sheetId: String!
  $row: [String!]!
) {
  google {
    sheets {
      appendValues(
        id: $sheetId
        valueInputOption: "USER_ENTERED"
        majorDimenson: "ROWS"
        range: "'Raw Data'!A1"
        values: [$row]
      ) {
        updates {
          spreadsheetId
          updatedRange
          updatedCells
          updatedData {
            values
          }
        }
      }
    }
  }
}

subscription SlackReactionSubscription(
  $webhookUrl: String!
) {
  slack(webhookUrl: $webhookUrl) {
    reactionAddedEvent {
      eventTime
      event {
        user {
          id
          name
        }
        eventTs
        reaction
        item {
          channel {
            name
          }
          message {
            permaLink
            user {
              id
              name
            }
            text
            ts
          }
        }
      }
    }
  }
}`

let addToDocMutation: Card.block = {
  title: "AddToDocMutation",
  id: "319e8375-16f0-434b-8f9a-3a1d364fe5df"->Uuid.parseExn,
  contributedBy: Some("@sgrove"),
  services: ["google"],
  description: "Insert a row into a Google Docs spreadsheet",
  kind: Mutation,
  body: `mutation AddToDocMutation($sheetId: String!, $row: [String!]!) {
  google {
    sheets {
      appendValues(
        id: $sheetId
        valueInputOption: "USER_ENTERED"
        majorDimenson: "ROWS"
        range: "'Raw Data'!A1"
        values: [$row]
      ) {
        updates {
          spreadsheetId
          updatedRange
          updatedCells
          updatedData {
            values
          }
        }
      }
    }
  }
}`,
}

let slackSub: Card.block = {
  title: "SlackReactionSubscription",
  id: "942ae063-f7b4-4747-bae0-be427a8802e7"->Uuid.parseExn,
  contributedBy: Some("@sgrove"),
  kind: Subscription,
  services: ["slack"],
  description: "Provide notifications when someone reacts with an emoji to a message on Slack",
  body: `subscription SlackReactionSubscription(
  $webhookUrl: String!
) {
  slack(webhookUrl: $webhookUrl) {
    reactionAddedEvent {
      eventTime
      event {
        user {
          id
          name          
        }        
        eventTs
        reaction
        item {
          channel {
            name
          }
          message {
            permaLink
            user {
              id
              name              
            }
            text
            ts
          }
        }        
      }
    }
  }
}`,
}

let npmDownloadsLastMonth: Card.block = {
  title: "NpmDownloadsLastMonth",
  id: "084beb2a-aae1-4a59-a3e8-7beaa383bd1a"->Uuid.parseExn,
  contributedBy: Some("@sgrove"),
  services: ["npm"],
  kind: Query,
  description: "Find the total number of downloads from npm in the past 30 days",
  body: `query NpmDownloadsLastMonth {
  npm {
    downloads {
      lastMonth {
        count
        end
        start
        ... on NpmOverallDownloadPeriodData {
          end
          start
        }
        perDay {
          count
          day
        }
      }
    }
  }
}`,
}

let testMutation: Card.block = {
  title: "TestMutation",
  id: "1886ccd2-7c37-49de-901b-e196221a94a0"->Uuid.parseExn,
  contributedBy: Some("@sgrove"),
  services: [],
  kind: Mutation,
  description: "Test mutation as a sanity test for tooling",
  body: `mutation TestMutation($query: String!,
  $another: [OneGraphQueryChainInput!]
  #, $temp: String, $age: Int!, $unlisted: Boolean!
  ) {
  testMutate(query: $query)
}`,
}

let req1 = {
  id: "SlackReactionSubscription",
  operation: slackSub,
  variableDependencies: [
    {
      name: "webhookUrl",
      dependency: Direct({
        name: "webhookUrl",
        value: Variable("$webhookUrl"),
      }),
    },
  ],
  dependencyRequestIds: [],
}

let req2 = {
  id: "AddToDocMutation",
  operation: addToDocMutation,
  variableDependencies: [
    {
      name: "row",
      dependency: ArgumentDependency({
        name: "row",
        ifList: #ALL,
        fromRequestIds: ["SlackReactionSubscription"],
        functionFromScript: "getRow",
        ifMissing: #SKIP,
        maxRecur: None,
      }),
    },
    {
      name: "sheetId",
      dependency: Direct({name: "sheetId", value: Variable("$sheetId")}),
    },
  ],
  dependencyRequestIds: [],
}

let req3 = {
  id: "NpmDownloadsLastMonth",
  operation: npmDownloadsLastMonth,
  variableDependencies: [],
  dependencyRequestIds: [],
}

let req4 = {
  id: "TestMutation",
  operation: testMutation,
  variableDependencies: [
    {
      name: "query",
      dependency: ArgumentDependency({
        name: "query",
        ifList: #FIRST,
        fromRequestIds: ["NpmDownloadsLastMonth"],
        functionFromScript: "getStatus",
        ifMissing: #ERROR,
        maxRecur: None,
      }),
    },
    //   {
    //     name: "another",
    //     dependency: ArgumentDependency({
    //       name: "another",
    //       ifList: #FIRST,
    //       fromRequestIds: [],
    //       functionFromScript: "getStatus",
    //       ifMissing: #ERROR,
    //       maxRecur: None,
    //     }),
    //   },
    //   {
    //     name: "temp",
    //     dependency: Direct({name: "temp", value: JSON(j`""`->Js.Json.parseExn)}),
    //   },
    //   {
    //     name: "age",
    //     dependency: Direct({name: "age", value: Variable("myAge")}),
    //   },
  ],
  dependencyRequestIds: [],
}

let req5 = {
  id: "GitHubStatus",
  operation: Card.gitHubStatus,
  variableDependencies: [
    {
      name: "login",
      dependency: Direct({
        name: "login",
        value: Variable("gitHubLogin"),
      }),
    },
  ],
  dependencyRequestIds: [],
}

let req6 = {
  id: "SetSlackStatus",
  operation: Card.setSlackStatus,
  variableDependencies: [
    {
      name: "jsonBody",
      dependency: ArgumentDependency({
        functionFromScript: "",
        maxRecur: None,
        ifMissing: #SKIP,
        ifList: #FIRST,
        fromRequestIds: ["GitHubStatus"],
        name: "jsonBody",
      }),
    },
  ],
  dependencyRequestIds: ["GitHubStatus"],
}

let chain2 = {
  name: "chain2",
  script: "export function getRow(result) {
          const event = result.SlackReactionSubscription[0].data.slack.reactionAddedEvent.event;
          const reaction = event.reaction;
          if (reaction !== 'eyes' && reaction !== 'white_check_mark') {
            return null;
          }
          return [
            event.item.message.permaLink, // message_permalink
            event.item.message.text || '', // message_text
            `=DATEOFTIMESTAMP(${event.item.message.ts} * 1000)`, // message_ts
            event.item.message.user.id || '', // message_user_id (we don't have this yet :/)
            event.item.message.user.name || '', // message_user_name
            reaction === 'eyes' ? `=DATEOFTIMESTAMP(${event.eventTs} * 1000)` : '', // eyes_reaction_ts
            reaction === 'eyes' ? event.user.id : '', // eyes_reaction_user_id
            reaction === 'eyes' ? event.user.name : '', // eyes_reaction_user_name
            reaction === 'white_check_mark' ? `=DATEOFTIMESTAMP(${event.eventTs} * 1000)` : '', //completed_reaction_ts
            reaction === 'white_check_mark' ? event.user.id : '', // completed_reaction_user_id
            reaction === 'white_check_mark' ? event.user.name : '', // completed_reaction_user_name
            event.item.channel.name // channel_name
          ]
        }",
  requests: [req1, req2, req3, req4],
  blocks: [addToDocMutation, slackSub],
}

let _chain = {
  name: "chain3",
  script: "// export function greet(hello) {
//  return true
// }

export function getDownloadsAsString(payload) {
 return String(payload.NpmDownloadsLastMonth.data.npm.downloads.lastMonth)
}

function getIssue(payload) {
  return payload.WatchForIssue?.data?.github?.issueCommentEvent?.issue;
}

export function getIssueId(payload) {
  return getIssue(payload)?.id;
}

export function getIssueTitle(payload) {
  const issue = getIssue(payload);

  const rateLimit = payload.GitHubRateLimits.data.gitHub.rateLimit;

  if (issue) {
    if (rateLimit.remaining < 4990) {
      return null;
    }

    if (rateLimit.remaining < 4995) {
      return `Sorry, API limits are low, will reset at ${rateLimit.resetAt}`;
    }

    const totalComments = issue.comments.totalCount;
    const totalReactions = issue.reactions.totalCount;

    return `This GitHub issue has ${totalComments} comments and ${totalReactions} reactions`;
  }
}
",
  requests: [req3, req4],
  blocks: [npmDownloadsLastMonth, testMutation],
}

let _chain = {
  name: "main",
  script: `import {
  GitHubStatusInput,
  GitHubStatusVariables,
  SetSlackStatusInput,
  SetSlackStatusVariables,
} from 'oneGraphStudio';

export function makeVariablesForSetSlackStatus(
  payload: SetSlackStatusInput
): SetSlackStatusVariables {
  let status = payload.GitHubStatus?.data?.gitHub?.user?.status?.message;

  if (!status) {
    return null;
  }

  return {
    jsonBody: {
      profile: {
        status_text: status,
      },
    },
  };
}`,
  requests: [req5, req6],
  blocks: [Card.gitHubStatus, Card.setSlackStatus],
}

let chain = {
  name: "main",
  script: ``,
  requests: [],
  blocks: [],
}

type compiled = {
  operationDoc: string,
  variables: Js.Json.t,
}

type mockCompiledChain = {
  compiled: compiled,
  variables: Js.Dict.t<Js.Json.t>,
}

let compileAsObj = (chain: t): compiled => {
  let operations = chain.blocks->Belt.Array.joinWith("\n", x => x.body)

  let makeRequest = request => {
    let variables = request.variableDependencies->Belt.Array.keepMap(dep => {
      switch dep.dependency {
      | ArgumentDependency(_) => None
      | Direct(variable) =>
        Some({
          "name": variable.name,
          "value": switch variable.value {
          | JSON(json) => json
          | Variable(name) => name->Js.Json.string
          },
        })
      }
    })

    let argumentDependencies = request.variableDependencies->Belt.Array.keepMap(dep => {
      switch dep.dependency {
      | ArgumentDependency(dep) =>
        Some({
          "name": dep.name,
          "ifList": dep.ifList,
          "ifMissing": dep.ifMissing,
          "fromRequestIds": dep.fromRequestIds,
          "maxRecur": dep.maxRecur,
          "functionFromScript": dep.functionFromScript,
        })
      | Direct(_) => None
      }
    })

    {
      "id": request.id,
      "operationName": request.operation.title,
      "variables": variables,
      "argumentDependencies": argumentDependencies,
    }
  }

  let requests = chain.requests->Belt.Array.map(makeRequest)

  let input = Obj.magic({
    "requests": requests,
    "script": chain.script,
  })

  {
    variables: Obj.magic({"chain": input}),
    operationDoc: j`
${operations}

${base}`,
  }
}

type requestScriptNames = {
  functionName: string,
  returnTypeName: string,
  inputTypeName: string,
}

let requestScriptNames = (request: request) => {
  let title = request.operation.title->Utils.capitalizeFirstLetter
  let functionName = j`makeVariablesFor${title}`
  let returnTypeName = j`${title}Variables`
  let inputTypeName = j`${title}Input`
  {
    functionName: functionName,
    returnTypeName: returnTypeName,
    inputTypeName: inputTypeName,
  }
}

let callForVariable = (request: request, variableName) => {
  let requestScriptName = requestScriptNames(request).functionName

  j`export function ${requestScriptName}_${variableName} (payload) {
  return ${requestScriptName}(payload)?.["${variableName}"]
}`
}

type variableToVariableDependency = {
  upstreamName: string,
  upstreamType: string,
  exposedName: string,
}

type compiledChainMeta = {
  name: string,
  operationName: string,
  exposedVariables: array<variableToVariableDependency>,
}

type compiledChainWithMeta = {
  operationDoc: string,
  chains: array<compiledChainMeta>,
}

let compileOperationDoc = (chain: t): compiledChainWithMeta => {
  let blockOperations = chain.blocks->Belt.Array.joinWith("\n", x => x.body)

  let exposedVariables =
    chain.requests
    ->Belt.Array.map(request =>
      request.variableDependencies->Belt.Array.keepMap(dep => {
        switch dep.dependency {
        | ArgumentDependency(_) => None
        | Direct(variable) =>
          switch variable.value {
          | JSON(_) => None
          | Variable(name) =>
            request.operation
            ->Card.getFirstVariables
            ->Belt.Array.getBy(((varName, _)) => {
              varName == variable.name
            })
            ->Belt.Option.map(((varName, varType)) => {
              {
                upstreamName: varName,
                upstreamType: varType,
                exposedName: name,
              }
            })
          }
        }
      })
    )
    ->Belt.Array.concatMany

  let (_, exposedVariableNamesAndTypes) = exposedVariables->Belt.Array.reduce(
    (Belt.Set.String.empty, []),
    ((names, uniqueVariables), next) => {
      switch names->Belt.Set.String.has(next.exposedName) {
      | false => (
          names->Belt.Set.String.add(next.exposedName),
          uniqueVariables->Belt.Array.concat([next]),
        )
      | true => (names, uniqueVariables)
      }
    },
  )

  let makeRequest = request => {
    let variables = request.variableDependencies->Belt.Array.keepMap(dep => {
      switch dep.dependency {
      | ArgumentDependency(_) => None
      | Direct(variable) =>
        switch variable.value {
        | JSON(json) => Some(j`{name: "${variable.name}", value: ${json->Js.Json.stringify}}`)
        | Variable(name) => Some(j`{name: "${variable.name}", value: \\$${name}}`)
        }
      }
    })

    let argumentDependencies = request.variableDependencies->Belt.Array.keepMap(dep => {
      switch dep.dependency {
      | ArgumentDependency(dep) =>
        let reqIds = {
          let ids =
            dep.fromRequestIds->Belt.Array.map(reqId => j`"${reqId}"`)->Js.Array2.joinWith(", ")
          j`[${ids}]`
        }
        let fields =
          [
            j`name: "${dep.name}"`,
            j`ifList: ${dep.ifList->Obj.magic}`,
            j`ifMissing: ${dep.ifMissing->Obj.magic}`,
            j`fromRequestIds: ${reqIds}`,
            j`functionFromScript: "${dep.functionFromScript}"`,
          ]->Js.Array2.joinWith(",\n                  ")

        let argDep = j`
                {
                  ${fields}
                }
`

        Some(argDep)
      | Direct(_) => None
      }
    })

    j`
          {
            id: "${request.id}",
            operationName: "${request.operation.title}",
            variables: [${variables->Js.Array2.joinWith(",\n  ")}],
            argumentDependencies: [${argumentDependencies->Js.Array2.joinWith(",")}],
          }`
  }

  let requests = chain.requests->Belt.Array.keepMap(request => {
    switch request.operation.kind {
    | Fragment => None
    | _ => Some(makeRequest(request))
    }
  })

  let compiledString = j`requests: [${requests->Js.Array2.joinWith(",")}],
    script: """
${chain.script}
""",
  `

  let operationVariables = switch exposedVariableNamesAndTypes {
  | [] => ""
  | other =>
    let variableNames =
      other
      ->Belt.Array.map(({exposedName, upstreamType}) => {
        let isRequired = upstreamType->Js.String2.endsWith("!") ? "!" : ""
        j`\\$${exposedName}: JSON${isRequired}`
      })
      ->Js.Array2.joinWith(",\n ")
    j`(${variableNames})`
  }

  let operationName = j`ExecuteChainMutation_${chain.name}`

  let base = j`mutation ${operationName}${operationVariables} {
  oneGraph {
    executeChain(
      input: {
        ${compiledString}
      }
    ) {
      results {
        request {
          id
        }
        result
        argumentDependencies {
          name
          returnValues
          logs {
            level
            body
          }
          error {
            name
            message
            stackString
          }
        }
      }
    }
  }
}`

  let operationDoc = j`
${base}

${blockOperations}`

  {
    operationDoc: operationDoc,
    chains: [
      {
        name: chain.name,
        operationName: operationName,
        exposedVariables: exposedVariables,
      },
    ],
  }
}

let saveToLocalStorage = (chain: t, docId): unit => {
  let jsonString = Obj.magic(chain)->Js.Json.stringify

  Dom.Storage2.localStorage->Dom.Storage2.setItem(docId, jsonString)
}

let loadFromLocalStorage = (docId: string): option<t> => {
  let jsonString = Dom.Storage2.localStorage->Dom.Storage2.getItem(docId)

  jsonString->Belt.Option.map(jsonString => {
    let json = jsonString->Js.Json.parseExn
    Obj.magic(json)
  })
}
