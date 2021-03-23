type ast

@module("typescript")
external createSourceFile: (~name: string, ~source: string, ~target: int, bool) => ast =
  "createSourceFile"

@send external getChildren: ast => array<ast> = "getChildren"

@module("typescript") external visitNode: (ast, ast => unit) => unit = "visitNode"

@module("typescript") external isFunctionDeclaration: ast => bool = "isFunctionDeclaration"

type range = {
  start: int,
  end: int,
}

type lineAndCharacter = {
  line: int,
  character: int,
}

type ts
@module("typescript") external ts: ts = "default"

@get external name: ast => option<ast> = "name"
@send external getText: (ast, ast) => string = "getText"
@send external getStart: ast => int = "getStart"
@send external getEnd: ast => int = "getEnd"
@send
external getPositionOfLineAndCharacter: (ast, int, int) => int = "getPositionOfLineAndCharacter"
@send
external getLineAndCharacterOfPosition: (ast, int) => lineAndCharacter =
  "getLineAndCharacterOfPosition"

let findFnPos = (ast: ast, targetName: string) => {
  let fnNode = ref(None)

  let rec helper = node => {
    switch fnNode.contents {
    | None =>
      switch isFunctionDeclaration(node) {
      | false => node->getChildren->Belt.Array.forEach(n => helper(n))
      | true =>
        let fnName = node->name->Belt.Option.map(name => name->getText(ast))
        fnName == Some(targetName)
          ? fnNode := Some(node)
          : node->getChildren->Belt.Array.forEach(n => helper(n))
      }

    | Some(_) => ()
    }
  }

  visitNode(ast, helper)

  fnNode.contents->Belt.Option.map(node => (node->getStart, node->getEnd))
}

type declaration<'a> = Js.t<'a>

let findContainingDeclaration = (ast: ast, position: int): option<declaration<'a>> => {
  let containingFunction = Obj.magic(ast)["statements"]->Belt.Array.getBy((
    declaration: declaration<'a>,
  ) => {
    let body = declaration["body"]
    let parameters = declaration["parameters"]
    let isFunctionDeclaration =
      body->Js.Undefined.toOption->Belt.Option.isSome &&
        parameters->Js.Undefined.toOption->Belt.Option.isSome

    let start = declaration["pos"]
    let end = declaration["end"]
    let containsPosition = start <= position && position <= end

    switch (isFunctionDeclaration, containsPosition) {
    | (false, _)
    | (_, false) => false
    | (true, true) => true
    }
  })

  containingFunction
}

let findPositionOfFirstLineOfContainingFunctionForPosition = (ast: ast, position: int): option<
  int,
> => {
  ast
  ->findContainingDeclaration(position)
  ->Belt.Option.flatMap(declarationNode => {
    try {
      Some(Obj.magic(declarationNode)["body"]["statements"][0]["pos"])
    } catch {
    | _ => None
    }
  })
}

@module("typescript") external syntaxToNumberKind: Js.Dict.t<int> = "SyntaxKind"
@module("typescript") external syntaxOfNumberKind: Js.Dict.t<string> = "SyntaxKind"

@module("typescript") @scope("SyntaxKind") external expressionStatement: int = "ExpressionStatement"
@module("typescript") @scope("SyntaxKind") external variableDeclaration: int = "VariableDeclaration"

type expressionStatementSearch = {start: int, end: int, name: string}

let findContainingDeclaration = (ast: ast, position: int): option<expressionStatementSearch> => {
  let assigmentStartAndEnd: ref<option<expressionStatementSearch>> = ref(None)

  let rec helper = node => {
    switch syntaxOfNumberKind->Js.Dict.get(node["kind"]) {
    | Some("ExpressionStatement") =>
      let start = node["pos"]
      let end = node["end"]
      let containsPosition = start <= position && position <= end

      switch containsPosition {
      | true =>
        Debug.assignToWindowForDeveloperDebug(~name="debugNode", node)
        let name = node["expression"]["left"]["escapedText"]
        assigmentStartAndEnd :=
          Some({
            start: start,
            end: end,
            name: name,
          })
      | false => node->Obj.magic->getChildren->Belt.Array.forEach(n => helper(n->Obj.magic))
      }

    | Some("VariableDeclaration") =>
      let start = node["pos"]
      let end = node["end"]
      let containsPosition = start <= position && position <= end

      switch containsPosition {
      | true =>
        Debug.assignToWindowForDeveloperDebug(~name="debugNode", node)
        let name = node["name"]["escapedText"]
        assigmentStartAndEnd :=
          Some({
            start: start,
            end: end,
            name: name,
          })
      | false => node->Obj.magic->getChildren->Belt.Array.forEach(n => helper(n->Obj.magic))
      }

    | _ => node->Obj.magic->getChildren->Belt.Array.forEach(n => helper(n->Obj.magic))
    }
  }

  visitNode(ast, helper->Obj.magic)

  assigmentStartAndEnd.contents
}
