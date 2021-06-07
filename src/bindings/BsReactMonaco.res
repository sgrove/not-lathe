type monaco
type editor

type action

type range = {
  endColumn: int,
  endLineNumber: int,
  startColumn: int,
  startLineNumber: int,
}

let makeRange: (monaco, int, int, int, int) => range = %raw(`function(monaco, a,b,c,d) {
return new monaco.Range(a,b,c,d)
}`)

module Monaco = {
  @get external getEditor: monaco => editor = "editor"
}

module Model = {
  type t

  @send @scope("editor")
  external createModel: (monaco, ~value: string, ~language: option<string>, ~uri: string) => t =
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

  @send external dispose: t => unit = "dispose"
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
@send external setModel: (editor, Model.t) => unit = "setModel"

@send external getAction: (editor, string) => option<action> = "getAction"

@send external runAction: action => unit = "run"

@send
external createModel: (editor, ~value: string, ~language: option<string>, ~uri: string) => Model.t =
  "createModel"

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

module Key = {
  type t = int
  type mod
  type code
  @get external mod: monaco => mod = "KeyMod"
  @get external code: monaco => code = "KeyCode"

  @get external ctrlCmd: mod => t = "CtrlCmd"
  @get external keyS: code => t = "KEY_S"

  let combine = (ts: array<t>): t => {
    ts->Belt.Array.reduce(0, (acc, next) => lor(acc, next))
  }
}

@send external addCommand: (editor, Key.t, unit => unit) => string = "addCommand"

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

module Widget = {
  type t

  @deriving(abstract)
  type options = {
    @optional allowEditorOverflow: bool,
    @optional suppressMouseDown: bool,
  }
}

@send external addContentWidget: (editor, Widget.t) => unit = "addContentWidget"
@send external removeContentWidget: (editor, Widget.t) => unit = "removeContentWidget"

@deriving(abstract)
type decorationMinimapOptions = {
  color: string,
  @optional darkColor: string,
  position: int,
}

@deriving(abstract)
type deltaDecorationOptions = {
  @optional afterContentClassName: string,
  @optional beforeContentClassName: string,
  @optional className: string,
  @optional firstLineDecorationClassName: string,
  @optional glyphMarginClassName: string,
  @optional glyphMarginHoverMessage: array<string>,
  @optional hoverMessage: array<string>,
  @optional inlineClassName: string,
  @optional inlineClassNameAffectsLetterSpacing: bool,
  @optional isWholeLine: bool,
  @optional linesDecorationsClassName: string,
  @optional marginClassName: string,
  @optional minimap: decorationMinimapOptions,
  // @optional overviewRuler:  IModelDecorationOverviewRulerOptions,
  // @optional stickiness:  TrackedRangeStickiness,
  @optional zIndex: int,
}

type deltaDecoration = {
  range: range,
  options: deltaDecorationOptions,
}

@send
external deltaDecorations: (editor, array<string>, array<deltaDecoration>) => array<string> =
  "deltaDecorations"

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

  let transpileFile = (monaco: monaco, ~uri: string, ~onComplete: (. transpiled) => unit): unit => {
    Obj.magic(monaco)["languages"]["typescript"]["getTypeScriptWorker"](.)
    ->Js.Promise.then_(worker => {
      Obj.magic(worker)(. uri)->Js.Promise.then_(client => {
        let result: Js.Promise.t<transpiled> = Obj.magic(client)["getEmitOutput"](. uri)
        result->Js.Promise.then_(result => onComplete(. result)->Js.Promise.resolve, _)
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

let createWidget: (
  ~monaco: monaco,
  ~lineNum: int,
  ~hasError: bool,
  ~horizontalOffset: int,
  ~content: string,
) => Widget.t = %raw(`function createContentWidget(
  Monaco,
  lineNum,
  hasError,
  horizontalOffset,
  content
) {
  const widget = {
    domNode: null,
    allowEditorOverflow: true,
    getId: function () {
      return "hypercode:" + lineNum;
    },
    getPosition: function () {
      return {
        position: {
          lineNumber: lineNum,
          column: horizontalOffset
        },
        preference: [Monaco.editor.ContentWidgetPositionPreference.EXACT]
      };
    },
    getDomNode: function () {
      if (!this.domNode) {
        this.domNode = document.createElement("div");
        this.domNode.innerText = content;

        // layout
        this.domNode.style.marginLeft = "4px";
        this.domNode.style.padding = "0px 4px";
        this.domNode.style.borderRadius = "2px";

        // display
        this.domNode.style.background = !hasError ? "lightgreen" : "pink";
        this.domNode.style.color = !hasError ? "darkgreen" : "darkred";

        // HACKY: copied from monaco internal
        this.domNode.style.fontFamily = 'Menlo, Monaco, "Courier New", monospace';
        this.domNode.style.fontSize = "12px";
        this.domNode.style.lineHeight = "18px";
      }
      return this.domNode;
    }
  };

  return widget;
}
`)
