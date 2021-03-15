// // const { duktapeEval, quickjsEval } = require('wasm-jseval')
// module QuickJS = {
//   type singleton
//   type t
//   @module("wasm-jseval") external singleton: singleton = "quickjsEval"

//   @send external getInstance: singleton => Js.Promise.t<t> = "getInstance"

//   @send external eval: (t, string) => Js.Json.t = "eval"
// }

// let test = () => {
//   open QuickJS
//   singleton->getInstance->Js.Promise.then_(mod => {
//     Js.log(mod->eval("1+1"))->Js.Promise.resolve
//   }, _)
// }

