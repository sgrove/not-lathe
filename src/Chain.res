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

let emptyChain = {
  name: "main",
  script: ``,
  requests: [],
  blocks: [],
}

let chain = emptyChain

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

  let requests =
    chain.requests
    ->Belt.SortArray.stableSortBy((a, b) =>
      switch (a.operation.kind, b.operation.kind) {
      | (Subscription, _) => -1
      | (_, Subscription) => 1
      | _ => 0
      }
    )
    ->Belt.Array.keepMap(request => {
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

let servicesRequired = chain => {
  chain.requests
  ->Belt.Array.map(request => request.operation.services)
  ->Belt.Array.concatMany
  ->Utils.distinctStrings
}

exception CircularDependencyDetected

let toposortRequests = (requests: array<request>): result<
  array<request>,
  [#circularDependencyDetected],
> => {
  let rec toposortHelper = (request, visited, temp, requests, sorted) => {
    visited->Belt.Set.String.has(request.id)
      ? ()
      : {
          Js.log2("Add Req: ", request.id)
          sorted := sorted.contents->Belt.Array.concat([request])
        }

    let deps = request.dependencyRequestIds
    let (visited, temp) = deps->Belt.Array.reduce((visited, temp), ((visited, temp), depId) => {
      let alreadyVisited = visited->Belt.Set.String.has(depId)
      let loopDetected = temp->Belt.Set.String.has(depId)

      switch (loopDetected, alreadyVisited) {
      | (true, _) => raise(CircularDependencyDetected)
      | (_, true) => (visited, temp)
      | (false, false) =>
        requests
        ->Belt.Array.getBy(existingRequest => existingRequest.id == depId)
        ->Belt.Option.mapWithDefault((visited, temp), dependencyRequest => {
          let visited = visited->Belt.Set.String.add(request.id)
          let temp = temp->Belt.Set.String.add(request.id)
          toposortHelper(dependencyRequest, visited, temp, requests, sorted)
        })
      }
    })

    let visited = visited->Belt.Set.String.add(request.id)
    let temp = temp->Belt.Set.String.remove(request.id)

    (visited, temp)
  }

  let visited = Belt.Set.String.empty
  let temp = Belt.Set.String.empty
  let sorted = ref([])

  try {
    let _ = requests->Belt.Array.reduce((visited, temp), ((visited, temp), request) => {
      toposortHelper(request, visited, temp, requests, sorted)
    })

    Ok(sorted.contents)
  } catch {
  | CircularDependencyDetected => Error(#circularDependencyDetected)
  | other =>
    Js.Console.warn2("Unexpected exception", other)
    Error(#circularDependencyDetected)
  }
}

let devJsonChain = (): t => {
  %raw(`{
  "name": "main",
  "script": "import {\n  CreateTreeInput,\n  CreateTreeVariables,\n  DefaultBranchRefInput,\n  DefaultBranchRefVariables,\n  FilesOnRefInput,\n  FilesOnRefVariables,\n  CreateCommitInput,\n  CreateCommitVariables,\n  CreateRefInput,\n  CreateRefVariables,\n  UpdateRefInput,\n  UpdateRefVariables,\n  UserInputInput,\n  UserInputVariables,\n} from 'oneGraphStudio';\n\nconst encoder = new TextEncoder();\n\nconst sha1 = (input) => {\n  return input;\n};\n\nconst computeGitHash = (source) =>\n  sha1('blob ' + encoder.encode(source).length + '\\0' + source);\n\nexport function makeVariablesForCreateTree(\n  payload: CreateTreeInput\n): CreateTreeVariables {\n  let headRefTreeSha =\n    payload.DefaultBranchRef?.data?.gitHub?.repository?.defaultBranchRef?.target\n      ?.tree?.oid;\n\n  const treeJson = {\n    base_tree: headRefTreeSha,\n    tree: treeFiles,\n  };\n\n  return {};\n}\n\nexport function makeVariablesForDefaultBranchRef(\n  payload: DefaultBranchRefInput\n): DefaultBranchRefVariables {\n  return {};\n}\n\nexport function makeVariablesForFilesOnRef(\n  payload: FilesOnRefInput\n): FilesOnRefVariables {\n  return {};\n}\n\nexport function makeVariablesForCreateRepo(\n  payload: CreateRepoInput\n): CreateRepoVariables {\n  return {};\n}\n\nexport function makeVariablesForCreateCommit(\n  payload: CreateCommitInput\n): CreateCommitVariables {\n  const message = payload.UserInput?.data?.oneGraph?.message;\n  const newTreeSha = '1';\n  const headRefCommitSha = '1';\n\n  const commitJson = {\n    message: message,\n    tree: newTreeSha,\n    parents: [headRefCommitSha],\n  };\n\n  return { commitJson: commitJson };\n}\n\nexport function makeVariablesForCreateRef(\n  payload: CreateRefInput\n): CreateRefVariables {\n  return {};\n}\n\nexport function makeVariablesForUpdateRef(\n  payload: UpdateRefInput\n): UpdateRefVariables {\n  const jsonBody =\n    payload.CreateCommit?.data?.gitHub?.makeRestCall?.post?.jsonBody;\n  const commitRefId = jsonBody?.node_id;\n  const commitSha = jsonBody?.sha;\n  return {\n    refId: commitRefId,\n    sha: commitSha,\n  };\n}\n\nexport function makeVariablesForUserInput(\n  payload: UserInputInput\n): UserInputVariables {\n  return {};\n}\n\nexport function makeVariablesForAboutMe(\n  payload: AboutMeInput\n): AboutMeVariables {\n  return {};\n}\n",
  "requests": [
    {
      "id": "CreateTree",
      "variableDependencies": [
        {
          "name": "path",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "path",
              "value": {
                "TAG": 1,
                "_0": "path"
              }
            }
          }
        },
        {
          "name": "treeJson",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "treeJson",
              "value": {
                "TAG": 1,
                "_0": "treeJson"
              }
            }
          }
        }
      ],
      "operation": {
        "id": "7dca56ce-7ea5-44c7-a7e1-c3a185f53e0e",
        "title": "CreateTree",
        "description": "TODO",
        "body": "mutation CreateTree($path: String!, $treeJson: JSON!) {\n  gitHub {\n    makeRestCall {\n      post(\n        path: $path\n        jsonBody: $treeJson\n        contentType: \"application/json\"\n        accept: \"application/json\"\n      ) {\n        response {\n          statusCode\n        }\n        jsonBody\n      }\n    }\n  }\n}",
        "kind": 1,
        "services": [
          "github"
        ]
      },
      "dependencyRequestIds": [
        "DefaultBranchRef"
      ]
    },
    {
      "id": "DefaultBranchRef",
      "variableDependencies": [
        {
          "name": "owner",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "owner",
              "value": {
                "TAG": 1,
                "_0": "owner"
              }
            }
          }
        },
        {
          "name": "name",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "name",
              "value": {
                "TAG": 1,
                "_0": "name"
              }
            }
          }
        }
      ],
      "operation": {
        "id": "4bac04c8-f918-4868-9a69-cded5a9a85d8",
        "title": "DefaultBranchRef",
        "description": "TODO",
        "body": "query DefaultBranchRef($owner: String!, $name: String!) {\n  gitHub {\n    repository(name: $name, owner: $owner) {\n      id\n      defaultBranchRef {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
        "kind": 0,
        "services": [
          "github"
        ]
      },
      "dependencyRequestIds": []
    },
    {
      "id": "FilesOnRef",
      "variableDependencies": [
        {
          "name": "owner",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "owner",
              "value": {
                "TAG": 1,
                "_0": "owner"
              }
            }
          }
        },
        {
          "name": "name",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "name",
              "value": {
                "TAG": 1,
                "_0": "name"
              }
            }
          }
        },
        {
          "name": "fullyQualifiedRefName",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "fullyQualifiedRefName",
              "value": {
                "TAG": 1,
                "_0": "fullyQualifiedRefName"
              }
            }
          }
        }
      ],
      "operation": {
        "id": "c0e9e88d-f6ac-4872-8687-ac9baa7f2110",
        "title": "FilesOnRef",
        "description": "TODO",
        "body": "query FilesOnRef($owner: String!, $name: String!, $fullyQualifiedRefName: String!) {\n  gitHub {\n    repository(name: $name, owner: $owner) {\n      id\n      ref(qualifiedName: $fullyQualifiedRefName) {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
        "kind": 0,
        "services": [
          "github"
        ]
      },
      "dependencyRequestIds": [
        "DefaultBranchRef"
      ]
    },
    {
      "id": "CreateCommit",
      "variableDependencies": [
        {
          "name": "path",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "path",
              "value": {
                "TAG": 1,
                "_0": "path"
              }
            }
          }
        },
        {
          "name": "commitJson",
          "dependency": {
            "TAG": 0,
            "_0": {
              "functionFromScript": "INITIAL_UNKNOWN",
              "ifMissing": "SKIP",
              "ifList": "FIRST",
              "fromRequestIds": [
                "UserInput",
                "CreateTree"
              ],
              "name": "commitJson"
            }
          }
        }
      ],
      "operation": {
        "id": "6bd45c77-3d51-47ad-91e1-12347f000567",
        "title": "CreateCommit",
        "description": "TODO",
        "body": "mutation CreateCommit($path: String!, $commitJson: JSON!) {\n  gitHub {\n    makeRestCall {\n      post(path: $path, jsonBody: $commitJson) {\n        response {\n          statusCode\n        }\n        jsonBody\n      }\n    }\n  }\n}",
        "kind": 1,
        "services": [
          "github"
        ]
      },
      "dependencyRequestIds": [
        "UserInput",
        "CreateTree"
      ]
    },
    {
      "id": "CreateRef",
      "variableDependencies": [
        {
          "name": "repositoryId",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "repositoryId",
              "value": {
                "TAG": 1,
                "_0": "repositoryId"
              }
            }
          }
        },
        {
          "name": "name",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "name",
              "value": {
                "TAG": 1,
                "_0": "name"
              }
            }
          }
        },
        {
          "name": "oid",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "oid",
              "value": {
                "TAG": 1,
                "_0": "oid"
              }
            }
          }
        }
      ],
      "operation": {
        "id": "632ff2a2-bc7b-49ea-b1cf-40c8431921e0",
        "title": "CreateRef",
        "description": "TODO",
        "body": "mutation CreateRef($repositoryId: ID!, $name: String!, $oid: GitHubGitObjectID!) {\n  gitHub {\n    createRef(input: {repositoryId: $repositoryId, name: $name, oid: $oid}) {\n      ref {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
        "kind": 1,
        "services": [
          "github"
        ]
      },
      "dependencyRequestIds": [
        "FilesOnRef",
        "DefaultBranchRef"
      ]
    },
    {
      "id": "UpdateRef",
      "variableDependencies": [
        {
          "name": "refId",
          "dependency": {
            "TAG": 0,
            "_0": {
              "functionFromScript": "INITIAL_UNKNOWN",
              "ifMissing": "ERROR",
              "ifList": "FIRST",
              "fromRequestIds": [],
              "name": "refId"
            }
          }
        },
        {
          "name": "sha",
          "dependency": {
            "TAG": 0,
            "_0": {
              "functionFromScript": "INITIAL_UNKNOWN",
              "ifMissing": "ERROR",
              "ifList": "FIRST",
              "fromRequestIds": [],
              "name": "sha"
            }
          }
        }
      ],
      "operation": {
        "id": "2f4d4266-db84-435b-bdf6-43e33224f4ed",
        "title": "UpdateRef",
        "description": "TODO",
        "body": "mutation UpdateRef($refId: ID!, $sha: GitHubGitObjectID!) {\n  gitHub {\n    updateRef(input: {refId: $refId, oid: $sha}) {\n      clientMutationId\n      ref {\n        name\n        id\n        target {\n          oid\n          id\n        }\n      }\n    }\n  }\n}",
        "kind": 1,
        "services": [
          "github"
        ]
      },
      "dependencyRequestIds": [
        "CreateRef",
        "DefaultBranchRef",
        "CreateCommit"
      ]
    },
    {
      "id": "UserInput",
      "variableDependencies": [
        {
          "name": "owner",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "owner",
              "value": {
                "TAG": 1,
                "_0": "owner"
              }
            }
          }
        },
        {
          "name": "name",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "name",
              "value": {
                "TAG": 1,
                "_0": "name"
              }
            }
          }
        },
        {
          "name": "branch",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "branch",
              "value": {
                "TAG": 1,
                "_0": "branch"
              }
            }
          }
        },
        {
          "name": "message",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "message",
              "value": {
                "TAG": 1,
                "_0": "message"
              }
            }
          }
        },
        {
          "name": "treeFiles",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "treeFiles",
              "value": {
                "TAG": 1,
                "_0": "treeFiles"
              }
            }
          }
        },
        {
          "name": "acceptOverrides",
          "dependency": {
            "TAG": 1,
            "_0": {
              "name": "acceptOverrides",
              "value": {
                "TAG": 1,
                "_0": "acceptOverrides"
              }
            }
          }
        }
      ],
      "operation": {
        "id": "9ea3b1ac-ebdd-4401-853c-29bb9607a1b8",
        "title": "UserInput",
        "description": "TODO",
        "body": "query UserInput($owner: String!, $name: String!, $branch: String!, $message: String!, $treeFiles: JSON!, $acceptOverrides: Boolean!) {\n  oneGraph {\n    owner: identity(input: $owner)\n    name: identity(input: $name)\n    branch: identity(input: $branch)\n    message: identity(input: $message)\n    treeFiles: identity(input: $treeFiles)\n    treeFiles: identity(input: $acceptOverrides)\n  }\n}",
        "kind": 0,
        "services": [
          "onegraph"
        ]
      },
      "dependencyRequestIds": []
    }
  ],
  "blocks": [
    {
      "id": "7dca56ce-7ea5-44c7-a7e1-c3a185f53e0e",
      "title": "CreateTree",
      "description": "TODO",
      "body": "mutation CreateTree($path: String!, $treeJson: JSON!) {\n  gitHub {\n    makeRestCall {\n      post(\n        path: $path\n        jsonBody: $treeJson\n        contentType: \"application/json\"\n        accept: \"application/json\"\n      ) {\n        response {\n          statusCode\n        }\n        jsonBody\n      }\n    }\n  }\n}",
      "kind": 1,
      "services": [
        "github"
      ]
    },
    {
      "id": "f19222f6-90e8-4650-882b-1de94a6d4a21",
      "title": "GitHubRefFragment",
      "description": "TODO",
      "body": "fragment GitHubRefFragment on GitHubRef {\n  id\n  name\n  target {\n    id\n    oid\n    ... on GitHubCommit {\n      history(first: 1) {\n        edges {\n          node {\n            tree {\n              entries {\n                name\n                path\n                oid\n                object {\n                  ... on GitHubTree {\n                    id\n                    entries {\n                      name\n                      path\n                      oid\n                    }\n                  }\n                }\n              }\n            }\n          }\n        }\n      }\n      tree {\n        id\n        oid\n      }\n    }\n  }\n}",
      "kind": 3,
      "services": [
        "github"
      ]
    },
    {
      "id": "4bac04c8-f918-4868-9a69-cded5a9a85d8",
      "title": "DefaultBranchRef",
      "description": "TODO",
      "body": "query DefaultBranchRef($owner: String!, $name: String!) {\n  gitHub {\n    repository(name: $name, owner: $owner) {\n      id\n      defaultBranchRef {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
      "kind": 0,
      "services": [
        "github"
      ]
    },
    {
      "id": "c0e9e88d-f6ac-4872-8687-ac9baa7f2110",
      "title": "FilesOnRef",
      "description": "TODO",
      "body": "query FilesOnRef($owner: String!, $name: String!, $fullyQualifiedRefName: String!) {\n  gitHub {\n    repository(name: $name, owner: $owner) {\n      id\n      ref(qualifiedName: $fullyQualifiedRefName) {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
      "kind": 0,
      "services": [
        "github"
      ]
    },
    {
      "id": "6bd45c77-3d51-47ad-91e1-12347f000567",
      "title": "CreateCommit",
      "description": "TODO",
      "body": "mutation CreateCommit($path: String!, $commitJson: JSON!) {\n  gitHub {\n    makeRestCall {\n      post(path: $path, jsonBody: $commitJson) {\n        response {\n          statusCode\n        }\n        jsonBody\n      }\n    }\n  }\n}",
      "kind": 1,
      "services": [
        "github"
      ]
    },
    {
      "id": "632ff2a2-bc7b-49ea-b1cf-40c8431921e0",
      "title": "CreateRef",
      "description": "TODO",
      "body": "mutation CreateRef($repositoryId: ID!, $name: String!, $oid: GitHubGitObjectID!) {\n  gitHub {\n    createRef(input: {repositoryId: $repositoryId, name: $name, oid: $oid}) {\n      ref {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
      "kind": 1,
      "services": [
        "github"
      ]
    },
    {
      "id": "2f4d4266-db84-435b-bdf6-43e33224f4ed",
      "title": "UpdateRef",
      "description": "TODO",
      "body": "mutation UpdateRef($refId: ID!, $sha: GitHubGitObjectID!) {\n  gitHub {\n    updateRef(input: {refId: $refId, oid: $sha}) {\n      clientMutationId\n      ref {\n        name\n        id\n        target {\n          oid\n          id\n        }\n      }\n    }\n  }\n}",
      "kind": 1,
      "services": [
        "github"
      ]
    },
    {
      "id": "9ea3b1ac-ebdd-4401-853c-29bb9607a1b8",
      "title": "UserInput",
      "description": "TODO",
      "body": "query UserInput($owner: String!, $name: String!, $branch: String!, $message: String!, $treeFiles: JSON!, $acceptOverrides: Boolean!) {\n  oneGraph {\n    owner: identity(input: $owner)\n    name: identity(input: $name)\n    branch: identity(input: $branch)\n    message: identity(input: $message)\n    treeFiles: identity(input: $treeFiles)\n    treeFiles: identity(input: $acceptOverrides)\n  }\n}",
      "kind": 0,
      "services": [
        "onegraph"
      ]
    }
  ]
}`)
}
