type ast

@module("typescript")
external createSourceFile: (~name: string, ~source: string, ~target: int, bool) => ast =
  "createSourceFile"

@send external getChildren: (ast, ast) => array<ast> = "getChildren"

@module("typescript") external visitNode: (ast, ast => unit) => unit = "visitNode"

@module("typescript") external isFunctionDeclaration: ast => bool = "isFunctionDeclaration"
@module("typescript") external isVariableDeclaration: ast => bool = "isVariableDeclaration"

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

type positionRange = {
  start: int,
  firstStatementStart: option<int>,
  end: int,
}

let findFnPos = (ast: ast, targetName: string) => {
  let fnNode = ref(None)

  let rec helper = node => {
    switch fnNode.contents {
    | None =>
      switch isFunctionDeclaration(node) {
      | false => node->getChildren(ast)->Belt.Array.forEach(n => helper(n))
      | true =>
        let fnName = node->name->Belt.Option.map(name => name->getText(ast))
        fnName == Some(targetName)
          ? fnNode := Some(node)
          : node->getChildren(ast)->Belt.Array.forEach(n => helper(n))
      }

    | Some(_) => ()
    }
  }

  visitNode(ast, helper)

  fnNode.contents->Belt.Option.map(node => {
    try {
      let startPos = Obj.magic(node)["body"]["statements"][0]["pos"]
      {start: node->getStart, firstStatementStart: Some(startPos - 1), end: node->getEnd}
    } catch {
    | _ => {
        start: node->getStart,
        firstStatementStart: None,
        end: node->getEnd,
      }
    }
  })
}

type declaration<'a> = 'a

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

let findAllVariableDeclarationsInFunctions = (ast: ast): array<ast> => {
  let nodes =
    Obj.magic(ast)["statements"]
    ->Belt.Array.map(topLeveNode => {
      switch isFunctionDeclaration(topLeveNode) {
      | false => []
      | true =>
        let rec helper = node => {
          switch isVariableDeclaration(node) {
          | false => node->getChildren(ast)->Belt.Array.map(n => helper(n))->Belt.Array.concatMany
          | true => [node]
          }
        }

        helper(topLeveNode)
      }
    })
    ->Belt.Array.concatMany

  nodes
}

Debug.assignToWindowForDeveloperDebug(
  ~name="findAllVariableDeclarationsInFunctions",
  findAllVariableDeclarationsInFunctions,
)

let findVariableDeclarationAtPosition = (ast: ast, position: int): option<ast> => {
  let finalNode = ref(None)

  let rec helper = node => {
    switch isVariableDeclaration(node) {
    | false => node->getChildren(ast)->Belt.Array.forEach(n => helper(n))
    | true =>
      let start = Obj.magic(node)["pos"]
      let end = Obj.magic(node)["end"]
      let containsPosition = start <= position && position <= end

      containsPosition
        ? finalNode := Some(node)
        : node->getChildren(ast)->Belt.Array.forEach(n => helper(n))
    }
  }

  visitNode(ast, helper)

  finalNode.contents
}

let findNodeAtPosition = (ast: ast, position: int): option<ast> => {
  let finalNode = ref(None)

  let rec helper = node => {
    let start = Obj.magic(node)["pos"]
    let end = Obj.magic(node)["end"]
    let containsPosition = start <= position && position <= end

    containsPosition
      ? {
          finalNode := Some(node)
          node->getChildren(ast)->Belt.Array.forEach(n => helper(n))
        }
      : node->getChildren(ast)->Belt.Array.forEach(n => helper(n))
  }

  visitNode(ast, helper)

  finalNode.contents
}

Debug.assignToWindowForDeveloperDebug(
  ~name="findVariableDeclarationAtPosition",
  findVariableDeclarationAtPosition,
)

Debug.assignToWindowForDeveloperDebug(~name="findNodeAtPosition", findNodeAtPosition)

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

module TypeFormatFlags = {
  type t
  @module("typescript") @scope("TypeFormatFlags")
  external writeArrayAsGenericType: t = "WriteArrayAsGenericType"
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
      | false => node->Obj.magic->getChildren(ast)->Belt.Array.forEach(n => helper(n->Obj.magic))
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
      | false => node->Obj.magic->getChildren(ast)->Belt.Array.forEach(n => helper(n->Obj.magic))
      }

    | _ => node->Obj.magic->getChildren(ast)->Belt.Array.forEach(n => helper(n->Obj.magic))
    }
  }

  visitNode(ast, helper->Obj.magic)

  assigmentStartAndEnd.contents
}

type simpleFunctionType = {
  name: string,
  firstParamType: option<string>,
  returnType: option<string>,
}

