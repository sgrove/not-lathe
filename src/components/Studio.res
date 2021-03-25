module DevTimeJson = {
  @module("../DevTime_Json.js") external devJsonChain: Chain.t = "devJsonChain"
  @module("../DevTime_Json.js") external simpleChain: Chain.t = "simpleChain"
  @module("../DevTime_Json.js") external spotifyChain: Chain.t = "spotifyChain"
  @module("../DevTime_Json.js") external descuriChain: Chain.t = "descuriChain"
}

@react.component
let make = (~schema, ~config) => {
  let (initialChain, setInitialChain) = React.useState(() => {
    let initialChain = Chain.emptyChain

    // let initialChain = DevTimeJson.simpleChain

    // let initialChain = DevTimeJson.devJsonChain

    initialChain
  })
  // To debug with a local JSON chain:

  open React

  let navButton = (~onClick, ~onDoubleClick=?, content) => {
    <button className="mr-2 ml-2" ?onDoubleClick onClick> content </button>
  }

  <div>
    <nav
      className="p-4 bg-black text-white"
      style={ReactDOMStyle.make(
        ~color=Comps.colors["gray-11"],
        ~backgroundColor=Comps.colors["gray-12"],
        (),
      )}>
      {navButton(~onClick=_ => (), "OneGraph >"->string)}
      {navButton(~onClick=_ => (), "Workspace >"->string)}
      {navButton(
        ~onClick=_ => (),
        ~onDoubleClick={
          _ => {
            let newName = Utils.prompt("Rename chain", ~default=Some(initialChain.name))
            switch newName {
            | None | Some("") => ()
            | Some(newName) => setInitialChain(oldChain => {...oldChain, name: newName})
            }
          }
        },
        <strong> {initialChain.name->string} </strong>,
      )}
    </nav>
    <ChainEditor schema initialChain config />
  </div>
}
