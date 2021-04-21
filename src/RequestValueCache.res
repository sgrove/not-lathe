// TODO: Make this private (have to add a resi file)
type t = Js.Dict.t<GraphQLJs.queryResult>

let make = (): t => (Js.Dict.empty() :> t)

let get = (t, ~requestId) => t->Js.Dict.get(requestId)
let set = (t, ~requestId, ~value) => t->Js.Dict.set(requestId, value)
let entries = t => t->Js.Dict.entries
let copy = t => t->entries->Js.Dict.fromArray
