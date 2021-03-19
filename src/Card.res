type operationKind = Query | Mutation | Subscription | Fragment

type block = {
  id: Uuid.v4,
  title: string,
  description: string,
  body: string,
  kind: operationKind,
  contributedBy: option<string>,
  services: array<string>,
}

@module("./OneGraph.js")
external fetchOneGraph: (
  OneGraphAuth.t,
  string,
  option<string>,
  option<Js.Json.t>,
) => Js.Promise.t<Js.Json.t> = "fetchOneGraph"

type tab = Block | Query

type state = {tab: tab, ast: GraphQLJs.graphqlAst}

let selectedTab = "bg-white inline-block border-l border-t border-r rounded-t py-2 px-4 text-blue-dark font-semibold"
let idleTab = "bg-white inline-block py-2 px-4 text-blue hover:text-blue-darker font-semibold"

let baseState: Js.Json.t = Obj.magic(Js.Json.parseExn("{}"))

@react.component
let make = (~block, ~schema as _, ~ports=?, ~onVariableInspected, ~onBlockInspected) => {
  open React

  let ports: Js.Dict.t<React.element> = ports->Belt.Option.getWithDefault(Js.Dict.empty())
  let ast = GraphQLJs.parse(block.body)
  let operationDef = ast.definitions->Belt.Array.get(0)

  switch operationDef {
  | None => "Couldn't parse operation doc"->string
  | Some(operationDef) =>
    let title = switch block.title {
    | "Unknown" => operationDef.name.value
    | other => other
    }

    // let (formVariables, setFormVariables) = React.useState(() => baseState)

    // let submitForm = _ => {
    //   auth
    //   ->fetchOneGraph(block.body, None, Some(formVariables))
    //   ->Js.Promise.then_((result: Js.Json.t) => {
    //     let missing = OneGraphAuth.findMissingAuthServices(auth, Some(result))

    //     switch missing {
    //     | list{} => ()
    //     | list{service, ..._} => setMissingAuthService(_ => Some(service))
    //     }

    //     Js.Promise.resolve()
    //   }, _)
    //   ->ignore
    // }

    let (state, _setState) = React.useState(() => {
      tab: Block,
      ast: ast,
    })

    // let runButton =
    //   <button
    //     className="block"
    //     onClick={event => {
    //       ReactEvent.Mouse.preventDefault(event)
    //       switch missingAuthService {
    //       | None => submitForm()
    //       | Some(service) =>
    //         auth
    //         ->OneGraphAuth.login(service)
    //         ->Js.Promise.then_(
    //           _ => auth->OneGraphAuth.isLoggedIn(service)->Js.Promise.then_(result =>
    //               switch result {
    //               | false => ()
    //               | true => setMissingAuthService(_ => None)
    //               }->Js.Promise.resolve
    //             , _)->Js.Promise.resolve,
    //           _,
    //         )
    //         ->ignore
    //       }
    //     }}>
    //     {switch missingAuthService {
    //     | None => <> <Icons.Play /> {"Run operation"->string} </>
    //     | Some(service) => ("Log into " ++ service)->string
    //     }}
    //   </button>

    <div className="bg-gray-900 shadow-lg rounded p-1" key={title}>
      <div className="group relative">
        <div
          onClick={event => {
            onBlockInspected(event, block)
          }}
          className={"bg-gradient-to-b p-2 " ++
          switch operationDef.operation {
          | #query => "bg-green-400"
          | #fragment => "bg-gray-400"
          | #mutation => "bg-red-400"
          | #subscription => "bg-yellow-400"
          }}>
          <h3 className="text-white text-sm overflow-x-scroll"> {title->string} </h3>
        </div>
        {switch state.tab {
        | Query =>
          <code>
            <pre
              className="text-black flex-1 bg-white w-full block rounded max-h-96 overflow-scroll text-sm whitespace-pre p-2">
              {block.body->string}
            </pre>
          </code>

        | Block =>
          let variables =
            (
              ast.definitions->Belt.Array.get(0)->Belt.Option.getExn
            ).variableDefinitions->Belt.Option.getWithDefault([])
          // let inputs =
          //   variables->Belt.Array.map(def => formInput(schema, def, setFormVariables, ports))

          let variableEls = variables->Belt.Array.map(def => {
            let name = def.variable.name.value
            let port = ports->Js.Dict.get(name)->Belt.Option.getWithDefault(React.null)
            <li
              onClick={event => {
                onVariableInspected(~event, ~block, ~variable=def.variable.name.value)
              }}>
              <div
                className="flex justify-start cursor-pointer text-gray-700 hover:text-blue-400 hover:bg-blue-200 bg-blue-100 rounded-md my-1 content-center">
                <div
                  className="flex flex-grow font-medium align-middle inline-block content-center">
                  port
                  <code className="align-middle inline-block content-center">
                    {("$" ++ name)->string}
                  </code>
                </div>
              </div>
            </li>
          })

          <> <form className="text-white"> <ul> {variableEls->array} </ul> </form> </>
        }}
      </div>
    </div>
  }
}

let createAssetWithStuff = {
  title: "CreateMuxAssetWithStuff",
  id: "812d3bb6-7552-41c6-8899-944a67cd7188"->Uuid.parseExn,
  contributedBy: Some("@sgrove"),
  description: "Just a test",
  kind: Mutation,
  services: ["mux"],
  body: "mutation CreateMuxAssetWithStuff(
  $normalizeAudio: Boolean = false
  $perTitleEncode: Boolean = false
  $playbackPolicy: [MuxVideoPlaybackPolicyEnumArg!] = PUBLIC
) {
  mux {
    createAsset(
      input: {
        sourceUrl: \"\"
        settings: {
          normalizeAudio: $normalizeAudio
          perTitleEncode: $perTitleEncode
          playbackPolicy: $playbackPolicy
        }
      }
    ) {
      asset {
        aspectRatio
      }
    }
  }
}",
}

let gitHubUserFragment: block = {
  title: "GitHubUserWithStatus",
  id: "084beb2a-aae1-4a59-a3e8-7beaa323bd1a"->Uuid.parseExn,
  contributedBy: Some("@sgrove"),
  services: ["github"],
  kind: Fragment,
  description: "TODO",
  body: `fragment User on GitHubUser {
  status {
    indicatesLimitedAvailability
    message
    expiresAt
    emojiHTML
    emoji
    createdAt
  }
}
`,
}

