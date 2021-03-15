type ast

module Walk = {
  type node

  @deriving(abstract)
  type walker = {
    @optional @as("ArrayExpression") arrayExpression: node => unit,
    @optional @as("ArrayPattern") arrayPattern: node => unit,
    @optional @as("ArrowFunctionExpression") arrowFunctionExpression: node => unit,
    @optional @as("AssignmentExpression") assignmentExpression: node => unit,
    @optional @as("AssignmentPattern") assignmentPattern: node => unit,
    @optional @as("AwaitExpression") awaitExpression: node => unit,
    @optional @as("BinaryExpression") binaryExpression: node => unit,
    @optional @as("BlockStatement") blockStatement: node => unit,
    @optional @as("BreakStatement") breakStatement: node => unit,
    @optional @as("CallExpression") callExpression: node => unit,
    @optional @as("CatchClause") catchClause: node => unit,
    @optional @as("ChainExpression") chainExpression: node => unit,
    @optional @as("Class") class: node => unit,
    @optional @as("ClassBody") classBody: node => unit,
    @optional @as("ClassDeclaration") classDeclaration: node => unit,
    @optional @as("ClassExpression") classExpression: node => unit,
    @optional @as("ConditionalExpression") conditionalExpression: node => unit,
    @optional @as("ContinueStatement") continueStatement: node => unit,
    @optional @as("DebuggerStatement") debuggerStatement: node => unit,
    @optional @as("DoWhileStatement") doWhileStatement: node => unit,
    @optional @as("EmptyStatement") emptyStatement: node => unit,
    @optional @as("ExportAllDeclaration") exportAllDeclaration: node => unit,
    @optional @as("ExportDefaultDeclaration") exportDefaultDeclaration: node => unit,
    @optional @as("ExportNamedDeclaration") exportNamedDeclaration: node => unit,
    @optional @as("Expression") expression: node => unit,
    @optional @as("ExpressionStatement") expressionStatement: node => unit,
    @optional @as("ForInStatement") forInStatement: node => unit,
    @optional @as("ForInit") forInit: node => unit,
    @optional @as("ForOfStatement") forOfStatement: node => unit,
    @optional @as("ForStatement") forStatement: node => unit,
    @optional @as("Function") function: node => unit,
    @optional @as("FunctionDeclaration") functionDeclaration: node => unit,
    @optional @as("FunctionExpression") functionExpression: node => unit,
    @optional @as("Identifier") identifier: node => unit,
    @optional @as("IfStatement") ifStatement: node => unit,
    @optional @as("ImportDeclaration") importDeclaration: node => unit,
    @optional @as("ImportDefaultSpecifier") importDefaultSpecifier: node => unit,
    @optional @as("ImportExpression") importExpression: node => unit,
    @optional @as("ImportNamespaceSpecifier") importNamespaceSpecifier: node => unit,
    @optional @as("ImportSpecifier") importSpecifier: node => unit,
    @optional @as("LabeledStatement") labeledStatement: node => unit,
    @optional @as("Literal") literal: node => unit,
    @optional @as("LogicalExpression") logicalExpression: node => unit,
    @optional @as("MemberExpression") memberExpression: node => unit,
    @optional @as("MemberPattern") memberPattern: node => unit,
    @optional @as("MetaProperty") metaProperty: node => unit,
    @optional @as("MethodDefinition") methodDefinition: node => unit,
    @optional @as("NewExpression") newExpression: node => unit,
    @optional @as("ObjectExpression") objectExpression: node => unit,
    @optional @as("ObjectPattern") objectPattern: node => unit,
    @optional @as("ParenthesizedExpression") parenthesizedExpression: node => unit,
    @optional @as("Pattern") pattern: node => unit,
    @optional @as("Program") program: node => unit,
    @optional @as("Property") property: node => unit,
    @optional @as("RestElement") restElement: node => unit,
    @optional @as("ReturnStatement") returnStatement: node => unit,
    @optional @as("SequenceExpression") sequenceExpression: node => unit,
    @optional @as("SpreadElement") spreadElement: node => unit,
    @optional @as("Statement") statement: node => unit,
    @optional @as("Super") super: node => unit,
    @optional @as("SwitchCase") switchCase: node => unit,
    @optional @as("SwitchStatement") switchStatement: node => unit,
    @optional @as("TaggedTemplateExpression") taggedTemplateExpression: node => unit,
    @optional @as("TemplateElement") templateElement: node => unit,
    @optional @as("TemplateLiteral") templateLiteral: node => unit,
    @optional @as("ThisExpression") thisExpression: node => unit,
    @optional @as("ThrowStatement") throwStatement: node => unit,
    @optional @as("TryStatement") tryStatement: node => unit,
    @optional @as("UnaryExpression") unaryExpression: node => unit,
    @optional @as("UpdateExpression") updateExpression: node => unit,
    @optional @as("VariableDeclaration") variableDeclaration: node => unit,
    @optional @as("VariableDeclarator") variableDeclarator: node => unit,
    @optional @as("VariablePattern") variablePattern: node => unit,
    @optional @as("WhileStatement") whileStatement: node => unit,
    @optional @as("WithStatement") withStatement: node => unit,
    @optional @as("YieldExpression") yieldExpression: node => unit,
  }
  @module("acorn-walk") external simple: (ast, walker) => unit = "simple"

  @get external name: node => option<string> = "name"
}

@deriving(abstract)
type parseOptions = {
  ecmaVersion: int,
  @optional
  sourceType: [#"module" | #script],
}

@module("acorn") external parse: (string, parseOptions) => ast = "parse"

let source = "function getIssue(payload) {
    return payload.WatchForIssue?.data?.github?.issueCommentEvent?.issue;
  }
  
  export function getIssueId(payload) {
    return getIssue(payload)?.id;
  }

  function unexported(){
      true
  }
  

  export const me = 199;

  export const something = unexported

  export const other = function wow() { true }

  export function final() { true }

  export function getIssueTitle(payload) {
    const issue = getIssue(payload);
  
    const rateLimit = payload.GitHubRateLimits.data.gitHub.rateLimit;
  
    if (issue) {
      if (rateLimit.remaining < 4990) {
        return null;
      }
  
      if (rateLimit.remaining < 4995) {
        return `Sorry, API limits are low, will reset at ${rateLimit.resetAt}`;
      }
  
      const totalComments = issue.comments.totalCount;
      const totalReactions = issue.reactions.totalCount;
  
      return `This GitHub issue has ${totalComments} comments and ${totalReactions} reactions`;
    }
  }"

// var fns = []; walk.simple(r, {"ExportNamedDeclaration": (node) => node.declaration.type === 'FunctionDeclaration' ? fns.push(node.declaration.id.name) : null}); fns

let collectExportedFunctionNames = (parsed: ast): array<string> => {
  let functions = []

  let walker = Walk.walker(~exportNamedDeclaration=node => {
    Obj.magic(node)["declaration"]
    ->Js.Undefined.toOption
    ->Belt.Option.forEach(declaration =>
      switch declaration["type"]->Js.Undefined.toOption {
      | Some(#FunctionDeclaration) =>
        let name: string = declaration["id"]["name"]
        functions->Js.Array2.push(name)->ignore
      | _ => ()
      }
    )
  }, ())
  Walk.simple(parsed, walker)
  functions
}

Debug.assignToWindowForDeveloperDebug(~name="parsed", 10)

// Js.log2("Sanity test for source, found fn names: ", collectExportedFunctionNames(parsed))