let findFunctionTypes = (ast: ast): Js.Dict.t<simpleFunctionType> => {
  let results = ref([])

  Obj.magic(ast)["statements"]->Belt.Array.forEach(node => {
    let node = Obj.magic(node)
    switch syntaxOfNumberKind->Js.Dict.get(node["kind"]) {
    | Some("FunctionDeclaration") =>
      let firstParamType: option<string> = %raw(`node?.parameters?.[0]?.type?.getText(ast)`)
      let returnType: option<string> = %raw(`node?.type?.getText(ast)`)
      let name: option<string> = %raw(`node?.name?.getText(ast)`)

      name->Belt.Option.forEach(name => {
        results :=
          results.contents->Belt.Array.concat([
            {
              name: name,
              firstParamType: firstParamType,
              returnType: returnType,
            },
          ])
      })

    | _ => ()
    }
  })

  results.contents->Belt.Array.map(fn => (fn.name, fn))->Js.Dict.fromArray
}

type returnObjectProperty = {
  start: int,
  end: int,
  name: string,
}

type returnObjectPositions = {
  start: int,
  end: int,
  objectPosition: range,
  property: option<returnObjectProperty>,
}

let findLastReturnObjectPos = (ast: ast, ~functionName: string, ~properyName: string): option<
  returnObjectPositions,
> => {
  let fnNode = ref(None)

  let rec helper = node => {
    switch fnNode.contents {
    | None =>
      switch isFunctionDeclaration(node) {
      | false => node->getChildren(ast)->Belt.Array.forEach(n => helper(n))
      | true =>
        let fnName = node->name->Belt.Option.map(name => name->getText(ast))
        fnName == Some(functionName)
          ? fnNode := Some(node)
          : node->getChildren(ast)->Belt.Array.forEach(n => helper(n))
      }

    | Some(_) => ()
    }
  }

  visitNode(ast, helper)

  fnNode.contents->Belt.Option.flatMap(node => {
    try {
      Obj.magic(node)["body"]["statements"]
      ->Belt.Array.reverse
      ->Belt.Array.getBy(statement => {
        switch syntaxOfNumberKind->Js.Dict.get(statement["kind"]) {
        | Some("ReturnStatement") =>
          let isObjectLiteral =
            statement["expression"]
            ->Belt.Option.map(expression => {
              switch syntaxOfNumberKind->Js.Dict.get(expression["kind"]) {
              | Some("ObjectLiteralExpression") => // We found a return node with an object literal
                true
              | _ => false
              }
            })
            ->Belt.Option.isSome

          isObjectLiteral
        | _ => false
        }
      })
      ->Belt.Option.map(returnStatement => {
        let expression = Obj.magic(returnStatement)["expression"]
        let property = expression["properties"]->Belt.Array.getBy(property => {
          property["name"]["escapedText"] == properyName
        })
        {
          start: returnStatement["pos"],
          end: returnStatement["end"],
          objectPosition: {
            start: expression["pos"],
            end: expression["end"],
          },
          property: property->Belt.Option.map(property => {
            start: property["pos"],
            end: property["end"],
            name: properyName,
          }),
        }
      })
    } catch {
    | _ => None
    }
  })
}

type emptyFunctionTest =
  | Empty // No statements at all
  | EmptyObjectReturn // single: return {}
  | ProbablyGenerated // single: return {repositoryId: repositoryId, labelIds: labelIds}
  | NotEmpty

let isFunctionEmpty = (ast: ast, targetName: string): option<emptyFunctionTest> => {
  let fnNode = ref(None)

  let rec helper = node => {
    switch fnNode.contents {
    | None =>
      switch isFunctionDeclaration(node) {
      | false => node->getChildren(ast)->Belt.Array.forEach(n => helper(n))
      | true =>
        let fnName = node->name->Belt.Option.map(name => name->getText(ast))
        fnName == Some(targetName)
          ? fnNode := Some(node)
          : node->getChildren(ast)->Belt.Array.forEach(n => helper(n))
      }

    | Some(_) => ()
    }
  }

  visitNode(ast, helper)

  fnNode.contents->Belt.Option.map(node => {
    try {
      let statements = Obj.magic(node)["body"]["statements"]
      switch statements {
      | [] => Empty
      | [statement] =>
        try {
          switch syntaxOfNumberKind->Js.Dict.get(statement["kind"]) {
          | Some("ReturnStatement") =>
            let expression = statement["expression"]

            switch syntaxOfNumberKind->Js.Dict.get(expression["kind"]) {
            | Some("ObjectLiteralExpression") =>
              // We found a return node with an object literal
              switch expression["properties"] {
              | [] => EmptyObjectReturn
              | properties =>
                properties->Belt.Array.every(property => {
                  let name = property["name"]->getText(ast)
                  let value = property["initializer"]->getText(ast)
                  name == value
                })
                  ? ProbablyGenerated
                  : NotEmpty
              }
            | _ => NotEmpty
            }

          | _ => NotEmpty
          }
        } catch {
        | _ => NotEmpty
        }
      | _ => NotEmpty
      }
    } catch {
    | _ => NotEmpty
    }
  })
}

Debug.assignToWindowForDeveloperDebug(~name="isFunctionEmpty", isFunctionEmpty)

Debug.assignToWindowForDeveloperDebug(~name="ts", ts)

