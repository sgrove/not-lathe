type audio
@new external createAudio: unit => audio = "Audio"

type audioContext

let createAudioContext: unit => option<audioContext> = () => {
  let audioContext = %raw(`typeof AudioContext !== "undefined" ? AudioContext : 
  typeof webkitAudioContext !== "undefined" ? webkitAudioContext :
  typeof mozAudioContext !== "undefined" ? mozAudioContext : null`)

  let instance = %raw(`function (AudioContext) { return !!AudioContext ? new AudioContext() : null}`)(
    audioContext,
  )

  instance
}

let monitorAudio = (~audio, ~onAudioProcess) => {
  createAudioContext()->Belt.Option.forEach(audioContext => {
    let analyser = Obj.magic(audioContext)["createScriptProcessor"](1024, 1, 1)
    let source = Obj.magic(audioContext)["createMediaElementSource"](audio)
    let () = source["connect"](analyser)
    let () = source["connect"](Obj.magic(audioContext)["destination"])
    let () = Obj.magic(analyser)["connect"](Obj.magic(audioContext)["destination"])

    let opacify = () => {
      Obj.magic(analyser)["onaudioprocess"] = onAudioProcess
    }

    opacify()
  })
}

let r = () => {
  let audio = createAudio()
  Obj.magic(audio)["crossOrigin"] = "anonymous"
  Obj.magic(audio)["src"] = "https://dl.dropboxusercontent.com/s/cnvbozzi5xhatv1/11%20Charlotte.mp3"
  let () = Obj.magic(audio)["play"]()

  monitorAudio(~audio, ~onAudioProcess=event => {
    let ints = event["inputBuffer"]["getChannelData"](0)
    let max = ints->Belt.Array.reduce(0, (acc, next) => acc < next ? next : acc)
    Js.log2("style.opacity", max)
  })
}

Debug.assignToWindowForDeveloperDebug(~name="audioTest", r)
