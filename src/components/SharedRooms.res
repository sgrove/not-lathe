type t = {document: Yjs.Document.t, provider: Yjs.Provider.t}

let globalState: Belt.HashMap.String.t<t> = Belt.HashMap.String.make(~hintSize=10)

let encodeUint8Array = %raw(`function encodeUint8Array(u8) {
  return btoa(String.fromCharCode.apply(null, u8));
}`)

let decodeUint8Array = %raw(`function decodeUint8Array(str) {
  return new Uint8Array(atob(str).split('').map(function (c) { return c.charCodeAt(0); }));
}`)

let idempotentCreate = (~name, ~yjsScript, ~audioStreamPromise) => {
  switch globalState->Belt.HashMap.String.get(name) {
  | Some(room) => room
  | None =>
    let ydocument = Yjs.createDocument()
    yjsScript->Belt.Option.forEach(base64History => {
      let update = decodeUint8Array(base64History)
      ydocument->Yjs.applyUpdate(update)
    })

    let yprovider = Yjs.WebRTC.createProvider(
      name,
      ydocument,
      Yjs.WebRTC.providerOptions(~maxConns=20, ()),
    )

    yprovider->Yjs.Provider.on("synced", (update, origin, other) => {
      Js.log4("Provider synced: ", update, origin, other)
    })

    yprovider->Yjs.WebRTC.onPeers(event => {
      Js.log2("Provider onPeers: ", event)

      event.added->Belt.Array.forEach(peerId => {
        let connection = yprovider->Yjs.WebRTC.getConnection(peerId)
        let peer = connection->Belt.Option.map(connection => connection.peer)

        peer->Belt.Option.forEach(peer => {
          audioStreamPromise->Js.Promise.then_(audioStream => {
            Js.log3("Adding audioStream to peer: ", peer, audioStream)
            peer->Yjs.Peer.addStream(audioStream)->Js.Promise.resolve
          }, _)->ignore

          peer->Yjs.Peer.onStream(stream => {
            Js.log2("Got a stream: ", stream)
            Debug.assignToWindowForDeveloperDebug(
              ~name="incomingStream",
              {
                "stream": stream,
                "peer": peer,
              },
            )
            let audioEl = %raw(`document.querySelector("#test-audio-tag")`)

            AudioVisualizer.monitorAudio(~audio=audioEl, ~onAudioProcess=event => {
              let ints = event["inputBuffer"]["getChannelData"](0)
              let max = ints->Belt.Array.reduce(0, (acc, next) => acc < next ? next : acc)
              Js.log2("Volume for stream: ", max)
            })

            let () = %raw(`function(audioEl) { audioEl.srcObject = stream; }`)(audioEl)
            %raw(`function(audioEl) { audioEl.play(); }`)(audioEl)
          })
        })
        Js.log3("\tConnection peer: ", connection, peer)
      })
    })

    yprovider->Yjs.Provider.on("signal", (update, origin, other) => {
      Js.log4("Provider signal: ", update, origin, other)
    })

    yprovider->Yjs.Provider.on("stream", (update, origin, other) => {
      Js.log4("Provider stream: ", update, origin, other)
    })

    let sharedRoom = {
      document: ydocument,
      provider: yprovider,
    }

    globalState->Belt.HashMap.String.set(name, sharedRoom)

    sharedRoom
  }
}
