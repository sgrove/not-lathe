module Query = %relay(`
  query StudioQuery($appId: String!) {
    oneGraph {
      app(id: $appId) {
        ...PackageList_oneGraphApp
      }
    }
    me {
      oneGraph {
        ...PackageViewer_authTokens
      }
    }
  }
`)

let sharedStateUpdateFps = 30
let sharedStateUpdateFpsMs = 1000 / sharedStateUpdateFps

module Inner = {
  @react.component
  let make = (~appId, ~schema) => {
    let data = Query.use(~variables={appId: appId}, ())

    let localAudioStreamPromise = React.useRef({
      Js.Promise.make((~resolve, ~reject as _) => {
        ()
        // Utils.Audio.getUserAudio(
        //   ~onSuccess=(. ~stream) => {
        //     resolve(. Some(stream))
        //   },
        //   ~onError=(. ~error) => {
        //     Js.Console.warn2("Unable to get local audioStream: ", error)
        //     resolve(. None)
        //   },
        // )
      })
    })

    let vectorClock = React.useRef(Js.Date.now())
    let tickVectorClockCallback = React.useCallback2(() => {
      vectorClock.current = Js.Date.now()
    }, (vectorClock, vectorClock.current))

    let tickVectorClock = Hooks.useThrottle(tickVectorClockCallback, sharedStateUpdateFpsMs)

    <CollaborationContext.Provider
      value={
        CollaborationContext.globalState: CollaborationContext.globalConnectionState,
        vectorClock: vectorClock.current,
        updateLocalPosition: (~channelId, ~position) => {
          let fieldName: CollaborationContext.localStateFieldName = #position
          CollaborationContext.globalConnectionState
          ->Belt.HashMap.String.get(channelId)
          ->Belt.Option.forEach((sharedChannel: CollaborationContext.t) => {
            sharedChannel.provider
            ->Yjs.Provider.awareness
            ->Yjs.Awareness.setLocalStateField((fieldName :> string), position)
          })
        },
        updateConnectSourceActionId: (~channelId, ~sourceActionId) => {
          let fieldName: CollaborationContext.localStateFieldName = #connectSourceActionId
          CollaborationContext.globalConnectionState
          ->Belt.HashMap.String.get(channelId)
          ->Belt.Option.forEach((sharedChannel: CollaborationContext.t) => {
            sharedChannel.provider
            ->Yjs.Provider.awareness
            ->Yjs.Awareness.setLocalStateField(
              (fieldName :> string),
              sourceActionId->Js.Undefined.fromOption,
            )
          })
        },
        getSharedChannelState: (~id) => {
          CollaborationContext.globalConnectionState
          ->Belt.HashMap.String.get(id)
          ->Belt.Option.map((sharedChannel: CollaborationContext.t) => {
            let awareness = sharedChannel.provider->Yjs.Provider.awareness
            (awareness->Yjs.Awareness.getClientId, awareness->Yjs.Awareness.getStates)
          })
        },
        getAudioStream: (~id) => {
          CollaborationContext.globalAudioConnectionState->Belt.HashMap.String.get(id)
        },
        getSharedChannel: (~id, ~concurrentSource) => {
          let localUser = switch Debug.Navigator.isChrome() {
          | true => "og_sean_chrome"
          | false => "og_sean_safari"
          }

          let color = localUser->Utils.String.hashToHslColor

          let sharedChannel = CollaborationContext.idempotentCreateChannel(
            ~concurrentSource,
            ~id,
            ~localUser,
            ~color,
            ~onPeerAdded=(~provider, ~channelId, ~peer) => {
              CollaborationContext.globalConnectionState
              ->Belt.HashMap.String.get(channelId)
              ->Belt.Option.forEach((sharedChannel: CollaborationContext.t) => {
                try {
                  let value = Obj.magic(sharedChannel.provider)["room"]["peerId"]
                  sharedChannel.provider->CollaborationContext.setLocalStateField(
                    ~field=#peerId,
                    ~value,
                  )
                } catch {
                | exn => Js.Console.warn2("Exception updating local state peerId: ", exn)
                }
              })

              localAudioStreamPromise.current->Js.Promise.then_(audioStream => {
                switch audioStream {
                | None => Js.Console.warn("AudioStream unavailable")->Js.Promise.resolve
                | Some(audioStream) => peer->Yjs.Peer.addStream(audioStream)->Js.Promise.resolve
                }
              }, _)->ignore
            },
            ~onPeerAudioStream=(~provider as _, ~channelId, ~peer, ~peerId, ~stream) => {
              CollaborationContext.globalAudioConnectionState->Belt.HashMap.String.set(
                peerId->Obj.magic,
                stream,
              )
            },
            (),
          )

          Debug.assignToWindowForDeveloperDebug(~name="lastSharedChannel", sharedChannel)

          let text = sharedChannel.document->Yjs.Document.getText("monaco")

          let runId = ref(0)

          localAudioStreamPromise.current->Js.Promise.then_(audioStream => {
            switch audioStream {
            | None =>
              sharedChannel.provider->CollaborationContext.setLocalStateField(
                ~field=#audioVolumeLevel,
                ~value=0,
              )
              Js.Console.warn("AudioStream unavailable for volume monitoring")->Js.Promise.resolve
            | Some(audioStream) =>
              Utils.Audio.monitorAudio(~audio=audioStream->Obj.magic, ~onAudioProcess=event => {
                let floats = event["inputBuffer"]["getChannelData"](. 0)
                let max =
                  (floats->Js.Array2.reduce((acc, next) => acc < next ? next : acc, 0.) *. 100.)
                    ->int_of_float
                sharedChannel.provider->CollaborationContext.setLocalStateField(
                  ~field=#audioVolumeLevel,
                  ~value=max,
                )
              })

              ()->Js.Promise.resolve
            }
          }, _)->ignore

          let shouldConnect = sharedChannel.provider->Yjs.Provider.shouldConnect

          if shouldConnect {
            sharedChannel.provider->Yjs.Provider.connect
          }

          sharedChannel.provider
          ->Yjs.Provider.awareness
          ->Yjs.Awareness.onChange((_updates, _transactionOrigin) => {
            tickVectorClock()
          })

          Some(sharedChannel)
        },
        getSharedMap: (~channelId, ~id) => {
          switch CollaborationContext.globalConnectionState->Belt.HashMap.String.get(channelId) {
          | None => None
          | Some(sharedChannel: CollaborationContext.t) =>
            sharedChannel.document->Yjs.Document.getMap(id)->Some
          }
        },
      }>
      <PackageList
        schema
        oneGraphApp={data.oneGraph.app.fragmentRefs}
        authTokensRef={data.me.oneGraph->Belt.Option.map(r => r.fragmentRefs)}
      />
    </CollaborationContext.Provider>
  }
}

@react.component
let make = (~schema) => {
  open React

  <div>
    <div style={ReactDOMStyle.make(~color="white", ())}>
      <Suspense fallback={<div> {"Loading OneGraph packages..."->string} </div>}>
        <ErrorBoundary
          fallback={errors => {
            Js.log2("Fallback errors", errors)
            <div> {string("Something went wrong")} </div>
          }}
          onError={errors => Js.log2("Errors: ", errors)}>
          <Inner appId={RelayEnv.appId} schema />
        </ErrorBoundary>
      </Suspense>
    </div>
  </div>
}
