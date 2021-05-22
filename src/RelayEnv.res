let appId = "4c1c8469-89fa-4995-ab5a-b22db4587381"

/* Determine if we're rendering in a non-browser environment (e.g. node) */
let isSsr: bool = switch %external(window) {
| Some(_) => false
| None => true
}

let oneGraphUrl = j`https://serve.onegraph.io/graphql?app_id=${"0b066ba6-ed39-4db8-a497-ba0be34d5b2a"}` //serve.onegraph.com/graphql?app_id=$appId|j};

let authConfig = OneGraphAuth.createOptions(~appId, ())

let auth = isSsr ? None : OneGraphAuth.create(authConfig)

/* This is just a custom exception to indicate that something went wrong. */
exception Graphql_error(string)

@ocaml.doc("
   * A standard fetch that sends our operation and variables to the
   * GraphQL server, and then decodes and returns the response.
   ")
let fetchQuery: RescriptRelay.Network.fetchFunctionPromise = (
  operation,
  variables,
  _cacheConfig,
  _uploadables,
) => {
  let authHeader = auth->Belt.Option.flatMap(auth => OneGraphAuth.authHeaders(auth))

  Fetch.fetchWithInit(
    oneGraphUrl,
    Fetch.RequestInit.make(
      ~method_=Post,
      ~body=Js.Dict.fromList(list{
        ("query", Js.Json.string(operation.text)),
        ("variables", variables),
      })
      ->Js.Json.object_
      ->Js.Json.stringify
      ->Fetch.BodyInit.make,
      ~headers=Fetch.HeadersInit.make({
        "content-type": "application/json",
        "accept": "application/json",
        "Authorization": "Bearer eH7zBV9qnXx1NDX_Bo94WyHRVK2qCuVc6LYN38ye7bA",
        // authHeader->Belt.Option.getWithDefault(""),
      }),
      (),
    ),
  )->Js.Promise.then_(resp =>
    if Fetch.Response.ok(resp) {
      Fetch.Response.json(resp)
    } else {
      Js.Promise.reject(Graphql_error("Request failed: " ++ Fetch.Response.statusText(resp)))
    }
  , _)
}

module OneGraphSubscriptionClient = {
  type t

  type subscriptionClientOptions = {oneGraphAuth: OneGraphAuth.t}

  @module("onegraph-subscription-client") @new("SubscriptionClient")
  external make: (string, subscriptionClientOptions) => t = "SubscriptionClient"

  type observable
  @send external request: (t, 'a) => observable = "request"
  @send external subscribe: (observable, 'a) => unit = "subscribe"
}

let oneGraphSubscriptionClient =
  auth->Belt.Option.map(oneGraphAuth =>
    OneGraphSubscriptionClient.make(appId, {oneGraphAuth: oneGraphAuth})
  )

/* Subscriptions to OneGraph can also work server-side with some addition packages, but we just disable them in SSR for now. */
let subscriptionFunction: option<
  RescriptRelay.Network.subscribeFn,
> = oneGraphSubscriptionClient->Belt.Option.map((
  oneGraphSubscriptionClient,
  operation: RescriptRelay.Network.operation,
  variables: Js.Json.t,
  _cacheConfig: RescriptRelay.cacheConfig,
) => {
  let subscribeObservable = oneGraphSubscriptionClient->OneGraphSubscriptionClient.request({
    "query": operation.text,
    "variables": variables,
    "operationName": operation.name,
  })

  let observable = RescriptRelay.Observable.make(sink => {
    subscribeObservable
    ->OneGraphSubscriptionClient.subscribe({
      "next": data => sink.next(data),
      "error": sink.error,
      "complete": sink.complete,
    })
    ->ignore

    None
  })

  observable
})

let network = RescriptRelay.Network.makePromiseBased(
  ~fetchFunction=fetchQuery,
  ~subscriptionFunction?,
  (),
)

let environment = RescriptRelay.Environment.make(
  ~network,
  ~store=RescriptRelay.Store.make(
    ~source=RescriptRelay.RecordSource.make(),
    ~gcReleaseBufferSize=100,
    (),
  ),
  (),
)
