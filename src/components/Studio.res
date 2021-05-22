module Query = %relay(`
  query StudioQuery($appId: String!) {
    oneGraph {
      app(id: $appId) {
        id
        name
        description
        ...PackageList_oneGraphApp
      }
      studio {
        actions {
          id
          name
          description
          graphQLOperation
          privacy
        }
      }
    }
    me {
      oneGraph {
        personalTokens {
          obscuredToken
          expireDate
          name
          appId
        }
        ...PackageViewer_authTokens
      }
    }
  }
`)

module Inner = {
  @react.component
  let make = (~appId, ~schema) => {
    let data = Query.use(~variables={appId: appId}, ())
    <PackageList
      schema
      oneGraphApp={data.oneGraph.app.fragmentRefs}
      authTokensRef={data.me.oneGraph->Belt.Option.map(r => r.fragmentRefs)}
    />
  }
}

@react.component
let make = (~schema, ~config) => {
  open React

  <div>
    <div style={ReactDOMStyle.make(~color="white", ())}>
      <Suspense fallback={<div> {"Loading lessons and pull requests..."->string} </div>}>
        <ErrorBoundary
          fallback={errors => {
            Js.log2("Fallback errors", errors)
            <div> {string("Something went wrong")} </div>
          }}
          onError={errors => Js.log2("Errors: ", errors)}>
          <Inner appId={RelayEnv.appId} schema />
          // <RelayTest packageName="react" />
          // <Package schema config />
        </ErrorBoundary>
      </Suspense>
    </div>
  </div>
}
