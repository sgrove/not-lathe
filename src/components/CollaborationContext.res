type t = {document: Yjs.Document.t, provider: Yjs.Provider.t}

let globalConnectionState: Belt.HashMap.String.t<t> = Belt.HashMap.String.make(~hintSize=17)

type audioConnection = {
  id: string,
  stream: Yjs.Stream.t,
}

let globalAudioConnectionState: Belt.HashMap.String.t<Yjs.Stream.t> = Belt.HashMap.String.make(
  ~hintSize=17,
)

type presence = {
  position: Js.Undefined.t<ReactFlow.position>,
  name: string,
  color: string,
  audioVolumeLevel: Js.Undefined.t<int>,
  peerId: Js.Undefined.t<string>,
  connectSourceActionId: Js.Undefined.t<string>,
}

type localStateFieldName = [
  | #name
  | #color
  | #position
  | #peerId
  | #audioVolumeLevel
  | #connectSourceActionId
]

let setLocalStateField = (provider, ~field: localStateFieldName, ~value) => {
  provider->Yjs.Provider.awareness->Yjs.Awareness.setLocalStateField((field :> string), value)
}

let encodeUint8Array = %raw(`function encodeUint8Array(u8) {
  return btoa(String.fromCharCode.apply(null, u8));
}`)

let decodeUint8Array = %raw(`function decodeUint8Array(str) {
  return new Uint8Array(atob(str).split('').map(function (c) { return c.charCodeAt(0); }));
}`)

let idempotentCreateChannel = (
  ~id,
  ~concurrentSource,
  ~onPeerAdded,
  ~localUser,
  ~onPeerAudioStream,
  ~onSynced=?,
  ~onPeerRemoved=?,
  ~onSignaled=?,
  ~onProviderStream=?,
  ~color,
  (),
) => {
  switch globalConnectionState->Belt.HashMap.String.get(id) {
  | Some(channel) => channel
  | None =>
    let update = concurrentSource->decodeUint8Array

    let ydocument = Yjs.createDocument()
    ydocument->Yjs.applyUpdate(update)

    let yprovider = Yjs.WebRTC.createProvider(
      id,
      ydocument,
      Yjs.WebRTC.providerOptions(~maxConns=20, ()),
    )

    [(#name, localUser), (#color, color)]->Belt.Array.forEach(((
      field: localStateFieldName,
      value,
    )) => {
      yprovider->Yjs.Provider.awareness->Yjs.Awareness.setLocalStateField((field :> string), value)
    })

    yprovider->Yjs.Provider.on("synced", (update, origin, other) => {
      onSynced->Belt.Option.forEach(onSynced => onSynced(update, origin, other))
    })

    yprovider->Yjs.Provider.on("connect", (args, _, _) => {
      Js.log2("Provider connected! ", args)
    })

    yprovider->Yjs.WebRTC.onPeers(event => {
      event.removed->Belt.Array.forEach(peerId => {
        let connection = yprovider->Yjs.WebRTC.getConnection(peerId)
        let peer = connection->Belt.Option.map(connection => connection.peer)

        peer->Belt.Option.forEach(peer => {
          onPeerRemoved->Belt.Option.forEach(onPeerRemoved =>
            onPeerRemoved(~provider=yprovider, ~channelId=id, ~peer)
          )
        })
      })

      event.added->Belt.Array.forEach(peerId => {
        let connection = yprovider->Yjs.WebRTC.getConnection(peerId)
        let peer = connection->Belt.Option.map(connection => connection.peer)

        peer->Belt.Option.forEach(peer => {
          onPeerAdded(~provider=yprovider, ~channelId=id, ~peer)->ignore

          peer->Yjs.Peer.onStream(stream => {
            onPeerAudioStream(~provider=yprovider, ~channelId=id, ~peer, ~peerId, ~stream)
          })
        })
      })
    })

    yprovider->Yjs.Provider.on("signal", (update, origin, other) => {
      onSignaled->Belt.Option.forEach(onSignaled => onSignaled(update, origin, other))
    })

    yprovider->Yjs.Provider.on("stream", (update, origin, other) => {
      onProviderStream->Belt.Option.forEach(onProviderStream =>
        onProviderStream(update, origin, other)
      )
    })

    let sharedChannel = {
      document: ydocument,
      provider: yprovider,
    }

    globalConnectionState->Belt.HashMap.String.set(id, sharedChannel)

    sharedChannel
  }
}

type state<'sharedClientState> = {
  getSharedChannel: (~id: string, ~concurrentSource: string) => option<t>,
  globalState: Belt.HashMap.String.t<t>,
  updateLocalPosition: (~channelId: string, ~position: ReactFlow.position) => unit,
  getSharedChannelState: (
    ~id: string,
  ) => option<(Yjs.Awareness.clientId, Js.Dict.t<'sharedClientState>)>,
  vectorClock: float,
  getAudioStream: (~id: string) => option<Yjs.Stream.t>,
  getSharedMap: (~channelId: string, ~id: string) => option<Yjs.Document.Map.t>,
  updateConnectSourceActionId: (~channelId: string, ~sourceActionId: option<string>) => unit,
}

let context = React.createContext({
  getSharedChannel: (~id as _, ~concurrentSource as _) => None,
  globalState: Belt.HashMap.String.make(~hintSize=17),
  updateLocalPosition: (~channelId as _: string, ~position as _: ReactFlow.position) => (),
  getSharedChannelState: (~id as _): option<(Yjs.Awareness.clientId, Js.Dict.t<presence>)> => None,
  vectorClock: -1.0,
  getAudioStream: (~id as _) => None,
  getSharedMap: (~channelId as _, ~id as _) => None,
  updateConnectSourceActionId: (~channelId as _, ~sourceActionId as _) => (),
})

module Provider = {
  let provider = React.Context.provider(context)

  @react.component
  let make = (~value, ~children) => {
    React.createElement(provider, {"value": value, "children": children})
  }
}
