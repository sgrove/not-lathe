module Document = {
  type t

  module Text = {
    type t
    @send external insert: (t, int, string) => unit = "insert"
    @get external length: t => int = "length"
    @send external toString: t => string = "toString"
    @send external observe: (t, ('textEvent, 'transaction) => unit) => unit = "observe"
    @send external unobserve: (t, ('textEvent, 'transaction) => unit) => unit = "unobserve"
  }
  @send external getText: (t, string) => Text.t = "getText"

  module Map = {
    type t
    @send external get: (t, string) => Js.Undefined.t<'value> = "get"
    @send external set: (t, string, 'value) => unit = "set"
    @send external observe: (t, ('mapEvent, 'transaction) => unit) => unit = "observe"
    @send external unobserve: (t, ('mapEvent, 'transaction) => unit) => unit = "unobserve"
  }
  @send external getMap: (t, string) => Map.t = "getMap"

  @send external on: (t, string, ('update, 'origin, t) => unit) => unit = "on"
  @send external once: (t, string, ('update, 'origin, t) => unit) => unit = "once"
  @send external off: (t, string, 'event => unit) => unit = "off"
  @send external destroy: t => unit = "destroy"
  @set external enableGC: (t, bool) => unit = "gc"
  @get external gc: t => bool = "gc"
  @get external clientID: t => Int64.t = "clientID"
}

type update

@module("yjs") external encodeStateAsUpdate: Document.t => update = "encodeStateAsUpdate"
@module("yjs") external applyUpdate: (Document.t, update) => unit = "applyUpdate"

@new @module("yjs") external createDocument: unit => Document.t = "Doc"

module Awareness = {
  type t

  type stateChange<'a> = {
    added: array<'a>,
    removed: array<'a>,
    updated: array<'a>,
  }

  type clientId

  @get external getClientId: t => clientId = "clientID"
  @send external getStates: t => Js.Dict.t<'state> = "getStates"
  @send external setLocalStateField: (t, string, 'value) => unit = "setLocalStateField"
  @send
  external onChange: (t, @as("change") _, (stateChange<'a>, 'transactionOrigin) => unit) => unit =
    "on"
  @send
  external onUpdate: (t, @as("update") _, (stateChange<'a>, 'transactionOrigin) => unit) => unit =
    "on"
}

module Stream = {
  type t
}

module Peer = {
  type t

  @get external getChannelName: t => string = "channelName"
  @send external onStream: (t, @as("stream") _, Stream.t => unit) => unit = "on"
  @send external addStream: (t, Stream.t) => unit = "addStream"
}

module Connection = {
  type t = {peer: Peer.t}
}

module Provider = {
  type t

  @send external connect: t => unit = "connect"
  @send external disconnect: t => unit = "disconnect"
  @get external shouldConnect: t => bool = "shouldConnect"

  @get external awareness: t => Awareness.t = "awareness"

  @send external on: (t, string, ('update, 'origin, t) => unit) => unit = "on"
  @send external once: (t, string, ('update, 'origin, t) => unit) => unit = "once"
  @send external off: (t, string, 'event => unit) => unit = "off"

  module Room = {
    type t
  }

  @get external room: t => Room.t = "room"
}

module WebRTC = {
  type simplePeerOptions

  @deriving(abstract)
  type providerOptions = {
    @optional
    /**
     If password is a string, it will be used to encrypt all communication over the signaling servers.
     No sensitive information (WebRTC connection info, shared data) will be shared over the signaling servers.
     The main objective is to prevent man-in-the-middle attacks and to allow you to securely use public / untrusted signaling instances. */
    password: string,
    @optional
    /**
     Specify signaling servers. The client will connect to every signaling server concurrently to find other peers as fast as possible. */
    signaling: array<string>,
    @optional
    /**
     Specify an existing Awareness instance - see https://github.com/yjs/y-protocols */
    awareness: Awareness.t,
    @optional
    /**
     Maximal number of WebRTC connections. */
    maxConns: int,
    @optional
    /* * Whether to disable WebRTC connections to other tabs in the same browser.
     Tabs within the same browser share document updates using BroadcastChannels.
     WebRTC connections within the same browser are therefore only necessary if you want to share video information too. */
    filterBcConns: bool,
    /**
     simple-peer options. See https://github.com/feross/simple-peer#peer--new-peeropts for available options.
     y-webrtc uses simple-peer internally as a library to create WebRTC connections. */
    @optional
    peerOpts: simplePeerOptions,
  }

  @new @module("y-webrtc")
  external createProvider: (string, Document.t, providerOptions) => Provider.t = "WebrtcProvider"

  type peerId

  type onPeerEventPayload = {
    removed: array<peerId>,
    added: array<peerId>,
    webrtcPeers: array<peerId>,
    bcPeers: array<peerId>,
  }

  @send external onPeers: (Provider.t, @as("peers") _, onPeerEventPayload => unit) => unit = "on"

  type webrtcConns = {get: (. peerId) => Js.Undefined.t<Connection.t>}

  @get external webrtcConns: Provider.Room.t => webrtcConns = "webrtcConns"

  let getConnection = (provider: Provider.t, peerId) => {
    let room = provider->Provider.room

    let conns = room->webrtcConns

    let conn = conns.get(. peerId)
    conn->Js.Undefined.toOption
  }
}

module WebSocket = {
  @new @module("y-websocket")
  external createProvider: (string, string, Document.t) => Provider.t = "WebsocketProvider"
}

let makeSet = %raw(`function makeSet(items) { return new Set([...items])}`)

module Monaco = {
  type binding
  @new @module("./y-monaco.js")
  external createBinding: (
    ~yText: Document.Text.t,
    ~model: BsReactMonaco.Model.t,
    ~editors: 'editorSet,
    ~awareness: Awareness.t,
  ) => binding = "MonacoBinding"
}
