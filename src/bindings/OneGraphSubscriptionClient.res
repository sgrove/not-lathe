@deriving(abstract)
type clientOptions = {
  @optional
  oneGraphAuth: OneGraphAuth.t,
  @optional
  timeout: int,
  @optional @as("lazy")
  lazyInitialization: bool,
  @optional
  reconnect: bool,
  @optional
  reconnectionAttempts: int,
  @optional
  inactivityTimeout: int,
}

type t

@module("onegraph-subscription-client") @new
external makeClient: (
  ~appId: string,
  ~options: clientOptions,
  ~webSocketImpl: option<'webSocketImpl>,
) => t = "SubscriptionClient"

type operationOptions<'variables, 'context> = {
  query: string,
  operationName: string,
  variables: 'variables,
  context: option<'context>,
}

type observable<'a> = {subscribe: 'a => unit}

@send
external request: (
  t,
  operationOptions<option<Js.Json.t>, option<Js.t<{..}>>>,
) => observable<'subscription> = "request"

@send
external subscribe: (
  observable<'a>,
  ~onData: 'data => unit,
  ~onError: 'error => unit,
  ~onClosed: unit => unit,
) => unit = "subscribe"

@send external unsubscribeAll: t => unit = "unsubscribeAll"

@send external on: (t, ~eventName: string, 'callback, 'thisContext, unit) => unit = "on"

type unsubscribeFn = unit => unit
type onCallback = unit => unit
type thisContext

@send external onConnected: (t, onCallback, thisContext) => unsubscribeFn = "onConnected"
@send external onReconnected: (t, onCallback, thisContext) => unsubscribeFn = "onReconnected"
@send external onConnecting: (t, onCallback, thisContext) => unsubscribeFn = "onConnecting"
@send external onReconnecting: (t, onCallback, thisContext) => unsubscribeFn = "onReconnecting"
@send external onDisconnected: (t, onCallback, thisContext) => unsubscribeFn = "onDisconnected"
@send external onError: (t, onCallback, thisContext) => unsubscribeFn = "onError"
