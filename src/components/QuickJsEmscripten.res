type t

@module("quickjs-emscripten") external getQuickJS: unit => Js.Promise.t<t> = "getQuickJS"

@send external evalCode: (t, string) => Js.Json.t = "evalCode"
