module MediaDevices = {
  let getUserAudio: unit => option<Js.Promise.t<'stream>> = () => {
    %external(navigator)->Belt.Option.map(navigator =>
      Obj.magic(navigator)["mediaDevices"]["getUserMedia"](. {
        "audio": true,
        "video": false,
      })
    )
  }

  let getUserAudioAndVideo: unit => option<Js.Promise.t<'stream>> = () => {
    %external(navigator)->Belt.Option.map(navigator =>
      Obj.magic(navigator)["mediaDevices"]["getUserMedia"](. {
        "audio": true,
        "video": true,
      })
    )
  }
}
