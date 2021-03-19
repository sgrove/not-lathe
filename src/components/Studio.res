module DevTimeJson = {
  @module("../DevTime_Json.js") external devJsonChain: Chain.t = "devJsonChain"
}

@react.component
let make = (~schema, ~config) => {
  let initialChain = Chain.emptyChain
  // To debug with a local JSON chain:
  // let initialChain = DevTimeJson.devJsonChain

  open React
  let navButton = (~onClick, content) => {
    <button className="mr-2 ml-2" onClick> content </button>
  }

  <div>
    <nav className="p-2 bg-black text-white">
      {navButton(~onClick=_ => (), "OneGraph"->string)}
      {navButton(~onClick=_ => (), "> Workspace"->string)}
    </nav>
    <ChainEditor schema initialChain config />
  </div>
}
