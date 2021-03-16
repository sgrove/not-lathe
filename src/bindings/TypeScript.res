type ast

@module("typescript")
external createSourceFile: (~name: string, ~source: string, ~target: int, bool) => ast =
  "createSourceFile"

@send external getChildren: ast => array<ast> = "getChildren"

@module("typescript") external visitNode: (ast, ast => unit) => unit = "visitNode"

@module("typescript") external isFunctionDeclaration: ast => bool = "isFunctionDeclaration"

let source = `import { AboutMeInput, AboutMeVariables } from 'oneGraphStudio';

export function makeVariablesForAboutMe(
  payload: AboutMeInput
): AboutMeVariables {
  return {};
}

export function makeVariablesForCreateDevToArticle(
  payload: CreateDevToArticleInput
): CreateDevToArticleVariables {
  return {};
}

export function makeVariablesForFindMyTwitchUserIdAndEmail(
  payload: FindMyTwitchUserIdAndEmailInput
): FindMyTwitchUserIdAndEmailVariables {
  return {};
}

export function makeVariablesForAddPullRequestCommentMutation(
  payload: AddPullRequestCommentMutationInput
): AddPullRequestCommentMutationVariables {
  return {};
}

export function makeVariablesForAmILoggedIntoDevTo(
  payload: AmILoggedIntoDevToInput
): AmILoggedIntoDevToVariables {
  return {};
}

export function makeVariablesForGetNpmPackageDownloads(
  payload: GetNpmPackageDownloadsInput
): GetNpmPackageDownloadsVariables {
  return {};
}
`

type range = {
  start: int,
  end: int,
}

@get external name: ast => option<ast> = "name"
@send external getText: (ast, ast) => string = "getText"
@send external getStart: ast => int = "getStart"
@send external getEnd: ast => int = "getEnd"

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
