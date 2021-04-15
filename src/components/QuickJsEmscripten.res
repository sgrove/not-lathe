type quickjs

@module("@dww/quickjs-emscripten") external getQuickJS: unit => Js.Promise.t<quickjs> = "getQuickJS"

@send external evalCode: (quickjs, string) => Js.Json.t = "evalCode"

module VM = {
  type t
  @send external create: (quickjs, unit) => t = "createVm"

  type global
  @get external global: t => global = "global"

  type prop
  @send external setProp: (t, global, string, prop) => unit = "setProp"

  @get external undefined: t => prop = "undefined"
  @send external newFunction: (t, string, 'fn) => prop = "newFunction"
  @send external newInt: (t, int) => prop = "newNumber"
  @send external newFloat: (t, float) => prop = "newNumber"
  @send external newArray: t => prop = "newArray"

  @send external disposeProp: prop => unit = "dispose"

  type result
  @send external evalCode: (t, string) => result = "evalCode"

  type value
  @send external unwrapResult: (t, result) => value = "unwrapResult"
  @send external getFloat: (t, value) => option<float> = "getNumber"

  @send external disposeValue: value => unit = "dispose"
  @send external dispose: t => unit = "dispose"

  type hostValue
  @send external dump: (t, 'vmValue) => hostValue = "dump"

  @send external setMemoryLimit: (t, int) => unit = "setMemoryLimit"

  @send external setInterruptHandler: (t, t => bool) => unit = "setInterruptHandler"

  @send external evalModuleCode: (t, string, string) => result = "evalModuleCode"
}

module Scope = {
  type t

  @module("@dww/quickjs-emscripten") @scope("Scope")
  external withScope: (t => unit) => unit = "withScope"

  @send external manage: (t, 'value) => 'value = "manage"
  @send external manageProp: (t, VM.prop) => VM.prop = "manage"
}

let main = () => {
  getQuickJS()->Js.Promise.then_(quickjs => {
    let vm = quickjs->VM.create()
    let global = vm->VM.global
    let state = ref(0)

    let fnHandle = vm->VM.newFunction("nextId", () => {
      state := state.contents + 1
      vm->VM.newInt(state.contents)
    })

    let recorderFnHandle = vm->VM.newFunction("baseRecorder", value => {
      let value = vm->VM.dump(value)->Obj.magic
      Js.log2("Recorder called from wasm: ", value)
      let json = Js.Json.parseExn(value)
      Js.log2("\tJSON:", json)
      vm->VM.undefined
    })

    vm->VM.setProp(global, "nextId", fnHandle)
    vm->VM.setProp(global, "baseRecorder", recorderFnHandle)

    let code = `nextId(); nextId(); nextId(); __$i({"hi": true});__$i({"hi": false, "other": 42}); nextId();


function __$i(value,source,line,name,filePath,runId,runGroup,fileVersion,scopeId,callNum) {
let serializedRecord = JSON.stringify({
  value: value,
  source: source,
  line: line,
  name: name,
  filePath: filePath,
  runId: runId,
  runGroup: runGroup,
  fileVersion: fileVersion,
  scopeId: scopeId,
  callNum: callNum
  });

  baseRecorder(serializedRecord)

  return value
}`

    let result = vm->VM.evalCode(code)
    let nextId = vm->VM.unwrapResult(result)

    Js.log4("vm result: ", vm->VM.getFloat(nextId), "native state: ", state.contents)

    fnHandle->VM.disposeProp
    recorderFnHandle->VM.disposeProp
    nextId->VM.disposeValue
    vm->VM.dispose
    Js.Promise.resolve()
  }, _)->ignore
}

/**
  const world = vm.newString('world')
  vm.setProp(vm.global, 'NAME', world)
  world.dispose()

  const vm = QuickJS.createVm()
let state = 0

const fnHandle = vm.newFunction('nextId', () => {
  return vm.newNumber(++state)
})

vm.setProp(vm.global, 'nextId', fnHandle)
fnHandle.dispose()

const nextId = vm.unwrapResult(vm.evalCode(`nextId(); nextId(); nextId()`))
console.log('vm result:', vm.getNumber(nextId), 'native state:', state)

nextId.dispose()
vm.dispose()

  const result = vm.evalCode(`"Hello " + NAME + "!"`)
  if (result.error) {
    console.log('Execution failed:', vm.dump(result.error))
    result.error.dispose()
  } else {
    console.log('Success:', vm.dump(result.value))
    result.value.dispose()
  }

  vm.dispose()
}

*/
