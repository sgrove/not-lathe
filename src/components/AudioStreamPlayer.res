@react.component
let make = (~presence: CollaborationContext.presence) => {
  <>
    {switch presence.audioVolumeLevel->Js.Undefined.toOption {
    | None => <Icons.Volume.Mute className="inline-block" color={presence.color} />
    | Some(level) =>
      <Icons.Volume.Auto className="inline-block" color={presence.color} level={level} />
    }}
  </>
}
