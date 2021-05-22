type state = {
  audioLevel: int,
  audioStream: AudioStreamContext.state,
}

@react.component
let make = () => {
  let (state, setState) = React.useState(() => {
    audioLevel: 0,
    audioStream: Empty,
  })

  let onStartAudio = _ => {
    Navigator.MediaDevices.getUserAudio()->Belt.Option.forEach(promise =>
      promise->Js.Promise.then_(stream => {
        setState(oldState => {...oldState, audioStream: Loaded(stream)})
        Js.log2("Got stream: ", stream)->Js.Promise.resolve
      }, _)->Js.Promise.catch(err => {
        Js.Console.warn2("Unable to get audio stream: ", err)->Js.Promise.resolve
      }, _)->ignore
    )
  }

  <>
    <Icons.Volume.Auto color="red" onClick={onStartAudio} level={state.audioLevel} />
    <Icons.Volume.Auto color="#662299" onClick={onStartAudio} level=99 />
    <Icons.Volume.Auto onClick={onStartAudio} level=10 />
  </>
}