module Map = {
  type t
  @new external make: unit => t = "Map"

  @send external set: (t, string, string) => unit = "set"

  // let addLib = (name, map: t) => {
  //   map->set(name, getLib)
  // }
}

module VirtualFileSystem = {
  type system
  type env

  @deriving(abstract)
  type cdnOptions = {target: int}
  @module("@typescript/vfs")
  external createDefaultMapFromCDN: (cdnOptions, string, bool, ts) => Js.Promise.t<Map.t> =
    "createDefaultMapFromCDN"

  @module("@typescript/vfs") external createSystem: (. Map.t) => system = "createSystem"

  @module("@typescript/vfs")
  external createVirtualTypeScriptEnvironment: (. system, array<string>, ts, 'compilerOpts) => env =
    "createVirtualTypeScriptEnvironment"

  // let make = () => {
  //   let shouldCache = true
  //   // let fsMap = Map.make()
  //   createDefaultMapFromCDN(
  //     cdnOptions(~target=Obj.magic(ts)["ScriptTarget"]["ES2015"]),
  //     "3.7.3",
  //     shouldCache,
  //     ts,
  //   )->Js.Promise.then_(fsMap => {
  //     let system = createSystem(. fsMap)
  //     let env = createVirtualTypeScriptEnvironment(. system, ["main.ts"], ts, {"o": true})
  //     let program = Obj.magic(env)["languageService"]["getProgram"](.)
  //     let typeChecker = Obj.magic(program)["getTypeChecker"](.)
  //     Debug.assignToWindowForDeveloperDebug(~name="tsSystem", system)
  //     Debug.assignToWindowForDeveloperDebug(~name="tsEnv", env)
  //     Debug.assignToWindowForDeveloperDebug(~name="tsProgram", program)
  //     Debug.assignToWindowForDeveloperDebug(~name="tsTypeChecker", typeChecker)
  //     Debug.assignToWindowForDeveloperDebug(~name="fsMap", fsMap)
  //     fsMap->Js.Promise.resolve
  //   }, _)
  // }

  let makeWithFileSystem = (~mainFile, ~onCreateFileSystem) => {
    let shouldCache = true
    // let fsMap = Map.make()
    createDefaultMapFromCDN(
      cdnOptions(~target=Obj.magic(ts)["ScriptTarget"]["ES2015"]),
      "3.7.3",
      shouldCache,
      ts,
    )->Js.Promise.then_(fsMap => {
      onCreateFileSystem(. fsMap)
      Debug.assignToWindowForDeveloperDebug(~name="fsMap", fsMap)
      let system = createSystem(. fsMap)
      let env = createVirtualTypeScriptEnvironment(. system, [mainFile], ts, %raw("{}"))
      Debug.assignToWindowForDeveloperDebug(~name="tsEnv", env)
      let program = Obj.magic(env)["languageService"]["getProgram"](.)
      Debug.assignToWindowForDeveloperDebug(~name="tsProgram", program)
      let typeChecker = Obj.magic(program)["getTypeChecker"](.)
      Debug.assignToWindowForDeveloperDebug(~name="tsTypeChecker", typeChecker)
      (env, program, typeChecker, fsMap, system)->Js.Promise.resolve
    }, _)
  }

  let () = {
    // Debug.assignToWindowForDeveloperDebug(~name="makeFsMap", make)
    Debug.assignToWindowForDeveloperDebug(~name="makeWithFileSystem", makeWithFileSystem)
  }
  // let r = Obj.magic(env)["languageService"]["getDocumentHighlights"]("main.ts", 0, ["main.ts"])
  // Js.log2("R: ", r)

  // let compilerOpts = Js.Dict.empty()
}

type program
type typeChecker

// let r = {
// t = await  makeWithFileSystem(fs => {
// fs.set("main.ts", "const introValue = [42 + 22]");
// console.log("Got fs: ", fs)
// }).then(r => {
// n =  tsProgram.getSourceFile('main.ts').statements[0].declarationList.declarations[0];
// at = tsProgram.getTypeChecker().getTypeAtLocation(n);
// return tsProgram.getTypeChecker().typeToString(at, n, ts.TypeFormatFlags.WriteArrayAsGenericType);})
// }

let findTypeOfVariableDeclarationAtPosition = (
  ~env: VirtualFileSystem.env,
  ~fileName: string,
  ~position: int,
): option<('a, string)> => {
  let program: program = Obj.magic(env)["languageService"]["getProgram"](.)
  let typeChecker = Obj.magic(program)["getTypeChecker"](.)
  let ast = Obj.magic(program)["getSourceFile"](. fileName)

  let node = findVariableDeclarationAtPosition(ast, position)

  node->Belt.Option.map(node => (node, typeChecker["getTypeAtLocation"](. node)))
}

let printType = (~flag=0, ~typeChecker: typeChecker, ~typeNode, ~node, ()) => {
  Obj.magic(typeChecker)["typeToString"](. typeNode, node, flag)
}