let setSlackStatus: block = {
  title: "SetSlackStatus",
  id: "084beb2a-aae1-4a59-a3e8-7ceaa383bd1a"->Uuid.parseExn,
  contributedBy: Some("@sgrove"),
  kind: Mutation,
  services: ["slack"],
  description: "Given some JSON, set the slack status",
  body: `mutation SetSlackStatus($jsonBody: JSON!) {
  slack {
    makeRestCall {
      post(
        path: "/api/users.profile.set"
        contentType: "application/json"
        jsonBody: $jsonBody
      ) {
        jsonBody
      }
    }
  }
}`,
}

let gitHubStatus = {
  title: "GitHubStatus",
  id: "262af487-b0f6-4658-ab89-99ad06bafc60"->Uuid.parseExn,
  contributedBy: None,
  description: "Get the current status message for a GitHub user.
",
  services: ["github"],
  body: "query GitHubStatus($login: String!) {
  gitHub {
    user(login: $login) {
      status {
        message
        emoji
        emojiHTML
        expiresAt
        indicatesLimitedAvailability
      }
    }
  }
}",
  kind: Query,
}

let gitHubStatusChangeNotification = {
  title: "GitHubStatusChangeNotification",
  id: "812d3bb6-7552-41c6-8899-944a67cd7128"->Uuid.parseExn,
  contributedBy: Some("@sgrove"),
  description: "Be notified when a user updates their status on GitHub",
  kind: Subscription,
  services: ["github"],
  body: "subscription GitHubStatusChangeNotification($login: String!, $pollingFrequencyInMinutes: Int = 1, $webhookUrl: String!) {
  poll(
    schedule: {every: {minutes: $pollingFrequencyInMinutes}}
    onlyTriggerWhenPayloadChanged: true
    webhookUrl: $webhookUrl
  ) {
    query {
      gitHub {
        user(login: $login) {
          status {
            emoji
            emojiHTML
            expiresAt
            indicatesLimitedAvailability
            message
          }
        }
      }
    }
  }
}
",
}
let watchTwitterFollower = {
  title: "WatchTwitterFollowers",
  id: "ba5bcd62-ddc9-4195-9e5f-e87e8c6d812c"->Uuid.parseExn,
  contributedBy: Some("@sgrove"),
  kind: Subscription,
  services: ["twitter"],
  description: "Watch for Twitter follower count change",
  body: "subscription WatchTwitterFollowers($twitterHandle: String!) {
  poll(
    schedule: { every: { minutes: 1 } }
    onlyTriggerWhenPayloadChanged: true
    webhookUrl: \"https://serve.onegraph.com/webhook/null\"
  ) {
    query {
      twitter {
        user(screenName: $twitterHandle) {
          followersCount
        }
      }
    }
  }
}",
}

let insertFollowersMutation = {
  title: "InsertFollowersMutation",
  id: "bd8c0be8-16e0-40ed-9ef8-5b9c2a9b822f"->Uuid.parseExn,
  contributedBy: Some("@sgrove"),
  kind: Mutation,
  services: ["google"],
  description: "Watch for Twitter follower count change",
  body: "mutation InsertFollowersMutation(
  $sheetId: String!
  $sheetName: String = \"Sheet1\"
  $followerCount: String!
  $timestamp: String!
) {
  google {
    sheets {
      appendValues(
        id: $sheetId
        majorDimenson: \"ROWS\"
        range: $sheetName
        valueInputOption: \"RAW\"
        insertDataOption: \"INSERT_ROWS\"
        values: [
          [
            $followerCount
            $timestamp
          ]
        ]
      ) {
        spreadsheetId
        updates {
          updatedCells
          updatedColumns
        }
      }
    }
  }
}",
}

let slackReactionEvent = {
  title: "SlackReactionSubscription",
  id: "900b0c65-9953-4921-9428-4e30232d3872"->Uuid.parseExn,
  contributedBy: Some("@sgrove"),
  kind: Subscription,
  services: ["slack"],
  description: "Get notified when a reaction is added to a message",
  body: "subscription SlackReactionSubscription {
  slack(webhookUrl: \"https://serve.onegraph.com/webhook/null\") {
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
}
",
}

