type scriptDependency = {
  name: string,
  version: string,
  main: string,
}

type localFile = {
  path: string,
  body: string,
}

@module("../lib/evalScript.js")
external executeScript: (
  ~payload: string,
  ~script: string,
  ~functionName: string,
  ~scriptDependencies: array<scriptDependency>,
  ~localFiles: array<localFile>,
) => Js.Promise.t<string> = "executeScript"

@module("../lib/evalScript.js")
external replaceRequires: string => string = "replaceRequires"
