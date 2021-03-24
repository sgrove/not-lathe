type monaco
type editor
type action

type range

module Model = {
  type t

  @send
  external createModel: (~value: string, ~language: option<string>, ~uri: string) => string =
    "createModel"

  let setUri: (monaco, t, string, string) => t = %raw(`function (monaco, model1, language, newURI) {
  // Assuming model1 is the previous model
var model2 = monaco.editor.createModel(model1.getValue(), language, newURI);

var cm2 = model2._commandManager;
var cm1 = model1._commandManager;
var temp;

// SWAP currentOpenStackElement
temp = cm2.currentOpenStackElement;
cm2.currentOpenStackElement = cm1.currentOpenStackElement;
cm1.currentOpenStackElement = temp;

// SWAP past
temp = cm2.past;
cm2.past = cm1.past;
cm1.past = temp;

// SWAP future
temp = cm2.future;
cm2.future = cm1.future;
cm1.future = temp;

return model2
}`)

  @deriving(abstract)
  type modelOptions = {
    @optional
    tabSize: int,
  }

  @send external updateOptions: (t, modelOptions) => unit = "updateOptions"

  @send external getFullModelRange: t => range = "getFullModelRange"
}

module Editor: {
  @react.component
  let make: (
    ~width: string=?,
    ~height: string=?,
    ~value: string=?,
    ~className: string=?,
    ~defaultValue: string=?,
    ~language: string=?,
    ~theme: string=?,
    ~options: {..}=?,
    ~overrideServices: string=?,
    ~onChange: (string, 'event) => unit=?,
    ~editorWillMount: monaco => unit=?,
    ~onMount: (editor, monaco) => unit=?,
    ~className: string=?,
    ~path: string=?,
  ) => React.element
} = {
  @module("@monaco-editor/react") @react.component
  external make: (
    ~width: string=?,
    ~height: string=?,
    ~value: string=?,
    ~className: string=?,
    ~defaultValue: string=?,
    ~language: string=?,
    ~theme: string=?,
    ~options: {..}=?,
    ~overrideServices: string=?,
    ~onChange: (string, 'event) => unit=?,
    ~editorWillMount: monaco => unit=?,
    ~onMount: (editor, monaco) => unit=?,
    ~className: string=?,
    ~path: string=?,
  ) => React.element = "default"
}

@send external layout: editor => unit = "layout"
@send external setValue: (editor, string) => unit = "setValue"
@send external getValue: editor => string = "getValue"

@send external getModel: (editor, string) => Model.t = "getModel"

@send external getAction: (editor, string) => option<action> = "getAction"

@send external runAction: action => unit = "run"

@deriving(abstract)
type editOperation = {
  @optional
  forceMoveMarkers: bool,
  range: range,
  text: string,
}

@send
external executeEdits: (editor, Js.Nullable.t<'a>, ~edits: array<editOperation>) => unit =
  "executeEdits"

type position = {
  lineNumber: int,
  column: int,
}

@send external setPosition: (editor, position) => unit = "setPosition"
@send external getPosition: editor => position = "getPosition"
@send external getPositionAt: (Model.t, int) => position = "getPositionAt"

type selection = {
  startLineNumber: int,
  startColumn: int,
  endLineNumber: int,
  endColumn: int,
}

@send external setSelection: (editor, selection) => unit = "setSelection"

@send external revealLine: (editor, int, ~scroll: int=?) => unit = "revealLine"
@send external revealLineInCenter: (editor, int, ~scroll: int=?) => unit = "revealLineInCenter"

@send external focus: editor => unit = "focus"

type disposable

@send external onMouseUp: (editor, 'mouseEvent => unit) => disposable = "onMouseUp"

@deriving(abstract)
type editorOptions = {
  @optional
  readOnly: bool,
}

let options = editorOptions(~readOnly=true, ())

@send external updateOptions: (editor, editorOptions) => unit = "updateOptions"

let formatDocument = (editor: editor) => {
  editor
  ->getAction("editor.action.formatDocument")
  ->Belt.Option.forEach(action => action->runAction)
}

module TypeScript = {
  type outputFile = {
    name: string,
    text: string,
    writeByteOrderMark: bool,
  }

  type transpiled = {
    emitSkipped: bool,
    outputFiles: array<outputFile>,
  }

  let transpileFile = (monaco: monaco, ~uri: string, ~onComplete: transpiled => unit): unit => {
    Obj.magic(monaco)["languages"]["typescript"]["getTypeScriptWorker"]()
    ->Js.Promise.then_(worker => {
      Obj.magic(worker)(uri)->Js.Promise.then_(client => {
        let result: Js.Promise.t<transpiled> = Obj.magic(client)["getEmitOutput"](uri)
        result->Js.Promise.then_(result => onComplete(result)->Js.Promise.resolve, _)
      }, _)
    }, _)
    ->ignore
  }

  @module("typescript")
  external tsTranspile: (
    string,
    {
      @optional
      "target": string,
    },
  ) => string = "transpile"

  type semanticDiagnostic = {
    category: int,
    code: int,
    length: int,
    messageText: string,
    start: int,
  }

  let getSemanticDiagnostics: (
    monaco,
    ~filename: string,
    ~onComplete: Js.Dict.t<semanticDiagnostic> => unit,
  ) => unit = %raw(`
function gatherDiagnostics(monaco, uri, onComplete) {
  var results = {};
  monaco.languages.typescript.getTypeScriptWorker().then((_worker) => {
    model = monaco.editor.getModel(uri);
    _worker(model.uri).then((worker) => {
      worker.getScriptFileNames().then((filename) => {
        var promises = filename.map((sf) => {
          return worker.getSemanticDiagnostics(sf).then((dd) => {
            results[sf] = dd;
          });
        });

        Promise.all(promises).then(() => onComplete(results));
      });
    });
  });
}
`)

  let addLib: (. monaco, string, string) => unit = %raw("function (monaco, types, content) {
monaco.languages.typescript.typescriptDefaults.addExtraLib(
    types,
    'file:///node_modules/@types/oneGraphStudio/index.d.ts'
);
}")
}

let registerPrettier: monaco => unit = %raw(`(function (monaco) {
monaco.languages.registerDocumentFormattingEditProvider('typescript', {
  async provideDocumentFormattingEdits(model, options, token) {
    const prettier = await import('prettier/standalone');
    const babel = await import('prettier/parser-babel');
    const value = model.getValue();
    const text = prettier.format(value, {
      parser: 'babel',
      plugins: [babel],
      singleQuote: true,
    });

    return [
      {
        range: model.getFullModelRange(),
        text,
      },
    ];
  },
})

})`)