let addToDocMutation = {
  title: "AddToDocMutation",
  id: "2ebf702b-5c89-4bab-9f4b-2a5860f13de0"->Uuid.parseExn,
  kind: Mutation,
  contributedBy: Some("@daniel"),
  description: "",
  services: ["google"],
  body: "mutation AddToDocMutation($sheetId: String!, $row: [String!]!) {
  google {
    sheets {
      appendValues(
        id: $sheetId
        valueInputOption: \"USER_ENTERED\"
        majorDimenson: \"ROWS\"
        range: \"'Raw Data'!A1\"
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
",
}

let blocks = [
  {
    title: "AmILoggedIntoDevTo",
    id: "fc16a4bb-89ea-4885-93a1-3d42ff9d875a"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    description: "Tell if a user is logged in (either via an `$apiKey` or the OAuth flow).
Note: We'll deprecate this field in favor of `id` as with our other integrations if/when DEV adds an endpoint to retrieve information about the currently logged in user. However, this field can be safely relied on to work even after that happens.

You can find or create your DEV.to API keys in [the settings menu on dev.to](https://dev.to/settings/account)
",
    services: ["dev-to"],
    body: "query AmILoggedIntoDevTo($apiKey: String) {
  me(auths: { devToAuth: { apiKey: $apiKey } }) {
    devTo {
      isLoggedIn
    }
  }
}",
    kind: Query,
  },
  {
    title: "CreateDevToArticle",
    id: "df9d1ca1-3e72-4c82-8175-c072e619e3ec"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["dev-to"],
    description: "Creates an (unpublished) article on DEV.to

See the [Publishing and Unpublishing](SetDevToArticlePublished) example for how to publish the article after creating it.
",
    body: "mutation CreateDevToArticle($apiKey: String!) {
  devTo(auths: { devToAuth: { apiKey: $apiKey } }) {
    createArticle(
      input: {
        article: {
          title: \"Posting articles to dev.to from any programming language via GraphQL: An Exhaustive Guide\"
          bodyMarkdown: \"Just use OneGraph, of course!\"
          tags: [\"graphql\", \"onegraph\"]
        }
      }
    ) {
      article {
        bodyHtml
        bodyMarkdown
        id
        slug
        tags
        url
      }
    }
  }
}",
    kind: Mutation,
  },
  {
    title: "CreateDevToWebhook",
    id: "a444b655-f9ea-4c7e-8616-4213e6f0706a"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["dev-to"],
    description: "Creates a webhook that will be notified whenever an article is created or published on DEV.to

See the counter example on [Destroying a Webhook on DEV.to](DestroyDevToWebhook).

You can find or create your DEV.to API keys in [the settings menu on dev.to](https://dev.to/settings/account)
",
    body: "mutation CreateDevToWebhook($apiKey: String!) {
  devTo(auths: { devToAuth: { apiKey: $apiKey } }) {
    createWebhook(
      input: {
        webhookEndpoint: {
          source: \"OneGraph\"
          targetUrl: \"https://websmee.com/hook/dev-to-example?_websmee_inspect\"
          events: [
            \"article_created\"
            \"article_updated\"
          ]
        }
      }
    ) {
      webhook {
        id
        source
        targetUrl
        events
        createdAt
      }
    }
  }
}
",
    kind: Mutation,
  },
  {
    title: "DestroyDevToWebhook",
    id: "ccc225f9-7b87-46c0-8657-6b5d831b1f8f"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["dev-to"],
    description: "Destroys a webhook on DEV.to by its `id`.

See the counter example on [Creating a Webhook on DEV.to](CreateDevToWebhook).

You can find or create your DEV.to API keys in [the settings menu on dev.to](https://dev.to/settings/account)
",
    body: "mutation DestroyDevToWebhook($apiKey: String!, $id: Int!) {
  devTo(auths: { devToAuth: { apiKey: $apiKey } }) {
    destroyWebhook(input: { id: $id }) {
      webhook {
        id
        source
        targetUrl
        events
        createdAt
        user {
          name
          username
          twitterUsername
          githubUsername
          websiteUrl
          profileImage
          profileImage90
        }
      }
    }
  }
}",
    kind: Mutation,
  },
  {
    title: "FindMyDevToWebhooks",
    id: "13206aaf-93d9-4452-b1b3-aaa4358b2be6"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["dev-to"],
    description: "Lists all of the webhooks you've created on DEV.to

You can find or create your DEV.to API keys in [the settings menu on dev.to](https://dev.to/settings/account)
",
    body: "query FindMyDevToWebhooks($apiKey: String!) {
  me(auths: { devToAuth: { apiKey: $apiKey } }) {
    devTo {
      webhooks {
        id
        source
        targetUrl
        events
        createdAt
      }
    }
  }
}",
    kind: Query,
  },
  {
    title: "FindMyTwitchUserIdAndEmail",
    id: "2fd6b964-2f0e-4428-a53f-83d20995efb4"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["twitch-tv"],
    description: "Finds a few details about the user if they're logged into Twitch:

- Twitch `userId`
- email
- whether the email has been verified by Twitch (`emailVerified`)
- The display name (what you'd see in the Twitch chat)
",
    body: "query FindMyTwitchUserIdAndEmail {
  me {
    twitchTv {
      id
      email
      emailVerified
      displayName
    }
  }
}",
    kind: Query,
  },
  {
    title: "FindUserContributionToOrgCount",
    id: "d6b0e341-5da8-4c00-b424-a1d0e6027266"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["github"],
    description: "Finds out how many PRs have been merged across an org for a given user - use this to reward your community members, like Gatsby!
",
    body: "query FindUserContributionToOrgCount(
  # You\'ll need to format this string when fetching this query
  # at runtime.
  # For example, your JavaScript might look like:
  # const query = `org:${repoOwner} author:${username} type:pr is:merged`;
  $query: String = \"org:onegraph author:sgrove type:pr is:merged\"
) {
  gitHub {
    search(first: 1, query: $query, type: ISSUE) {
      contributionCount: issueCount
    }
  }
}
",
    kind: Query,
  },
  {
    title: "GetNpmPackageDownloads",
    id: "658fa568-0f76-4616-9c7f-e926cbed805d"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["npm"],
    description: "Get the downloads for a package on npm given the package name
",
    body: "query GetNpmPackageDownloads($name: String!) {
  npm {
    package(name: $name) {
      downloads {
        lastMonth {
          count
        }
      }
    }
  }
}",
    kind: Query,
  },
  {
    title: "AddPullRequestCommentMutation",
    id: "eb934b23-8d20-4507-bc3d-d85cbc2b913a"->Uuid.parseExn,
    // services: ["github"],
    contributedBy: None,
    description: "Add a comment to a pull request given its id - see the [GitHubGetPullRequest example](GitHubGetPullRequest) for how to find a PR's id given its repository and number.
",
    services: ["github"],
    body: "mutation AddPullRequestCommentMutation(
  $pullRequestId: ID!
  $body: String!
) {
  gitHub {
    addComment(
      input: { body: $body, subjectId: $pullRequestId }
    ) {
      subject {
        ... on GitHubPullRequest {
          id
          title
          comments {
            nodes {
              id
              body
            }
          }
        }
      }
    }
  }
}",
    kind: Mutation,
  },
  {
    title: "CreateBranchMutation",
    id: "c3f66bab-d8d7-4081-9a2f-c4d907db071c"->Uuid.parseExn,
    contributedBy: None,
    description: "Create a branch name `$branchName` (from `master`) on the GitHub project `${repoOwner}/${repoName}`
",
    services: ["github"],
    body: "mutation CreateBranchMutation(
  $repoOwner: String!
  $repoName: String!
  $branchName: String!
) {
  gitHub {
    createBranch_oneGraph(
      input: {
        branchName: $branchName
        repoName: $repoName
        repoOwner: $repoOwner
      }
    ) {
      ref_: ref {
        name
        id
      }
    }
  }
}
",
    kind: Mutation,
  },
  {
    title: "GitHubCreateIssueCommentMutation",
    id: "27c77920-dd82-4596-a293-bfc0e12128bb"->Uuid.parseExn,
    contributedBy: None,
    description: "Add a new comment on a GitHub issue.
",
    services: ["github"],
    body: "mutation GitHubCreateIssueCommentMutation {
  gitHub {
    addComment(
      input: {
        body: \"Comment added from OneGraph\"
        subjectId: \"MDU6SXNzdWU0MTQ4ODg3MTM=\"
      }
    ) {
      commentEdge {
        node {
          body
          url
        }
      }
    }
  }
}
",
    kind: Mutation,
  },
  {
    title: "UpdateFileMutation",
    id: "c50233e0-1331-4f83-bc67-8285af9ee41e"->Uuid.parseExn,
    contributedBy: None,
    services: ["github"],
    description: "Create a single commit on the GitHub project `${repoOwner}/${repoName}` that \"upserts\" (creates a new file if it doesn\'t exist, or updates it if it does).

For example, to add a new file \"/examples/MyExample.md\" to the [OneGraph GraphQL Docs Repository](https://github.com/OneGraph/graphql-docs/tree/master/src/examples), the following variables would work:
javascript
{
  \"repoName\": \"graphql-docs\",
  \"repoOwner\": \"OneGraph\",
  \"branchName\": \"master\",
  \"path\": \"src/examples/MyExample.md\",
  \"message\": \"Adding a new example\",
  \"content\": \"Example file content here\",
  \"sha\": null
}

Note that if you\'re _updating_ a file, you\'ll need to provide its *current* sha for the mutation to succeed. See the [GitHubGetFileShaAndContent example](GitHubGetFileShaAndContent) for how to find an existing file\'s sha.
",
    body: "mutation UpdateFileMutation(
  $repoOwner: String!
  $repoName: String!
  $branchName: String!
  $path: String!
  $message: String!
  $content: String!
  $sha: String!
) {
  gitHub {
    createOrUpdateFileContent_oneGraph(
      input: {
        message: $message
        path: $path
        repoName: $repoName
        repoOwner: $repoOwner
        branchName: $branchName
        plainContent: $content
        existingFileSha: $sha
      }
    ) {
      commit {
        message
      }
    }
  }
}
",
    kind: Mutation,
  },
  {
    title: "DeleteIssueById",
    id: "38c2109d-f1d5-403a-800e-b0439f622531"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["github"],
    description: "You\'ll need to find the GitHub issue id first (see the [GitHubFindIssueIdByNumber](GitHubFindIssueIdByNumber) example) to use as the argument to `issueId`.

Since issue ids are globally unique across every kind of object in GitHub, you won\'t need to add the repository owner/name, just the `id`!
javascript
{
  \"id\": \"MDU6SXNzdWU1NDUyNDk2ODg=\"
}
",
    body: "mutation DeleteIssueById($id: ID!) {
  gitHub {
    deleteIssue(input: { issueId: $id }) {
      repository {
        issues(
          first: 0
          orderBy: { direction: DESC, field: CREATED_AT }
        ) {
          totalCount
        }
      }
    }
  }
}",
    kind: Mutation,
  },
  {
    title: "GitHubFindIssueIdByNumber",
    id: "fa51e70b-3918-4814-af03-11267f5b55d6"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["github"],
    description: "Given a repository `$repoOwner`/`$repoName`, find the id of an issue by its `$number`.

Usually users think of \"issue #10\", but most GitHub GraphQL mutations refer to issues by their id, so you\'ll find this query quite helpful! For example, you\'ll need the issue id if you want to [Delete a GitHub issue](GitHubDeleteIssueById).


To find the id of issue #3 on the [OneGraph GraphQL Docs Repository](https://github.com/OneGraph/graphql-docs/issues/1), we could pass in the following variables:
  
  ```javascript
  {
    \"repoName\": \"graphql-docs\",
    \"repoOwner\": \"OneGraph\",
    \"number\": 3
  }
  ```
",
    body: "query GitHubFindIssueIdByNumber(
  $repoOwner: String!
  $repoName: String!
  $number: Int!
) {
  gitHub {
    repository(owner: $repoOwner, name: $repoName) {
      issue(number: $number) {
        id
        title
      }
    }
  }
}",
    kind: Query,
  },
  {
    title: "GetFileTextContentsQuery",
    id: "78ff6314-a4cd-4bf4-adf9-783e5339ec02"->Uuid.parseExn,
    contributedBy: None,
    services: ["github"],
    description: "Get the (textual) value of a file in a GitHub repo via GraphQL
- `$branchAndFilePath` should be formatted as `${branchName}:${filePath without the leading\"/'}`

Note that the `text` field will be null if the file is a binary blog (such as an image).

If you need to read the binary content, email [support@onegraph.com](mailto:support@onegraph.com?subject=Can you add a base64-encoded binary content field to the `GitHubBlob` type on OneGraph?) and we can stitch in the [corresponding REST endpoint](https://developer.github.com/v3/git/blobs/#get-a-blob)
",
    body: "query GetFileTextContentsQuery($repoName: String!, $repoOwner: String!, $branchAndFilePath: String = \"master:README.md\") {
  gitHub {
    repository(name: $repoName, owner: $repoOwner) {
      object_: object(expression: $branchAndFilePath) {
        ... on GitHubBlob {
          sha: oid # alias this to `sha`, as that\'s a bit more familiar
          byteSize
          isBinary
          # Note the text content will be null if
          # `isBinary` is true
          text
        }
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "GetPullRequest",
    id: "42ccb1c1-cb45-4db7-be7a-17c22e063d80"->Uuid.parseExn,
    contributedBy: None,
    services: ["github"],
    description: "Get the details of a pull request by its number.

Also see:
- how to [Merge a Pull Request](GitHubMergePullRequest)
- how to [Add a comment to a Pull Request](GitHubAddPullRequestComment)
",
    body: "query GetPullRequest {
  gitHub {
    repository(owner: \"OneGraph\", name: \"graphql-docs\") {
      pullRequest(number: 1) {
        id # The `id` is useful if you want to add a comment to the PR
        headRefOid # The `headRefOid` sha is useful if you need to merge this PR
        title
        state
      }
    }
  }
}",
    kind: Query,
  },
  {
    title: "GitHubIsRepositoryAFork",
    id: "4730f263-e470-44af-a9ce-12812eb7080e"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["github"],
    description: "Given a GitHub `$repoOwner`/`$repoName`, find if the corresponding repository is fork (`gitHub.repository.isFork`) - and if so, what the original repository is `gitHub.repository.parent.nameWithOwner`.
",
    body: "query GitHubIsRepositoryAFork(
  $repoOwner: String!
  $repoName: String!
) {
  gitHub {
    repository(owner: $repoOwner, name: $repoName) {
      id
      ## Is this repository a fork?
      isFork
      parent {
        ## if it is a fork, what's the original?
        nameWithOwner
      }
    }
  }
}",
    kind: Query,
  },
  {
    title: "MergePullRequest",
    id: "fee8f921-f984-4ac0-b8c4-298a102a3f0f"->Uuid.parseExn,
    contributedBy: None,
    services: ["github"],
    description: "Merge a GitHub pull request by its number with `$title` as the commit message.

Note as a precaution against merging a PR into the wrong target, you\'ll need to provide the current sha of the target branch head. You can find the sha under the `headRef.oid` field of the Pull Request, as per the [GitHubGetPullRequest example](GitHubGetPullRequest)

To merge the first PR on the [OneGraph GraphQL Docs Repository](https://github.com/OneGraph/graphql-docs/pulls/1), we could pass in the following variables:
javascript
{
  \"repoName\": \"graphql-docs\",
  \"repoOwner\": \"OneGraph\",
  \"number\": 1,
  \"title\": \"Merge the GitHub examples, thank you @dwwoelfel!\",
  \"sha\": \"44d4e20fd739f486411049b7e94849d7b3332770\"
}
",
    body: "mutation MergePullRequest(
  $repoOwner: String!
  $repoName: String!
  $number: Int!
  $sha: String!
  $title: String!
) {
  gitHub {
    mergePullRequest_oneGraph(
      input: {
        repoOwner: $repoOwner
        repoName: $repoName
        number: $number
        sha: $sha
        commitTitle: $title
      }
    ) {
      pullRequest {
        id
        title
        merged
        state
      }
    }
  }
}
",
    kind: Mutation,
  },
  {
    title: "GitHubOpenPullRequestsQuery",
    id: "688de94a-95a7-4cae-893f-ec66b2791a65"->Uuid.parseExn,
    contributedBy: None,
    services: ["github"],
    description: "Fetch the first ten open pull requests for a GitHub repository, sorted by when they were opened.
",
    body: "query GitHubOpenPullRequestsQuery {
  gitHub {
    repository(name: \"graphql-js\", owner: \"graphql\") {
      pullRequests(
        orderBy: {direction: DESC, field: CREATED_AT}
        first: 10
        states: OPEN
      ) {
        nodes {
          title
        }
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "GitHubUnresolvedIssuesQuery",
    id: "1a8b5ab8-1682-4f58-9ff8-0aa25b167ff3"->Uuid.parseExn,
    contributedBy: None,
    services: ["github"],
    description: "Fetch the first ten open issues for a GitHub repository, sorted by when they were created.
",
    body: "query GitHubUnresolvedIssuesQuery {
  gitHub {
    viewer {
      issues(
        orderBy: {direction: DESC, field: CREATED_AT}
        first: 10
        states: OPEN
      ) {
        edges {
          node {
            title
            repository {
              nameWithOwner
            }
          }
        }
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "IntercomCreateUserMutation",
    id: "c8aed900-23ea-42d8-85ee-6be09146d36e"->Uuid.parseExn,
    contributedBy: None,
    services: ["intercom"],
    description: "Create a new user on Intercom.
",
    body: "mutation IntercomCreateUserMutation {
  intercom {
    createUser(input: {email: \"newuser@example.com\", name: \"New User\"}) {
      user {
        id
        email
      }
    }
  }
}
",
    kind: Mutation,
  },
  {
    title: "IntercomOpenConversations",
    id: "0e76d866-b536-4375-a039-aacee06809fc"->Uuid.parseExn,
    contributedBy: None,
    services: ["intercom"],
    description: "List open conversations on Intercom.
",
    body: "query IntercomOpenConversations {
  intercom {
    conversations(
      displayAsPlaintext: true
      orderBy: ASC
      sortByField: WAITING_SINCE
    ) {
      nodes {
        conversationMessage {
          body
        }
        customers {
          name
          email
        }
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "IntercomUsersWithConversationsQuery",
    id: "eaf18a0d-7330-4787-ae26-08895681ef12"->Uuid.parseExn,
    contributedBy: None,
    services: ["intercom"],
    description: "List Intercom conversations for users that have been active recently.
",
    body: "query IntercomUsersWithConversationsQuery {
  intercom {
    users(first: 10, orderBy: DESC, sortByField: LAST_REQUEST_AT) {
      nodes {
        email
        conversations(displayAsPlaintext: true) {
          nodes {
            id
            conversationMessage {
              body
            }
          }
        }
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "IsDomainAvailableQueryOnZeit",
    id: "d72c91f8-ab50-417e-aaaa-50cee543871f"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    description: "Check if a domain is available on Zeit
",
    services: ["zeit"],
    body: "query IsDomainAvailableQuery($domain: String!) {
  zeit {
    domainAvailable(name: $domain) {
      available
    }
  }
}",
    kind: Query,
  },
  {
    title: "MuxCreateVideoAsset",
    id: "3fb362ac-440b-4876-9f74-23eae7009e4b"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["mux"],
    description: "Create a video asset on Mux with a source video, an image overlay, and textual subtitles.

You\'ll need your Mux access token `id`/`secret` for the variables (find them on the [Mux dashboard settings](https://dashboard.mux.com/settings/access-tokens)):

{
  \"secret\": \"mymuxsecret\",
  \"tokenId\": \"mytokenid\"
}
",
    body: "mutation MuxCreateVideoAsset($secret: String!, $tokenId: String!) {
  mux(auths: {muxAuth: {accessToken: {secret: $secret, tokenId: $tokenId}}}) {
    createAsset(
      input: {
        # The source video to start with (thanks to http://techslides.com/sample-webm-ogg-and-mp4-video-files-for-html5 for providing this!)
        sourceUrl: \"http://techslides.com/demos/sample-videos/small.mp4\"
        # Any images we want to overlay on top of the video
        imageInputs: [
          {
            url: \"https://avatars2.githubusercontent.com/u/35296?s=460&u=9753e52e664dba2ab83b2c08b9a6cc90a5cac7bb&v=4\"
            overlaySettings: {
              verticalAlign: BOTTOM
              horizontalAlign: LEFT
              verticalMargin: \"5%\"
              horizontalMargin: \"5%\"
              width: \"15%\"
              height: \"15%\"
            }
          }
        ]
        # Subtitles or closed captions: each will be included as a separate option in the final video
        textualInputs: [
          {
            url: \"https://egghead.io/api/v1/lessons/graphql-use-graphql-primitive-types/subtitles\"
            textType: SUBTITLES
            languageCode: \"en\"
            name: \"English\"
            passthrough: \"Data attached to this subtitle resource\"
          }
        ]
        # Metadata to control permissions for the playback, to attach some custom data to the resource, set the mp4 support level, etc.
        settings: {
          isTest: false
          masterAccess: TEMPORARY
          mp4Support: STANDARD
          normalizeAudio: true
          passthrough: \"{\\\"json-also-works\\\": true}\"
          perTitleEncode: true
          playbackPolicy: PUBLIC
          demo: false
        }
      }
    ) {
      # Our created asset!
      asset {
        ...MuxVideoAssetFragment
      }
    }
  }
}

fragment MuxVideoAssetFragment on MuxVideoAsset {
  isLive
  id
  isTest
  errors {
    type
    messages
  }
  playbackIds {
    id
    policy
  }
  status
}
",
    kind: Mutation,
  },
  {
    title: "MuxListVideoAssetNoPaginationQuery",
    id: "97202a25-b47d-48af-96f5-cd14725d0e6d"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["mux"],
    description: "List your video asset on Mux (without pagination).

You\'ll need your Mux access token `id`/`secret` for the variables (find them on the [Mux dashboard settings](https://dashboard.mux.com/settings/access-tokens)):

{
  \"secret\": \"mymuxsecret\",
  \"tokenId\": \"mytokenid\"
}
",
    body: "query MuxListAssetQuery(
  $secret: String!
  $tokenId: String!
) {
  mux(
    auths: {
      muxAuth: {
        accessToken: { secret: $secret, tokenId: $tokenId }
      }
    }
  ) {
    video {
      assets {
        edges {
          node {
            ...MuxVideoAssetFragment
          }
        }
      }
    }
  }
}

fragment MuxVideoAssetFragment on MuxVideoAsset {
  isLive
  id
  isTest
  errors {
    type
    messages
  }
  playbackIds {
    id
    policy
  }
  status
}",
    kind: Query,
  },
  {
    title: "MuxVideoAssetByOneGraphNodeId",
    id: "22211818-3225-47bf-87c6-be8028f54123"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["mux"],
    description: "Look up a Mux video asset directly by its oneGraphNodeId.

You\'ll need your Mux access token `id`/`secret` for the variables (find them on the [Mux dashboard settings](https://dashboard.mux.com/settings/access-tokens)):

{
  \"secret\": \"mymuxsecret\",
  \"tokenId\": \"mytokenid\"
}
",
    body: "query MuxVideoAssetByOneGraphNodeId(
  $tokenId: String!
  $secret: String!
  $oneGraphNodeId: ID!
) {
  oneGraphNode(
    auths: {
      muxAuth: {
        accessToken: { secret: $secret, tokenId: $tokenId }
      }
    }
    oneGraphId: $oneGraphNodeId
  ) {
    ... on MuxVideoAsset {
      ...MuxVideoAssetFragment
    }
  }
}

fragment MuxVideoAssetFragment on MuxVideoAsset {
  isLive
  id
  isTest
  errors {
    type
    messages
  }
  playbackIds {
    id
    policy
  }
  status
  oneGraphId
}",
    kind: Query,
  },
  {
    title: "MuxVideoAssetQuery",
    id: "8dd80b56-1d1a-4fce-97cd-b63d3f63526c"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["mux"],
    description: "Find a VideoAsset on Mux via its id.

You\'ll need your Mux access token `id`/`secret` for the variables (find them on the [Mux dashboard settings](https://dashboard.mux.com/settings/access-tokens)), and the id of your Mux asset:

{
  \"secret\": \"mymuxsecret\"
  \"tokenId\": \"mytokenid\"
  \"id\": \"assetId\"
}
",
    body: "query MuxAssetQuery(
  $id: String!
  $secret: String!
  $tokenId: String!
) {
  mux(
    auths: {
      muxAuth: {
        accessToken: { secret: $secret, tokenId: $tokenId }
      }
    }
  ) {
    video {
      asset(id: $id) {
        ...MuxVideoAssetFragment
      }
    }
  }
}

fragment MuxVideoAssetFragment on MuxVideoAsset {
  isLive
  id
  isTest
  errors {
    type
    messages
  }
  playbackIds {
    id
    policy
  }
  status
}",
    kind: Query,
  },
  {
    title: "MyDevToArticlesPendingPublication",
    id: "8fdae3d2-cd71-429f-9e93-74a669ab7094"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["dev-to"],
    description: "Finds all articles I've written on DEV.to (sorted by recency) that haven't been published yet.
",
    body: "query MyDevToArticlesPendingPublication($apiKey: String!) {
  me(auths: { devToAuth: { apiKey: $apiKey } }) {
    devTo {
      articles(publishStatus: UNPUBLISHED) {
        nodes {
          id
          title
          bodyMarkdown
        }
      }
    }
  }
}",
    kind: Query,
  },
  {
    title: "RecentlyRisingTopArticles",
    id: "71d791bc-80d1-47d9-800b-d7d41059dd34"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["dev-to"],
    description: "Find the recently rising top articles on DEV
",
    body: "query RecentlyRisingTopArticles {
  devTo {
    articles(state: \"rising\") {
      nodes {
        id
        title
        url
        socialImage
        publishedAt
        user {
          name
          username
          githubUsername
        }
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "RssFeeds",
    id: "27abfd2c-02e6-42b4-bfe5-99fe838d00a8"->Uuid.parseExn,
    contributedBy: Some("@dabit3"),
    services: ["rss"],
    description: "You can build a podcast player with GraphQL simply by passing in a `$url` param, for example:

{\"url\": \"https://feeds.simplecast.com/tRYUp5wn\"}
",
    body: "query RssFeed($url: String!) {
  rss {
    rss2Feed(url: $url) {
      title
      items {
        title
        ## Enclosure contains the link to the podcast audio
        enclosure {
          url # Use this in an <audio src=\"\"> tag for a podcast player!
          length
          mime
        }
        content
        description
      }
    }
  }
}",
    kind: Query,
  },
  {
    title: "SalesforceCasesQuery",
    id: "c0b24dcd-1f05-46f9-bea0-2d8aa038883f"->Uuid.parseExn,
    contributedBy: None,
    services: ["salesforce"],
    description: "List open cases on Salesforce.
",
    body: "query SalesforceCasesQuery {
  salesforce {
    cases(
      filter: {status: {notEqualTo: \"Closed\"}}
      sortByField: PRIORITY
      orderBy: ASC
    ) {
      edges {
        node {
          id
          status
          priority
        }
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "SalesforceLeadsQuery",
    id: "06fa326f-464c-4d03-aefa-4b5f9875d51c"->Uuid.parseExn,
    contributedBy: None,
    description: "List leads on Salesforce, ordered by when they were created.
",
    services: ["salesforce"],
    body: "query SalesforceLeadsQuery {
  salesforce {
    leads(sortByField: CREATED_DATE, orderBy: DESC, first: 10) {
      nodes {
        firstName
        lastName
        email
        createdDate
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "SalesforceOpportunitiesQuery",
    id: "9b67d6cf-a422-417c-9e32-4dfb12f133cf"->Uuid.parseExn,
    contributedBy: None,
    services: ["salesforce"],
    description: "List Opportunities on Salesforce, where the account has more then 10 employees.
",
    body: "query SalesforceOpportunitiesQuery {
  salesforce {
    opportunities(
      first: 10
      filter: {account: {numberOfEmployees: {greaterThan: 10}}}
    ) {
      nodes {
        name
        expectedRevenue
        probability
        stageName
        account {
          name
          numberOfEmployees
        }
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "SetDevToArticlePublished",
    id: "c0cad642-8fa0-43f8-b84c-64c06340c948"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["dev-to"],
    description: "Publishes (and un-publishes) an article by its `id` (`$articleId`).

You can find or create your DEV.to API keys in [the settings menu on dev.to](https://dev.to/settings/account)
",
    body: "mutation SetDevToArticlePublished(
  $apiKey: String!
  $articleId: Int!
  $isPublished: Boolean!
) {
  devTo(auths: { devToAuth: { apiKey: $apiKey } }) {
    setArticlePublished(
      input: { id: $articleId, published: $isPublished }
    ) {
      article {
        bodyHtml
        bodyMarkdown
        id
        slug
        tags
        publishedAt
        publishedTimestamp
        url
      }
    }
  }
}",
    kind: Mutation,
  },
  {
    title: "SpecificRangeInGoogleSheets",
    id: "28bf49b2-1d8f-4f8f-8ccb-7eb2acaf397e"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["google"],
    description: "Reads from a specific range of cells in a Google sheets
",
    body: "query SpecificRangeInGoogleSheets(
  # The id of the sheet to pull data from, in
  # https://docs.google.com/spreadsheets/d/1CRUduucIQKot-Bwvh4teSblQTWPsIoNUs6AGLAg7Sjs/edit
  # it would be \"1CRUduucIQKot-Bwvh4teSblQTWPsIoNUs6AGLAg7Sjs\"
  $id: String!
  # Normal syntax for selecting ranges in sheets
  $ranges: String = \"e12:f16\"
) {
  google {
    sheets {
      sheet(
        id: $id
        ranges: $ranges
        includeGridData: true
      ) {
        sheets {
          data {
            rowData {
              values {
                formattedValue
              }
            }
          }
        }
      }
    }
  }
}",
    kind: Query,
  },
  {
    title: "AboutMe",
    id: "7f31ca47-3715-4c95-8a19-a897078ce98b"->Uuid.parseExn,
    contributedBy: None,
    description: "Find the currently logged-in Spotify user's email, name, profile image, etc. from GraphQL!
",
    services: ["spotify"],
    body: "## Find some information about the currently logged-in
## Spotify user.
query AboutMe {
  me {
    spotify {
      country
      displayName
      email
      href
      id
      images {
        height
        url
        width
      }
      product
      type
      uri
    }
  }
}
",
    kind: Query,
  },
  {
    title: "FullPlayer",
    id: "ac28feb9-dbed-4116-afb1-d9bce22a8629"->Uuid.parseExn,
    contributedBy: None,
    services: ["spotify"],
    description: "Control your Spotify player completely from GraphQL!

- Find the currently logged-in Spotify user with `AboutMe`
- Search for matching Spotify tracks (songs) with the GraphQL operation `Search`
- Use the mutations (`Resume`/`Pause`/`Next`/`Previous`/`Play`) to control the Spotify player
",
    body: "query Search($query: String!) {
  spotify {
    search(data: { query: $query }) {
      tracks {
        name
        id
        album {
          name
          id
          images {
            height
            url
            width
          }
          href
        }
        href
      }
    }
  }
}

## Find some information about the currently logged-in
## Spotify user.
query AboutMe {
  me {
    spotify {
      birthdate
      country
      displayName
      email
      href
      id
      images {
        height
        url
        width
      }
      product
      type
      uri
    }
  }
}

## Note that by default this will affect the
## currently active device. If you get an error,
## either specify `deviceId`, or start playing
## a song on any of your Spotify devices.
mutation Pause {
  __typename
  spotify {
    pausePlayer {
      player {
        ...Player
      }
    }
  }
}

mutation Resume {
  __typename
  spotify {
    skipNextTrack {
      player {
        ...Player
      }
    }
  }
}

mutation Next {
  __typename
  spotify {
    skipPreviousTrack {
      player {
        ...Player
      }
    }
  }
}

fragment Player on SpotifyPlayer {
  timestamp
  progressMs
  isPlaying
  currentlyPlayingType
  repeatState
  shuffleState
  item {
    id
    name
  }
}",
    kind: Query,
  },
  {
    title: "Search",
    id: "ac28feb9-dbed-4116-afb1-d9bce22a8629"->Uuid.parseExn,
    contributedBy: None,
    services: ["spotify"],
    description: "Search for matching Spotify tracks (songs) with the GraphQL operation `Search`",
    body: "query Search($query: String!) {
  spotify {
    search(data: { query: $query }) {
      tracks {
        name
        id
        album {
          name
          id
          images {
            height
            url
            width
          }
          href
        }
        href
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "SpotifyPlayTrack",
    id: "5be36d92-3012-411e-861e-fb51640482e0"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["spotify"],
    description: "Get pumped at GraphQL Asia!
",
    body: `mutation SpotifyPlayTrack($trackId: String = "12PNcnMsjsZ3eHm62t8hiy") {
  spotify {
    playTrack(
      input: {
        trackIds: [$trackId]
        positionMs: 69500
      }
    ) {
      player {
        isPlaying
      }
    }
  }
}`,
    kind: Mutation,
  },
  {
    title: "StripeCustomersQuery",
    id: "ee7505c6-99b8-4073-9183-051dd89ed74c"->Uuid.parseExn,
    contributedBy: None,
    services: ["stripe"],
    description: "List customers on Stripe.
",
    body: "query StripeCustomersQuery {
  stripe {
    customers {
      nodes {
        email
        description
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "StripeIssueRefundMutation",
    id: "b229bbcf-f370-4df0-a00d-06b5be888a86"->Uuid.parseExn,
    contributedBy: None,
    services: ["stripe"],
    description: "Issue a refund for a charge on Stripe.
",
    body: "mutation StripeIssueRefundMutation {
  stripe {
    refundCharge(data: {chargeId: \"YOUR_CHARGE_ID\"}) {
      refund {
        amount
        charge {
          customer {
            ... on StripeCustomer {
              email
            }
          }
        }
        id
      }
    }
  }
}
",
    kind: Mutation,
  },
  {
    title: "StripeListRefundsQuery",
    id: "6bc549bd-8f28-4426-a12e-504aa2a9f0b4"->Uuid.parseExn,
    contributedBy: None,
    services: ["stripe"],
    description: "List refunds with charge and customer info on Stripe.
",
    body: "query StripeListRefundsQuery {
  stripe {
    refunds {
      nodes {
        reason
        amount
        status
        charge {
          customer {
            ... on StripeCustomer {
              email
            }
          }
        }
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "StripeInvoicesQuery",
    id: "c90242a6-9b17-4931-bf2d-e44dc283325b"->Uuid.parseExn,
    contributedBy: None,
    services: ["stripe"],
    description: "List unpaid invoices on Stripe.
",
    body: "query StripeInvoicesQuery {
  stripe {
    invoices(first: 10, status: open) {
      nodes {
        amountDue
        paid
        customer {
          ... on StripeCustomer {
            email
            description
          }
        }
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "TrelloCreateCardMutation",
    id: "0b5a8474-c206-4b0b-b660-7ef2ed543049"->Uuid.parseExn,
    contributedBy: None,
    services: ["trello"],
    description: "Add a new card to a Trello list.
",
    body: "mutation TrelloCreateCardMutation {
  trello {
    createCard(
      input: {
        idList: \"REPLACE_WITH_LIST_ID\"
        name: \"New card created from OneGraph\"
      }
    ) {
      card {
        id
        name
        url
      }
    }
  }
}
",
    kind: Mutation,
  },
  {
    title: "TrelloListBoardsQuery",
    id: "587f3854-5ee1-46b8-8a9c-8d184875f874"->Uuid.parseExn,
    contributedBy: None,
    description: "Get all boards and cards on Trello for a given user.
",
    services: ["trello"],
    body: "query TrelloListBoardsQuery {
  trello {
    member(username: \"spolsky\") {
      boards {
        nodes {
          name
          cards {
            nodes {
              name
            }
          }
        }
      }
    }
  }
}
",
    kind: Query,
  },
  {
    title: "TrelloMemberInfo",
    id: "262af487-b0f6-4658-ab89-99cd06bafc60"->Uuid.parseExn,
    contributedBy: None,
    services: ["trello"],
    description: "Get profile information on a Trello user.
",
    body: "query TrelloMemberInfo {
  trello {
    member(username: \"spolsky\") {
      fullName
      bio
      avatarUrl
      url
      email
    }
  }
}
",
    kind: Query,
  },
  {
    title: "UpdateGitHubUserProfile",
    id: "cfeff87c-486a-445d-b388-a620e51810ea"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["github"],
    description: "Updates the currently authenticated GitHub user's profile. To run this, you'll need to either use a personal access token, or you'll need to make a custom GitHub app that requests the `user` permission. 

Once you've made a custom GitHub app, set the client id/secret for it in your OneGraph dashboard, authenticate a user, and run this mutation!
",
    body: "mutation UpdateGitHubUserProfile(
  $hireable: Boolean
  $name: String
  $twitterUsername: String
  $bio: String
) {
  gitHub {
    # Note that you'll need a custom GitHub app
    # with the `user` permission requested in
    # order to update a user's profile
    updateAuthenticatedUser_oneGraph(
      input: {
        bio: $bio
        hireable: $hireable
        name: $name
        twitterUsername: $twitterUsername
      }
    ) {
      updatedUser {
        bio
        email
      }
    }
  }
}",
    kind: Mutation,
  },
  {
    title: "PostSimpleMarkdownSlackMessage",
    id: "cfeff87d-486a-445d-b388-a620e51810ea"->Uuid.parseExn,
    contributedBy: Some("@sgrove"),
    services: ["github"],
    description: "TODO",
    body: "mutation PostSimpleMarkdownSlackMessage(
  $channel: String!
  $text: String!
) {
  slack {
    postMessage(
      data: {
        channel: $channel
        markdown: true
        text: $text
      }
    ) {
      ok
    }
  }
}",
    kind: Mutation,
  },
  createAssetWithStuff,
  gitHubStatusChangeNotification,
  setSlackStatus,
  gitHubStatus,
  insertFollowersMutation,
  gitHubUserFragment,
]

let blockServices = (~schema, block: block): array<GraphQLUtils.service> => {
  block.body->GraphQLJs.parse->GraphQLUtils.gatherAllReferencedServices(~schema)
}

let getFirstVariables = (block: block): array<(string, string)> => {
  let ast = GraphQLJs.parse(block.body)

  ast.definitions->Belt.Array.get(0)->Belt.Option.getExn->GraphQLUtils.getOperationVariables
}
