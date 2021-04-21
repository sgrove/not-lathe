type plugin

type map
type ast

type transformResult = {
  code: string,
  map: map,
  ast: ast,
}

type pluginOptions

external pluginOptions: 'options => pluginOptions = "%identity"

@module("@babel/standalone")
external transform: (
  string,
  ~options: {"filename": string, "plugins": array<(plugin, pluginOptions)>},
) => transformResult = "transform"

@module("@babel/plugin-transform-typescript") external typescriptPlugin: plugin = "default"
@module("@babel/plugin-proposal-optional-chaining")
external optionalChainingPlugin: plugin = "default"

module Insight = {
  type evaluationRecord = {
    lineNum: int,
    hasError: bool,
    content: string,
    runId: int,
  }

  type runner = transformResult => array<evaluationRecord>
  type asyncRunner = transformResult => Js.Promise.t<array<evaluationRecord>>
  type recorder
  type recordStore

  type insight = {
    store: recordStore,
    latestRunId: int,
    previousRunId: int,
  }

  @module("@insightdotjs-hackers/platform/lib/core/RecordStore") @new
  external createRecordStore: unit => recordStore = "RecordStore"

  @send external addRecord: (recordStore, evaluationRecord) => unit = "addRecord"
  @send
  external getGroupedLineDecorations: (
    recordStore,
    ~runId: int,
    ~filePath: string,
    ~maxRecordLen: option<int>,
    ~beforePosition: option<int>,
  ) => array<evaluationRecord> = "getGroupedLineDecorations"
  @send external removeRun: (recordStore, int) => unit = "removeRun"

