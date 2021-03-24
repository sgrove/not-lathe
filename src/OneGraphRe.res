@module("./OneGraph.js")
external fetchOneGraph: (
  OneGraphAuth.t,
  string,
  option<string>,
  option<Js.Json.t>,
) => Js.Promise.t<GraphQLJs.introspectionQueryResult> = "fetchOneGraph"

@module("./OneGraph.js")
external persistQuery: (
  ~appId: string,
  ~persistQueryToken: string,
  ~queryToPersist: string,
  ~freeVariables: array<string>,
  ~accessToken: option<string>,
  ~fixedVariables: option<Js.Json.t>,
  ~onComplete: Js.Json.t => unit,
) => unit = "persistQuery"

@module("./OneGraph.js")
external basicFetchOneGraphPersistedQuery: (
  ~appId: string,
  ~accessToken: option<OneGraphAuth.t>,
  ~docId: string,
  ~variables: option<Js.Json.t>,
  ~operationName: option<string>,
) => Js.Promise.t<GraphQLJs.queryResult> = "basicFetchOneGraphPersistedQuery"

@module("./OneGraph.js")
external fetchOneGraphPersistedQuery: (
  ~oneGraphAuth: option<OneGraphAuth.t>,
  ~docId: string,
  ~operationName: option<string>,
  ~variables: option<Js.Json.t>,
) => Js.Promise.t<GraphQLJs.queryResult> = "fetchOneGraphPersistedQuery"

module GitHub = {
  type projectType =
    | Netlify([#nextjs | #any])
    | Unknown
    | Nextjs

  let friendlyOfProjectType = t =>
    switch t {
    | Netlify(#nextjs) => "Next.js on Netlify"
    | Netlify(#any) => "Netlify Site"
    | Unknown => "Unknown"
    | Nextjs => "Next.js"
    }

  let _guessProjecType: (
    ~owner: string,
    ~name: string,
  ) => Js.Promise.t<string> = %raw(`async function listRepositories(owner, name) {
let resp = await fetch("https://serve.onegraph.com/graphql?app_id=993a3e2d-de45-44fa-bff4-0c58c6150cbf",
  {
    method: "POST",
    "Content-Type": "application/json",
    body: JSON.stringify({
      "doc_id": "14d10e67-0c1f-473e-8959-696a9fb90963",
      "operationName": "ExecuteChainMutation_hello_onegraph_its_netlify",
      "variables": {"owner": owner, "name": name}
      }
    )
  }
)

let res = await resp.json()


const value = res?.data?.oneGraph?.executeChain?.results?.find(res => res?.request?.id === 'ProjectType')?.result?.[0]?.data?.oneGraph?.identity

console.log(owner, name, value, res)

return value
}`)

  let guessProjecType = (~owner, ~name) => {
    _guessProjecType(~owner, ~name)->Js.Promise.then_(result => {
      let typ = switch result {
      | "next.js" => Nextjs
      | "netlify/next.js" => Netlify(#nextjs)
      | "netlify/*" => Netlify(#any)
      | "unknown"
      | _ =>
        Unknown
      }

      Js.log3(owner, name, friendlyOfProjectType(typ))
      typ->Js.Promise.resolve
    }, _)
  }

  type treeFile = {
    path: string,
    content: string,
    mode: string,
  }

  let pushToRepo: {
    "owner": string,
    "name": string,
    "branch": string,
    "message": string,
    "treeFiles": array<treeFile>,
    "acceptOverrides": bool,
  } => Js.Promise.t<{..}> = %raw(`async function pushToRepo(variables){
const resp = await fetch("https://serve.onegraph.com/graphql?app_id=993a3e2d-de45-44fa-bff4-0c58c6150cbf",
  {
    method: "POST",
    "Content-Type": "application/json",
    body: JSON.stringify({
      "doc_id": "93e83185-a2b3-4b20-9cfd-34d2d0bb2e91",
      "operationName": "ExecuteChainMutation_og_studio_dev_chain",
      "variables": variables
      }
    )
  }
)

let res = await resp.json()

return res
}`)
}
