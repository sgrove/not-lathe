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

  @send external setLocalStateField: (t, string, 'value) => unit = "setLocalStateField"
}

module Stream = {
  type t
}

module Peer = {
  type t

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
    ~optimisticInitialText: string,
    ~yText: Document.Text.t,
    ~model: BsReactMonaco.Model.t,
    ~editors: 'editorSet,
    ~awareness: Awareness.t,
  ) => binding = "MonacoBinding"
}

// let ydocument = createDocument()
// let yprovider = WebRTC.createProvider(
//   "your-room-name",
//   ydocument,
//   WebRTC.providerOptions(
//     ~password="optional-room-password",
//     ~signaling=["wss://y-webrtc-ckynwnzncc.now.sh"],
//     ~maxConns=20,
//     (),
//   ),
// )

// let typ = ydocument->Document.getText("monaco")

// let editor = Obj.magic("editor")
// let model = Obj.magic(editor)["getModel"]()

// let monacoBinding = Monaco.createBinding(typ, model, [editor], yprovider->WebRTC.awareness)