  @module("insight-kit/lib/core/createRecorder")
  external createRecorder: ('run => unit) => recorder = "createRecorder"

  type recordInvocation<
    'value,
    'source,
    'line,
    'name,
    'filePath,
    'runId,
    'runGroup,
    'fileVersion,
    'scopeId,
    'callNum,
  > = {
    value: 'value,
    source: 'source,
    line: 'line,
    name: 'name,
    filePath: 'filePath,
    runId: 'runId,
    runGroup: 'runGroup,
    fileVersion: 'fileVersion,
    scopeId: 'scopeId,
    callNum: 'callNum,
  }

  let consoleCode = `function logImpl(level, message) {
  __ogLogs.push({level, message});
}

function log(...args) {
  logImpl('info', args);
}

function info(...args) {
  logImpl('info', args);
}

function debug(...args) {
  logImpl('debug', args);
}

function warn(...args) {
  logImpl('warn', args);
}

function error(...args) {
  logImpl('error', args);
}

globalThis.console = {log, info, debug, warn, error};`

  let wasmQuickJSRunner: asyncRunner = transformResult => {
    let rs: array<evaluationRecord> = []

    let recorder = createRecorder(r => {
      let _length = rs->Js.Array2.push(r)
    })

    open QuickJsEmscripten
    getQuickJS()->Js.Promise.then_(quickjs => {
      try {
        Scope.withScope(scope => {
          let vm = scope->Scope.manage(quickjs->VM.create())
          vm->VM.setMemoryLimit(1024 * 1024)
          let start = Js.Date.now()

          vm->VM.setInterruptHandler(_vm => {
            Js.Date.now() > start +. 250.
          })

          Debug.assignToWindowForDeveloperDebug(~name="myVm", vm)

          let global = vm->VM.global

          let logsVar = scope->Scope.manageProp(vm->VM.newArray)
          vm->VM.setProp(global, "__ogLogs", logsVar)

          let _getLogs = () => {
            let result = vm->VM.evalCode("__ogLogs")
            let unwrapped = vm->VM.unwrapResult(result)
            let managed = scope->Scope.manage(unwrapped)
            vm->VM.dump(managed)
          }

          let _installConsole = {
            let result = VM.evalModuleCode(vm, "console", consoleCode)
            let unwrapped = vm->VM.unwrapResult(result)
            let managed = scope->Scope.manage(unwrapped)
            managed
          }

          let recorderFnHandle = vm->VM.newFunction("baseRecorder", value => {
            let value = vm->VM.dump(value)->Obj.magic
            let json: recordInvocation<
              'value,
              'source,
              'line,
              'name,
              'filePath,
              'runId,
              'runGroup,
              'fileVersion,
              'scopeId,
              'callNum,
            > =
              Js.Json.parseExn(value)->Obj.magic

            let temp = Obj.magic(recorder)(
              json.value,
              json.source,
              json.line,
              json.name,
              json.filePath,
              json.runId,
              json.runGroup,
              json.fileVersion,
              json.scopeId,
              json.callNum,
            )

            temp
            ->Js.Nullable.toOption
            ->Belt.Option.forEach(temp => {
              let _length = rs->Js.Array2.push(temp->Obj.magic)
            })
            vm->VM.undefined
          })

          vm->VM.setProp(global, "baseRecorder", recorderFnHandle)

          let hijackedRecorder = `function __$i(value,source,line,name,filePath,runId,runGroup,fileVersion,scopeId,callNum) {
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

          let code = transformResult.code ++ "\n\n" ++ hijackedRecorder ++ "\n\n" ++ consoleCode

          let _result = vm->VM.evalCode(code)
        })
      } catch {
      | _ => ()
      }
      Js.Promise.resolve(rs)
    }, _)
  }

  let exampleRunner: runner = transformResult => {
    let rs: array<evaluationRecord> = []

    let {code} = transformResult

    let recorder = createRecorder(r => {
      let _length = rs->Js.Array2.push(r)
    })

    Debug.assignToWindowForDeveloperDebug(~name="__$i", recorder)
    Debug.assignToWindowForDeveloperDebug(~name="createRecorder", createRecorder)
    try {
      %raw(`(function (code) { eval(code) })`)(code)
    } catch {
    | error => Js.Console.warn2("!Error in exampleRunner.eval: ", error)
    // Omitting for this example.
    // An eval-based runner doesn't fare well with errors:
    // - Eval messes up line numbers in error stack traces
    // - You can't isolate async errors
    // I have some code that parses Error object stacktraces
    // and uses source maps generated by Babel
    // to derive the location of the error in the source text.
    // It's pretty messy and coupled to the app right now,
    // but let me know when you need it and I'll copy/paste
    // what I've got.
    }

    rs
  }

  @module("insight-kit/lib/babel") external babelTransform: plugin = "default"

  let exampleHyperEval = (~transformResult, ~runner: runner) => {
    // 1. instrument the original code

    // let transformResult = try {
    //   Ok(
    //     transform(
    //       code,
    //       ~options={
    //         "filename": filename,
    //         "plugins": [(babelTransform, {"runId": runId})],
    //       },
    //     ),
    //   )
    // } catch {
    // | error =>
    //   Js.Console.warn2("Error in hypereval.transform: ", error)
    //   Error(error)
    // }

    // 2. run code, collect run records
    try {
      transformResult->Belt.Result.map(transformResult => {
        let r = runner(transformResult)

        // r->Belt.Array.forEach(record => store->addRecord(record))
        r
      })
    } catch {
    | error =>
      Js.Console.warn2("Error in hypereval.runner: ", error)
      // Omitting for this example
      // Babel has some pretty decent errors
      // that point to the offending source position.
      // I'll send over some code to map Babel errors to EvaluationRecords.
      Error(error)
    }
  }

  let asyncHyperEval = (~transformResult, ~runner: asyncRunner) => {
    // 1. instrument the original code

    // let transformResult = try {
    //   Ok(
    //     transform(
    //       code,
    //       ~options={
    //         "filename": filename,
    //         "plugins": [(babelTransform, {"runId": runId})],
    //       },
    //     ),
    //   )
    // } catch {
    // | error =>
    //   Js.Console.warn2("Error in hypereval.transform: ", error)
    //   Error(error)
    // }

    // 2. run code, collect run records
    try {
      transformResult->Belt.Result.map(transformResult => {
        let r = runner(transformResult)

        // r->Belt.Array.forEach(record => store->addRecord(record))
        r
      })
    } catch {
    | error =>
      Js.Console.warn2("Error in hypereval.runner: ", error)
      // Omitting for this example
      // Babel has some pretty decent errors
      // that point to the offending source position.
      // I'll send over some code to map Babel errors to EvaluationRecords.
      Error(error)
    }
  }
}
