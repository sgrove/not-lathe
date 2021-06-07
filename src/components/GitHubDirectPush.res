type repoNode = {
  id: string,
  nameWithOwner: string,
}

type repoEdge = {node: repoNode}

type projectTypeGuess = option<OneGraphRe.GitHub.projectType>

type state = {
  repoList: option<array<repoEdge>>,
  selectedRepo: option<repoEdge>,
  repoProjectGuess: projectTypeGuess,
}

@react.component
let make = (~schema, ~chain: Chain.t, ~savedChainId, ~oneGraphAuth) => {
  let loadedChain = Some(chain)
  // Chain.loadFromLocalStorage()->Belt.Array.getBy(chain =>
  //   chain.id == savedChainId->Belt.Option.map(Uuid.parseExn)
  // )

  let appId = oneGraphAuth->OneGraphAuth.appId

  open React

  let remoteChainCalls =
    savedChainId->Belt.Option.flatMap(chainId =>
      loadedChain->Belt.Option.map(loadedChain =>
        Compiler.Exports.remoteChainCalls(~schema, ~appId, ~chainId, loadedChain)
      )
    )

  let (state, setState) = React.useState(() => {
    repoList: None,
    selectedRepo: None,
    repoProjectGuess: None,
  })

  React.useEffect0(() => {
    Debug.assignToWindowForDeveloperDebug(
      ~name="guessGitHubProject",
      OneGraphRe.GitHub.guessProjectType,
    )
    OneGraphRe.basicFetchOneGraphPersistedQuery(.
      ~appId="993a3e2d-de45-44fa-bff4-0c58c6150cbf",
      ~accessToken=None,
      ~docId="fc839e0e-982b-43fc-b59b-3c080e17480a",
      ~operationName=Some("ExecuteChainMutation_look_ma_connections"),
      ~variables=None,
    )
    ->Js.Promise.then_(result => {
      Obj.magic(result)["data"]
      ->Js.Undefined.toOption
      ->Belt.Option.forEach(data => {
        try {
          data["oneGraph"]["executeChain"]["results"]
          ->Belt.Array.getBy(result => result["request"]["id"] == "ListMyRepositories")
          ->Belt.Option.forEach(request => {
            let repos = request["result"][0]["data"]["me"]["github"]["repositories"]["edges"]
            setState(oldState => {
              {...oldState, repoList: repos}
            })
          })
        } catch {
        | ex =>
          Js.Console.warn2("Exception while fetching GitHub Repo list", ex)
          ()
        }
      })
      ->Js.Promise.resolve
    }, _)
    ->ignore

    None
  })

  {
    state.repoList->Belt.Option.mapWithDefault(React.null, repoList => {
      <>
        <div className=" text-center" style={ReactDOMStyle.make(~color=Comps.colors["gray-4"], ())}>
          {"- OR -"->React.string}
        </div>
        <Comps.Select
          style={ReactDOMStyle.make(~width="100%", ~margin="10px", ())}
          value={state.selectedRepo->Belt.Option.mapWithDefault("", repo => repo.node.id)}
          onChange={event => {
            let id = ReactEvent.Form.target(event)["value"]
            let repo = state.repoList->Belt.Option.flatMap(repoList =>
              repoList->Belt.Array.getBy(repoEdge => {
                repoEdge.node.id == id
              })
            )
            setState(oldState => {...oldState, selectedRepo: repo, repoProjectGuess: None})
            repo->Belt.Option.forEach(repo => {
              switch repo.node.nameWithOwner->Js.String2.split("/") {
              | [owner, name] =>
                OneGraphRe.GitHub.guessProjectType(~owner, ~name)->Js.Promise.then_(result => {
                  setState(oldState => {
                    ...oldState,
                    repoProjectGuess: Some(result),
                  })->Js.Promise.resolve
                }, _)->ignore
              | _ => ()
              }
            })
          }}>
          <option value="" />
          {repoList
          ->Belt.Array.map(repoEdge => {
            <option key={repoEdge.node.id} value={repoEdge.node.id}>
              {repoEdge.node.nameWithOwner->React.string}
            </option>
          })
          ->array}
        </Comps.Select>
        <Comps.Button
          disabled={state.repoProjectGuess->Belt.Option.isNone || savedChainId->Belt.Option.isNone}
          className="w-full"
          onClick={_ =>
            remoteChainCalls->Belt.Option.forEach(remoteChainCalls => {
              state.repoProjectGuess->Belt.Option.forEach(repoProjectGuess => {
                state.selectedRepo->Belt.Option.forEach(repo => {
                  switch repo.node.nameWithOwner->Js.String2.split("/") {
                  | [owner, name] =>
                    let content = switch repoProjectGuess {
                    | Unknown =>
                      remoteChainCalls.fetch->Prettier.format({
                        "parser": "babel",
                        "plugins": [Prettier.babel],
                        "singleQuote": true,
                      })
                    | Netlify(#any) =>
                      let code = remoteChainCalls.netlify.code

                      let fmt = s =>
                        s->Prettier.format({
                          "parser": "babel",
                          "plugins": [Prettier.babel],
                          "singleQuote": true,
                        })

                      Debug.assignToWindowForDeveloperDebug(~name="nextjscode", code)
                      Debug.assignToWindowForDeveloperDebug(~name="pfmt", fmt)

                      code->Prettier.format({
                        "parser": "babel",
                        "plugins": [Prettier.babel],
                        "singleQuote": true,
                      })
                    | Netlify(#nextjs)
                    | Nextjs =>
                      let code = remoteChainCalls.nextjs.code

                      let fmt = s =>
                        s->Prettier.format({
                          "parser": "babel",
                          "plugins": [Prettier.babel],
                          "singleQuote": true,
                        })

                      Debug.assignToWindowForDeveloperDebug(~name="nextjscode", code)
                      Debug.assignToWindowForDeveloperDebug(~name="pfmt", fmt)

                      code->Prettier.format({
                        "parser": "babel",
                        "plugins": [Prettier.babel],
                        "singleQuote": true,
                      })
                    }

                    let path = switch repoProjectGuess {
                    | Unknown => j`src/${chain.name}.js`
                    | Netlify(#any) => remoteChainCalls.netlify.path
                    | Netlify(#nextjs)
                    | Nextjs =>
                      remoteChainCalls.nextjs.path
                    }

                    let file = {
                      OneGraphRe.GitHub.path: path,
                      content: content,
                      mode: "100644",
                    }

                    OneGraphRe.GitHub.pushToRepo({
                      "owner": owner,
                      "name": name,
                      "branch": "onegraph-studio",
                      "treeFiles": [file],
                      "message": "Automated push for " ++ chain.name,
                      "acceptOverrides": true,
                    })
                    ->Js.Promise.then_(result => {
                      Js.log2("GitHub push result: ", result)->Js.Promise.resolve
                    }, _)
                    ->ignore
                  | _ => ()
                  }
                })
              })
            })}>
          {switch (savedChainId, state.selectedRepo, state.repoProjectGuess) {
          | (None, _, _) => "Persist chain to push to GitHub"->string
          | (_, None, _) => "Select a GitHub repository"->string
          | (_, _, None) => "Determining project type..."->string
          | (Some(_), Some(_), Some(projectGuess)) =>
            let target = switch projectGuess {
            | Unknown => "repo"
            | Netlify(#nextjs)
            | Nextjs => "next.js project"
            | Netlify(#any) => "Netlify functions"
            }
            <>
              <Icons.Login className="inline-block" color={Comps.colors["gray-6"]} />
              {j`  Push chain to ${target} on GitHub`->string}
            </>
          }}
        </Comps.Button>
      </>
    })
  }
}
