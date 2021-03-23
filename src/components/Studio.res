module DevTimeJson = {
  @module("../DevTime_Json.js") external devJsonChain: Chain.t = "devJsonChain"
  @module("../DevTime_Json.js") external simpleChain: Chain.t = "simpleChain"
}

@react.component
let make = (~schema, ~config) => {
  // let initialChain = Chain.emptyChain
  // To debug with a local JSON chain:
  let initialChain = DevTimeJson.devJsonChain

  open React

  let navButton = (~onClick, content) => {
    <button className="mr-2 ml-2" onClick> content </button>
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
      {navButton(~onClick=_ => (), <strong> {initialChain.name->string} </strong>)}
    </nav>
    <ChainEditor schema initialChain config />
  </div>
}
