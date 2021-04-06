export const devJsonChain = {
  name: "pushFilesToBranch",
  id: "7dca56ce-7ea5-44c7-a7e1-c3a185f53e0a",
  script:
    "import {\n  CreateTreeInput,\n  CreateTreeVariables,\n  DefaultBranchRefInput,\n  DefaultBranchRefVariables,\n  UserInputInput,\n  UserInputVariables,\n  CreateRefInput,\n  CreateRefVariables,\n  CheckIfRefExistsInput,\n  CheckIfRefExistsVariables,\n  FilesOnRefInput,\n  FilesOnRefVariables,\n  CreateCommitInput,\n  CreateCommitVariables,\n  UpdateRefInput,\n  UpdateRefVariables,\n} from 'oneGraphStudio';\n\nimport sha1 from 'js-sha1';\nimport { TextEncoder } from 'text-encoder';\n\nconst encoder = new TextEncoder();\n\nconst computeGitHash = (source) =>\n  sha1('blob ' + encoder.encode(source).length + '\\0' + source);\n\nconst findExistingFileByPath = (existingFiles, path) => {\n  const parts = path.split('/');\n  let candidates = existingFiles;\n\n  const helper = (parts) => {\n    const next = parts[0];\n    const remainingParts = parts.slice(1);\n    const nextFile = candidates.find((gitFile) => gitFile.name === next);\n\n    if (!nextFile) return null;\n\n    if (remainingParts.length === 0) {\n      return nextFile;\n    }\n\n    candidates = nextFile.object?.entries || [];\n    return helper(remainingParts);\n  };\n\n  return helper(parts);\n};\n\nexport function makeVariablesForCreateTree(\n  payload: CreateTreeInput\n): CreateTreeVariables {\n  const headRef =\n    payload.CreateRef?.data?.gitHub?.createRef?.ref ||\n    payload.DefaultBranchRef?.data?.gitHub?.repository?.defaultBranchRef;\n\n  let headRefNodeId = headRef?.id;\n  let headRefCommitSha = headRef?.target?.oid;\n  let headRefTreeSha = headRef?.target?.tree?.oid;\n  let branch = headRef?.name;\n  const fullyQualifiedRefName = `refs/heads/${branch}`;\n\n  let inputFiles = payload.UserInput?.data?.oneGraph?.treeFiles || [];\n\n  let existingFiles =\n    payload.DefaultBranchRef?.data?.gitHub?.repository?.defaultBranchRef?.target\n      ?.history?.edges[0]?.node?.tree?.entries ||\n    payload.FilesOnRef?.data?.gitHub?.repository?.ref?.target?.history?.edges[0]\n      ?.node?.tree?.entries;\n\n  const fileHashes = inputFiles?.reduce((acc, next) => {\n    console.log('Computing next hash for: ', next);\n    acc[next.path] = computeGitHash(next.content || 'default');\n    return acc;\n  }, {});\n\n  // Try to calculate the minimum number of files we can upload\n  const changeset = inputFiles?.reduce(\n    (acc, file) => {\n      // This will only look two levels down since that's the limit of our GraphQL query\n      const existingFile = findExistingFileByPath(existingFiles, file.path);\n      if (!existingFile) {\n        acc['new'] = [...acc.new, file];\n        return acc;\n      }\n\n      // This file already exists, so check if the hash is the same\n      if (fileHashes[file.path] === existingFile.oid) {\n        const tempFile = {\n          ...file,\n        };\n\n        delete tempFile['content'];\n\n        acc['unchanged'] = [\n          ...acc.unchanged,\n          { ...tempFile, sha: fileHashes[file.path] },\n        ];\n        return acc;\n      }\n\n      // The file exists, but its hash has changed;\n      acc['changed'] = [...acc.changed, file];\n      return acc;\n    },\n    { unchanged: [], new: [], changed: [] }\n  );\n\n  // Don't bother uploading files with unchanged hashes (Git will filter these out of a changeset anyway)\n  const treeFiles = [...changeset.new, ...changeset.changed];\n\n  console.log('Changeset: ', inputFiles, changeset);\n\n  const treeJson = {\n    base_tree: headRefTreeSha,\n    tree: treeFiles,\n  };\n\n  const owner = String(payload.UserInput?.data?.oneGraph?.owner);\n  const name = String(payload.UserInput?.data?.oneGraph?.name);\n\n  const path = `/repos/${owner}/${name}/git/trees`;\n\n  const acceptOverrides = !!payload.UserInput?.data?.oneGraph?.acceptOverrides;\n\n  if ((changeset.changed || []).length > 0 && !acceptOverrides) {\n    return {\n      confirmationNeeded: 'Some files have changed and will be overwritten',\n      changeset,\n    };\n  }\n\n  return { path: path, treeJson: treeJson };\n}\n\nexport function makeVariablesForDefaultBranchRef(\n  payload: DefaultBranchRefInput\n): DefaultBranchRefVariables {\n  return {\n    owner: String(payload.UserInput?.data?.oneGraph?.owner),\n    name: String(payload.UserInput?.data?.oneGraph?.name),\n  };\n}\n\nexport function makeVariablesForFilesOnRef(\n  payload: FilesOnRefInput\n): FilesOnRefVariables {\n  const branch = payload.UserInput?.data?.oneGraph?.branch;\n\n  return {\n    owner: String(payload.UserInput?.data?.oneGraph?.owner),\n    name: String(payload.UserInput?.data?.oneGraph?.name),\n    fullyQualifiedRefName: !!branch ? `refs/heads/${branch}` : null,\n  };\n}\n\nexport function makeVariablesForCreateCommit(\n  payload: CreateCommitInput\n): CreateCommitVariables {\n  const headRef =\n    payload.CheckIfRefExists?.data?.gitHub?.repository?.ref ||\n    payload.CreateRef?.data?.gitHub?.createRef?.ref ||\n    payload.DefaultBranchRef?.data?.gitHub?.repository?.defaultBranchRef;\n\n  const message = payload.UserInput?.data?.oneGraph?.message;\n  const treeResults =\n    payload.CreateTree?.data?.gitHub?.makeRestCall?.post?.jsonBody;\n  const newTreeSha = treeResults?.sha;\n  const headRefCommitSha = headRef.target.oid;\n\n  const owner = String(payload.UserInput?.data?.oneGraph?.owner);\n  const name = String(payload.UserInput?.data?.oneGraph?.name);\n\n  const path = `/repos/${owner}/${name}/git/commits`;\n\n  const commitJson = {\n    message: message,\n    tree: newTreeSha,\n    parents: [headRefCommitSha],\n  };\n\n  return {\n    path: path,\n    commitJson: commitJson,\n  };\n}\n\nexport function makeVariablesForCreateRef(\n  payload: CreateRefInput\n): CreateRefVariables {\n  const refAlreadyExists = !!payload.CheckIfRefExists?.data?.gitHub?.repository\n    ?.ref?.target?.oid;\n  const branch = refAlreadyExists\n    ? null\n    : payload.UserInput?.data?.oneGraph?.branch;\n\n  return {\n    name: !!branch ? `refs/heads/${branch}` : null,\n    repositoryId: payload.DefaultBranchRef?.data?.gitHub?.repository?.id,\n    oid:\n      payload.DefaultBranchRef?.data?.gitHub?.repository?.defaultBranchRef\n        ?.target?.oid,\n  };\n}\n\nexport function makeVariablesForUpdateRef(\n  payload: UpdateRefInput\n): UpdateRefVariables {\n  const headRef =\n    payload.CheckIfRefExists?.data?.gitHub?.repository?.ref ||\n    payload.CreateRef?.data?.gitHub?.createRef?.ref ||\n    payload.DefaultBranchRef?.data?.gitHub?.repository?.defaultBranchRef;\n\n  const headRefId = headRef.id;\n\n  const commitResult =\n    payload.CreateCommit?.data?.gitHub?.makeRestCall?.post?.jsonBody;\n  const commitSha = commitResult?.sha;\n\n  return {\n    refId: headRefId,\n    sha: commitSha,\n  };\n}\n\nexport function makeVariablesForUserInput(\n  payload: UserInputInput\n): UserInputVariables {\n  return {};\n}\n\nexport function makeVariablesForCheckIfRefExists(\n  payload: CheckIfRefExistsInput\n): CheckIfRefExistsVariables {\n  const branch = String(payload.UserInput?.data?.oneGraph?.branch);\n  return {\n    owner: String(payload.UserInput?.data?.oneGraph?.owner),\n    name: String(payload.UserInput?.data?.oneGraph?.name),\n    fullyQualifiedRefName: !!branch ? `refs/heads/${branch}` : null,\n  };\n}\n",
  scriptDependencies: [
    {
      name: "js-sha1",
      version: "0.6.0",
    },
    {
      name: "text-encoder",
      version: "0.0.4",
    },
  ],
  requests: [
    {
      id: "CreateTree",
      variableDependencies: [
        {
          name: "path",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: [],
              name: "path",
            },
          },
        },
        {
          name: "treeJson",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: [],
              name: "treeJson",
            },
          },
        },
      ],
      operation: {
        id: "7dca56ce-7ea5-44c7-a7e1-c3a185f53e0e",
        title: "CreateTree",
        description: "TODO",
        body:
          'mutation CreateTree($path: String!, $treeJson: JSON!) {\n  gitHub {\n    makeRestCall {\n      post(\n        path: $path\n        jsonBody: $treeJson\n        contentType: "application/json"\n        accept: "application/json"\n      ) {\n        response {\n          statusCode\n        }\n        jsonBody\n      }\n    }\n  }\n}',
        kind: 1,
        services: ["github"],
      },
      dependencyRequestIds: [
        "DefaultBranchRef",
        "CreateRef",
        "FilesOnRef",
        "UserInput",
      ],
    },
    {
      id: "DefaultBranchRef",
      variableDependencies: [
        {
          name: "owner",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "SKIP",
              ifList: "FIRST",
              fromRequestIds: ["UserInput"],
              name: "owner",
            },
          },
        },
        {
          name: "name",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "SKIP",
              ifList: "FIRST",
              fromRequestIds: ["UserInput"],
              name: "name",
            },
          },
        },
      ],
      operation: {
        id: "4bac04c8-f918-4868-9a69-cded5a9a85d8",
        title: "DefaultBranchRef",
        description: "TODO",
        body:
          "query DefaultBranchRef($owner: String!, $name: String!) {\n  gitHub {\n    repository(name: $name, owner: $owner) {\n      id\n      defaultBranchRef {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
        kind: 0,
        services: ["github"],
      },
      dependencyRequestIds: ["UserInput"],
    },
    {
      id: "UserInput",
      variableDependencies: [
        {
          name: "owner",
          dependency: {
            TAG: 1,
            _0: {
              name: "owner",
              value: {
                TAG: 1,
                _0: "owner",
              },
            },
          },
        },
        {
          name: "name",
          dependency: {
            TAG: 1,
            _0: {
              name: "name",
              value: {
                TAG: 1,
                _0: "name",
              },
            },
          },
        },
        {
          name: "branch",
          dependency: {
            TAG: 1,
            _0: {
              name: "branch",
              value: {
                TAG: 1,
                _0: "branch",
              },
            },
          },
        },
        {
          name: "message",
          dependency: {
            TAG: 1,
            _0: {
              name: "message",
              value: {
                TAG: 1,
                _0: "message",
              },
            },
          },
        },
        {
          name: "treeFiles",
          dependency: {
            TAG: 1,
            _0: {
              name: "treeFiles",
              value: {
                TAG: 1,
                _0: "treeFiles",
              },
            },
          },
        },
        {
          name: "acceptOverrides",
          dependency: {
            TAG: 1,
            _0: {
              name: "acceptOverrides",
              value: {
                TAG: 1,
                _0: "acceptOverrides",
              },
            },
          },
        },
      ],
      operation: {
        id: "9ea3b1ac-ebdd-4401-853c-29bb9607a1b8",
        title: "UserInput",
        description: "TODO",
        body:
          "query UserInput($owner: String!, $name: String!, $branch: String!, $message: String!, $treeFiles: JSON!, $acceptOverrides: Boolean!) {\n  oneGraph {\n    owner: identity(input: $owner)\n    name: identity(input: $name)\n    branch: identity(input: $branch)\n    message: identity(input: $message)\n    treeFiles: identity(input: $treeFiles)\n    acceptOverrides: identity(input: $acceptOverrides)\n  }\n}",
        kind: 0,
        services: ["onegraph"],
      },
      dependencyRequestIds: [],
    },
    {
      id: "CreateRef",
      variableDependencies: [
        {
          name: "repositoryId",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: [
                "UserInput",
                "DefaultBranchRef",
                "CheckIfRefExists",
              ],
              name: "repositoryId",
            },
          },
        },
        {
          name: "name",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: [
                "UserInput",
                "DefaultBranchRef",
                "CheckIfRefExists",
              ],
              name: "name",
            },
          },
        },
        {
          name: "oid",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: [
                "UserInput",
                "DefaultBranchRef",
                "CheckIfRefExists",
              ],
              name: "oid",
            },
          },
        },
      ],
      operation: {
        id: "632ff2a2-bc7b-49ea-b1cf-40c8431921e0",
        title: "CreateRef",
        description: "TODO",
        body:
          "mutation CreateRef($repositoryId: ID!, $name: String!, $oid: GitHubGitObjectID!) {\n  gitHub {\n    createRef(input: {repositoryId: $repositoryId, name: $name, oid: $oid}) {\n      ref {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
        kind: 1,
        services: ["github"],
      },
      dependencyRequestIds: [
        "DefaultBranchRef",
        "UserInput",
        "CheckIfRefExists",
      ],
    },
    {
      id: "CheckIfRefExists",
      variableDependencies: [
        {
          name: "owner",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: [],
              name: "owner",
            },
          },
        },
        {
          name: "name",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: [],
              name: "name",
            },
          },
        },
        {
          name: "fullyQualifiedRefName",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "SKIP",
              ifList: "FIRST",
              fromRequestIds: [],
              name: "fullyQualifiedRefName",
            },
          },
        },
      ],
      operation: {
        id: "cf0ba2d5-d880-424a-a156-4b733bd7433d",
        title: "CheckIfRefExists",
        description: "TODO",
        body:
          "query CheckIfRefExists($owner: String!, $name: String!, $fullyQualifiedRefName: String!) {\n  gitHub {\n    repository(name: $name, owner: $owner) {\n      id\n      ref(qualifiedName: $fullyQualifiedRefName) {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
        kind: 0,
        services: ["github"],
      },
      dependencyRequestIds: ["UserInput"],
    },
    {
      id: "FilesOnRef",
      variableDependencies: [
        {
          name: "owner",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: ["CreateRef"],
              name: "owner",
            },
          },
        },
        {
          name: "name",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: ["CreateRef"],
              name: "name",
            },
          },
        },
        {
          name: "fullyQualifiedRefName",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: ["CreateRef"],
              name: "fullyQualifiedRefName",
            },
          },
        },
      ],
      operation: {
        id: "c0e9e88d-f6ac-4872-8687-ac9baa7f2110",
        title: "FilesOnRef",
        description: "TODO",
        body:
          "query FilesOnRef($owner: String!, $name: String!, $fullyQualifiedRefName: String!) {\n  gitHub {\n    repository(name: $name, owner: $owner) {\n      id\n      ref(qualifiedName: $fullyQualifiedRefName) {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
        kind: 0,
        services: ["github"],
      },
      dependencyRequestIds: ["UserInput", "CreateRef"],
    },
    {
      id: "CreateCommit",
      variableDependencies: [
        {
          name: "path",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "SKIP",
              ifList: "FIRST",
              fromRequestIds: ["CheckIfRefExists"],
              name: "path",
            },
          },
        },
        {
          name: "commitJson",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "SKIP",
              ifList: "FIRST",
              fromRequestIds: [
                "UserInput",
                "CreateTree",
                "CreateRef",
                "DefaultBranchRef",
                "CheckIfRefExists",
              ],
              name: "commitJson",
            },
          },
        },
      ],
      operation: {
        id: "6bd45c77-3d51-47ad-91e1-12347f000567",
        title: "CreateCommit",
        description: "TODO",
        body:
          "mutation CreateCommit($path: String!, $commitJson: JSON!) {\n  gitHub {\n    makeRestCall {\n      post(path: $path, jsonBody: $commitJson) {\n        response {\n          statusCode\n        }\n        jsonBody\n      }\n    }\n  }\n}",
        kind: 1,
        services: ["github"],
      },
      dependencyRequestIds: [
        "UserInput",
        "CreateTree",
        "CreateRef",
        "DefaultBranchRef",
        "CheckIfRefExists",
      ],
    },
    {
      id: "UpdateRef",
      variableDependencies: [
        {
          name: "refId",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: ["CheckIfRefExists"],
              name: "refId",
            },
          },
        },
        {
          name: "sha",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "ERROR",
              ifList: "FIRST",
              fromRequestIds: ["CheckIfRefExists"],
              name: "sha",
            },
          },
        },
      ],
      operation: {
        id: "2f4d4266-db84-435b-bdf6-43e33224f4ed",
        title: "UpdateRef",
        description: "TODO",
        body:
          "mutation UpdateRef($refId: ID!, $sha: GitHubGitObjectID!) {\n  gitHub {\n    updateRef(input: {refId: $refId, oid: $sha}) {\n      clientMutationId\n      ref {\n        name\n        id\n        target {\n          oid\n          id\n        }\n      }\n    }\n  }\n}",
        kind: 1,
        services: ["github"],
      },
      dependencyRequestIds: [
        "CreateRef",
        "DefaultBranchRef",
        "CreateCommit",
        "CheckIfRefExists",
      ],
    },
  ],
  blocks: [
    {
      id: "7dca56ce-7ea5-44c7-a7e1-c3a185f53e0e",
      title: "CreateTree",
      description: "TODO",
      body:
        'mutation CreateTree($path: String!, $treeJson: JSON!) {\n  gitHub {\n    makeRestCall {\n      post(\n        path: $path\n        jsonBody: $treeJson\n        contentType: "application/json"\n        accept: "application/json"\n      ) {\n        response {\n          statusCode\n        }\n        jsonBody\n      }\n    }\n  }\n}',
      kind: 1,
      services: ["github"],
    },
    {
      id: "f19222f6-90e8-4650-882b-1de94a6d4a21",
      title: "GitHubRefFragment",
      description: "TODO",
      body:
        "fragment GitHubRefFragment on GitHubRef {\n  id\n  name\n  target {\n    id\n    oid\n    ... on GitHubCommit {\n      history(first: 1) {\n        edges {\n          node {\n            tree {\n              entries {\n                name\n                path\n                oid\n                object {\n                  ... on GitHubTree {\n                    id\n                    entries {\n                      name\n                      path\n                      oid\n                    }\n                  }\n                }\n              }\n            }\n          }\n        }\n      }\n      tree {\n        id\n        oid\n      }\n    }\n  }\n}",
      kind: 3,
      services: ["github"],
    },
    {
      id: "4bac04c8-f918-4868-9a69-cded5a9a85d8",
      title: "DefaultBranchRef",
      description: "TODO",
      body:
        "query DefaultBranchRef($owner: String!, $name: String!) {\n  gitHub {\n    repository(name: $name, owner: $owner) {\n      id\n      defaultBranchRef {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
      kind: 0,
      services: ["github"],
    },
    {
      id: "c0e9e88d-f6ac-4872-8687-ac9baa7f2110",
      title: "FilesOnRef",
      description: "TODO",
      body:
        "query FilesOnRef($owner: String!, $name: String!, $fullyQualifiedRefName: String!) {\n  gitHub {\n    repository(name: $name, owner: $owner) {\n      id\n      ref(qualifiedName: $fullyQualifiedRefName) {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
      kind: 0,
      services: ["github"],
    },
    {
      id: "6bd45c77-3d51-47ad-91e1-12347f000567",
      title: "CreateCommit",
      description: "TODO",
      body:
        "mutation CreateCommit($path: String!, $commitJson: JSON!) {\n  gitHub {\n    makeRestCall {\n      post(path: $path, jsonBody: $commitJson) {\n        response {\n          statusCode\n        }\n        jsonBody\n      }\n    }\n  }\n}",
      kind: 1,
      services: ["github"],
    },
    {
      id: "632ff2a2-bc7b-49ea-b1cf-40c8431921e0",
      title: "CreateRef",
      description: "TODO",
      body:
        "mutation CreateRef($repositoryId: ID!, $name: String!, $oid: GitHubGitObjectID!) {\n  gitHub {\n    createRef(input: {repositoryId: $repositoryId, name: $name, oid: $oid}) {\n      ref {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
      kind: 1,
      services: ["github"],
    },
    {
      id: "2f4d4266-db84-435b-bdf6-43e33224f4ed",
      title: "UpdateRef",
      description: "TODO",
      body:
        "mutation UpdateRef($refId: ID!, $sha: GitHubGitObjectID!) {\n  gitHub {\n    updateRef(input: {refId: $refId, oid: $sha}) {\n      clientMutationId\n      ref {\n        name\n        id\n        target {\n          oid\n          id\n        }\n      }\n    }\n  }\n}",
      kind: 1,
      services: ["github"],
    },
    {
      id: "cf0ba2d5-d880-424a-a156-4b733bd7433d",
      title: "CheckIfRefExists",
      description: "TODO",
      body:
        "query CheckIfRefExists($owner: String!, $name: String!, $fullyQualifiedRefName: String!) {\n  gitHub {\n    repository(name: $name, owner: $owner) {\n      id\n      ref(qualifiedName: $fullyQualifiedRefName) {\n        ...GitHubRefFragment\n      }\n    }\n  }\n}",
      kind: 0,
      services: ["github"],
    },
    {
      id: "9ea3b1ac-ebdd-4401-853c-29bb9607a1b8",
      title: "UserInput",
      description: "TODO",
      body:
        "query UserInput($owner: String!, $name: String!, $branch: String!, $message: String!, $treeFiles: JSON!, $acceptOverrides: Boolean!) {\n  oneGraph {\n    owner: identity(input: $owner)\n    name: identity(input: $name)\n    branch: identity(input: $branch)\n    message: identity(input: $message)\n    treeFiles: identity(input: $treeFiles)\n    acceptOverrides: identity(input: $acceptOverrides)\n  }\n}",
      kind: 0,
      services: ["onegraph"],
    },
  ],
};

export const simpleChain = {
  name: "simple_chain",
  id: "7dca56ce-7ea5-44c7-a7e1-c3a185f53e0b",
  script:
    "import {\n  MyQueryInput,\n  MyQueryVariables,\n  ComputeTypeInput,\n  ComputeTypeVariables,\n} from 'oneGraphStudio';\n\nfunction stringOfFloat(x: GitHubURI): string {\n  return x.toString();\n}\n\nexport function makeVariablesForMyQuery(\n  payload: MyQueryInput\n): MyQueryVariables {\n  return {};\n}\n\nexport function makeVariablesForComputeType(\n  payload: ComputeTypeInput\n): ComputeTypeVariables {\n  let updatedAt =\n    payload?.MyQuery?.data?.gitHub?.user?.gists?.edges[0]?.node?.updatedAt;\n  return {};\n}\n",
  scriptDependencies: [],
  requests: [
    {
      id: "MyQuery",
      variableDependencies: [],
      operation: {
        id: "c45ceb4c-d811-45a6-8ba2-befb9de88a48",
        title: "MyQuery",
        description: "TODO",
        body:
          'query MyQuery {\n  gitHub {\n    user(login: "") {\n      bio\n      bioHTML\n      email\n      id\n      gists(first: 10, orderBy: {field: CREATED_AT, direction: DESC}) {\n        edges {\n          node {\n            createdAt\n            description\n            id\n            ... on GitHubGist {\n              url\n              updatedAt\n            }\n          }\n        }\n      }\n      issues(first: 10, orderBy: {field: CREATED_AT, direction: DESC}) {\n        ...GitHubIssueConnectionFragment\n      }\n    }\n  }\n}',
        kind: 0,
        services: ["github"],
      },
      dependencyRequestIds: [],
    },
    {
      id: "ComputeType",
      variableDependencies: [
        {
          name: "name",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "SKIP",
              ifList: "FIRST",
              fromRequestIds: ["MyQuery"],
              name: "name",
            },
          },
        },
      ],
      operation: {
        id: "0081bf79-a06e-4edb-a4a8-1703c415fa17",
        title: "ComputeType",
        description: "TODO",
        body:
          "query ComputeType($name: String!) {\n  oneGraph {\n    name: identity(input: $name)\n  }\n}",
        kind: 4,
        services: ["onegraph"],
      },
      dependencyRequestIds: ["MyQuery"],
    },
  ],
  blocks: [
    {
      id: "c45ceb4c-d811-45a6-8ba2-befb9de88a48",
      title: "MyQuery",
      description: "TODO",
      body:
        'query MyQuery {\n  gitHub {\n    user(login: "") {\n      bio\n      bioHTML\n      email\n      id\n      gists(first: 10, orderBy: {field: CREATED_AT, direction: DESC}) {\n        edges {\n          node {\n            createdAt\n            description\n            id\n            ... on GitHubGist {\n              url\n              updatedAt\n            }\n          }\n        }\n      }\n      issues(first: 10, orderBy: {field: CREATED_AT, direction: DESC}) {\n        ...GitHubIssueConnectionFragment\n      }\n    }\n  }\n}',
      kind: 0,
      services: ["github"],
    },
    {
      id: "177a4f9f-0600-4366-8022-17551e83602e",
      title: "GitHubIssueConnectionFragment",
      description: "TODO",
      body:
        "fragment GitHubIssueConnectionFragment on GitHubIssueConnection {\n  edges {\n    node {\n      activeLockReason\n      body\n      bodyHTML\n    }\n  }\n}",
      kind: 3,
      services: ["github"],
    },
    {
      id: "0081bf79-a06e-4edb-a4a8-1703c415fa17",
      title: "ComputeType",
      description: "TODO",
      body:
        "query ComputeType($name: String!) {\n  oneGraph {\n    name: identity(input: $name)\n  }\n}",
      kind: 4,
      services: ["onegraph"],
    },
  ],
};

export const spotifyChain = {
  name: "spotifyGetLucky",
  id: "7dca56ce-7ea5-44c7-a7e1-c3a185f53e0c",
  script:
    "import {\n  SearchInput,\n  SearchVariables,\n  ComputeTypeInput,\n  ComputeTypeVariables,\n  SetSlackStatusInput,\n  SetSlackStatusVariables,\n  SpotifyPlayTrackInput,\n  SpotifyPlayTrackVariables,\n} from 'oneGraphStudio';\n\nexport function makeVariablesForSearch(payload: SearchInput): SearchVariables {\n  return {};\n}\n\nexport function makeVariablesForSpotifyPlayTrack(\n  payload: SpotifyPlayTrackInput\n): SpotifyPlayTrackVariables {\n  return {};\n}\n\nexport function makeVariablesForSetSlackStatus(\n  payload: SetSlackStatusInput\n): SetSlackStatusVariables {\n  let name = payload?.ComputeType?.data?.oneGraph?.name;\n  const songName =\n    payload?.SpotifyPlayTrack?.data?.spotify?.playTrack?.player?.item?.name;\n  const albumName =\n    payload?.SpotifyPlayTrack?.data?.spotify?.playTrack?.player?.item?.album\n      ?.name;\n  const message = payload?.ComputeType?.data?.oneGraph?.message;\n\n  const status_text = `Listening to \"${songName}\" on ${albumName}, > ${name} says, \"${message}\"`;\n\n  return {\n    jsonBody: {\n      profile: {\n        status_text: status_text,\n        status_emoji: ':mountain_railway:',\n      },\n    },\n  };\n}\n\nexport function makeVariablesForComputeType(\n  payload: ComputeTypeInput\n): ComputeTypeVariables {\n  return {};\n}\n",
  scriptDependencies: [],
  requests: [
    {
      id: "Search",
      variableDependencies: [
        {
          name: "query",
          dependency: {
            TAG: 1,
            _0: {
              name: "query",
              value: {
                TAG: 1,
                _0: "query",
              },
            },
          },
        },
      ],
      operation: {
        id: "13083522-28ad-49c2-bc94-f35bfac1c956",
        title: "Search",
        description: "TODO",
        body:
          "query Search($query: String!) {\n  spotify {\n    search(data: {query: $query}) {\n      tracks {\n        name\n        id\n        album {\n          name\n          id\n          images {\n            height\n            url\n            width\n          }\n          href\n        }\n        href\n      }\n    }\n  }\n}",
        kind: 0,
        services: ["spotify"],
      },
      dependencyRequestIds: ["ComputeType"],
    },
    {
      id: "ComputeType",
      variableDependencies: [
        {
          name: "message",
          dependency: {
            TAG: 1,
            _0: {
              name: "message",
              value: {
                TAG: 1,
                _0: "message",
              },
            },
          },
        },
        {
          name: "name",
          dependency: {
            TAG: 1,
            _0: {
              name: "name",
              value: {
                TAG: 1,
                _0: "name",
              },
            },
          },
        },
        {
          name: "positionMs",
          dependency: {
            TAG: 1,
            _0: {
              name: "positionMs",
              value: {
                TAG: 1,
                _0: "positionMs",
              },
            },
          },
        },
      ],
      operation: {
        id: "fc9c01c0-e76b-44cc-9460-a954a0a3fef6",
        title: "ComputeType",
        description: "TODO",
        body:
          "query ComputeType($message: String!, $name: String!, $positionMs: Int) {\n  oneGraph {\n    message: identity(input: $message),name: identity(input: $name),positionMs: identity(input: $positionMs)\n  }\n}",
        kind: 4,
        services: ["onegraph"],
      },
      dependencyRequestIds: [],
    },
    {
      id: "SetSlackStatus",
      variableDependencies: [
        {
          name: "jsonBody",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "SKIP",
              ifList: "FIRST",
              fromRequestIds: ["ComputeType"],
              name: "jsonBody",
            },
          },
        },
      ],
      operation: {
        id: "936e0e44-4d8f-43b5-b8d0-ea0e2ccba075",
        title: "SetSlackStatus",
        description: "TODO",
        body:
          'mutation SetSlackStatus($jsonBody: JSON!) {\n  slack {\n    makeRestCall {\n      post(\n        path: "/api/users.profile.set"\n        contentType: "application/json"\n        jsonBody: $jsonBody\n      ) {\n        jsonBody\n      }\n    }\n  }\n}',
        kind: 1,
        services: ["slack"],
      },
      dependencyRequestIds: ["SpotifyPlayTrack", "ComputeType"],
    },
    {
      id: "SpotifyPlayTrack",
      variableDependencies: [
        {
          name: "trackId",
          dependency: {
            TAG: 2,
            _0: {
              name: "trackId",
              ifMissing: "SKIP",
              ifList: "FIRST",
              fromRequestId: "Search",
              path: [
                "payload",
                "Search",
                "data",
                "spotify",
                "search",
                "tracks[0]",
                "id",
              ],
              functionFromScript: "TBD",
            },
          },
        },
        {
          name: "positionMs",
          dependency: {
            TAG: 2,
            _0: {
              name: "positionMs",
              ifMissing: "ALLOW",
              ifList: "FIRST",
              fromRequestId: "ComputeType",
              path: [
                "payload",
                "ComputeType",
                "data",
                "oneGraph",
                "positionMs",
              ],
              functionFromScript: "TBD",
            },
          },
        },
      ],
      operation: {
        id: "31125f56-0c8f-4eda-9500-1378fbe22113",
        title: "SpotifyPlayTrack",
        description: "TODO",
        body:
          'mutation SpotifyPlayTrack($trackId: String = "12PNcnMsjsZ3eHm62t8hiy", $positionMs: Int = 0) {\n  spotify {\n    playTrack(input: {trackIds: [$trackId], positionMs: $positionMs}) {\n      player {\n        isPlaying\n        item {\n          name\n          album {\n            name\n          }\n        }\n      }\n    }\n  }\n}',
        kind: 1,
        services: ["spotify"],
      },
      dependencyRequestIds: ["Search", "ComputeType"],
    },
  ],
  blocks: [
    {
      id: "13083522-28ad-49c2-bc94-f35bfac1c956",
      title: "Search",
      description: "TODO",
      body:
        "query Search($query: String!) {\n  spotify {\n    search(data: {query: $query}) {\n      tracks {\n        name\n        id\n        album {\n          name\n          id\n          images {\n            height\n            url\n            width\n          }\n          href\n        }\n        href\n      }\n    }\n  }\n}",
      kind: 0,
      services: ["spotify"],
    },
    {
      id: "936e0e44-4d8f-43b5-b8d0-ea0e2ccba075",
      title: "SetSlackStatus",
      description: "TODO",
      body:
        'mutation SetSlackStatus($jsonBody: JSON!) {\n  slack {\n    makeRestCall {\n      post(\n        path: "/api/users.profile.set"\n        contentType: "application/json"\n        jsonBody: $jsonBody\n      ) {\n        jsonBody\n      }\n    }\n  }\n}',
      kind: 1,
      services: ["slack"],
    },
    {
      id: "fc9c01c0-e76b-44cc-9460-a954a0a3fef6",
      title: "ComputeType",
      description: "TODO",
      body:
        "query ComputeType($message: String!, $name: String!, $positionMs: Int) {\n  oneGraph {\n    message: identity(input: $message),name: identity(input: $name),positionMs: identity(input: $positionMs)\n  }\n}",
      kind: 4,
      services: ["onegraph"],
    },
    {
      id: "31125f56-0c8f-4eda-9500-1378fbe22113",
      title: "SpotifyPlayTrack",
      description: "TODO",
      body:
        'mutation SpotifyPlayTrack($trackId: String = "12PNcnMsjsZ3eHm62t8hiy", $positionMs: Int = 0) {\n  spotify {\n    playTrack(input: {trackIds: [$trackId], positionMs: $positionMs}) {\n      player {\n        isPlaying\n        item {\n          name\n          album {\n            name\n          }\n        }\n      }\n    }\n  }\n}',
      kind: 1,
      services: ["spotify"],
    },
  ],
};

export const descuriChain = {
  name: "siteMonitoringChain",
  id: "7dca56ce-7ea5-44c7-a7e1-c3a185f53e0d",
  script:
    "import {\n  CheckSiteLinksInput,\n  CheckSiteLinksVariables,\n  ComputeTypeInput,\n  ComputeTypeVariables,\n} from 'oneGraphStudio';\n\nexport function makeVariablesForCheckSiteLinks(\n  payload: CheckSiteLinksInput\n): CheckSiteLinksVariables {\n  return {};\n}\n\nexport function makeVariablesForComputeType(\n  payload: ComputeTypeInput\n): ComputeTypeVariables {\n  let uris = payload?.CheckSiteLinks?.data?.descuri?.other[0];\n  let hasEventilLink = uris?.some((node) => node.uri === 'hi');\n\n  const message = hasEventilLink ? null : 'Uhoh!';\n  return { message };\n}\n",
  scriptDependencies: [],
  requests: [
    {
      id: "CheckSiteLinks",
      variableDependencies: [
        {
          name: "url",
          dependency: {
            TAG: 1,
            _0: {
              name: "url",
              value: {
                TAG: 1,
                _0: "url",
              },
            },
          },
        },
      ],
      operation: {
        id: "afce7ecb-50c3-43d7-99c9-821e7e832079",
        title: "CheckSiteLinks",
        description: "TODO",
        body:
          'query CheckSiteLinks($url: String = "") {\n  descuri(url: $url) {\n    other(first: 100) {\n      uri\n    }\n  }\n}',
        kind: 0,
        services: [],
      },
      dependencyRequestIds: [],
    },
    {
      id: "ComputeType",
      variableDependencies: [
        {
          name: "message",
          dependency: {
            TAG: 0,
            _0: {
              functionFromScript: "INITIAL_UNKNOWN",
              ifMissing: "SKIP",
              ifList: "FIRST",
              fromRequestIds: [],
              name: "message",
            },
          },
        },
      ],
      operation: {
        id: "674578e6-ab2d-4eb5-ab40-2463ea1afade",
        title: "ComputeType",
        description: "TODO",
        body:
          "query ComputeType($message: String!) {\n  oneGraph {\n    message: identity(input: $message)\n  }\n}",
        kind: 4,
        services: ["onegraph"],
      },
      dependencyRequestIds: ["CheckSiteLinks"],
    },
  ],
  blocks: [
    {
      id: "afce7ecb-50c3-43d7-99c9-821e7e832079",
      title: "CheckSiteLinks",
      description: "TODO",
      body:
        'query CheckSiteLinks($url: String = "") {\n  descuri(url: $url) {\n    other(first: 100) {\n      uri\n    }\n  }\n}',
      kind: 0,
      services: [],
    },
    {
      id: "674578e6-ab2d-4eb5-ab40-2463ea1afade",
      title: "ComputeType",
      description: "TODO",
      body:
        "query ComputeType($message: String!) {\n  oneGraph {\n    message: identity(input: $message)\n  }\n}",
      kind: 4,
      services: ["onegraph"],
    },
  ],
};

export let spotifyChainTrace0 = {
  chainId: "7dca56ce-7ea5-44c7-a7e1-c3a185f53e0c",
  createdAt: "2021-03-28T20:51:45.054Z",
  trace: {
    id: "7dca56ce-7ea5-44c7-a7e1-c3a185f53e11",
    data: {
      oneGraph: {
        executeChain: {
          results: [
            {
              request: {
                id: "Search",
              },
              result: [
                {
                  data: {
                    spotify: {
                      search: {
                        tracks: [
                          {
                            name: "Calling My Phone",
                            id: "5Kskr9LcNYa0tpt5f0ZEJx",
                            album: {
                              name: "Calling My Phone",
                              id: "1QhKOq11hGEoNA42rV2IHp",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b2731b36f91abf80aedb7c88f460",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e021b36f91abf80aedb7c88f460",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d000048511b36f91abf80aedb7c88f460",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/1QhKOq11hGEoNA42rV2IHp",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/5Kskr9LcNYa0tpt5f0ZEJx",
                          },
                          {
                            name: "Calling My Phone",
                            id: "0irplcCrIYLzpPn2B9CjKw",
                            album: {
                              name: "Calling My Phone",
                              id: "489jwFiGVqmcZqc5hH52pa",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b2735e134a0f3143b3df8e6b4f72",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e025e134a0f3143b3df8e6b4f72",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d000048515e134a0f3143b3df8e6b4f72",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/489jwFiGVqmcZqc5hH52pa",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/0irplcCrIYLzpPn2B9CjKw",
                          },
                          {
                            name: "POPSTAR (feat. Drake)",
                            id: "6EDO9iiTtwNv6waLwa1UUq",
                            album: {
                              name: "POPSTAR (feat. Drake)",
                              id: "5nNtpPsSUgb9Hlb3dF1gXa",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273efaecb4b9cbae7c120d14617",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02efaecb4b9cbae7c120d14617",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851efaecb4b9cbae7c120d14617",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/5nNtpPsSUgb9Hlb3dF1gXa",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/6EDO9iiTtwNv6waLwa1UUq",
                          },
                          {
                            name: "Calling My Phone",
                            id: "1CG8FcfigkTS4xVpIuNDOZ",
                            album: {
                              name: "Calling My Phone",
                              id: "3g6uxrpVfHQpCYOEkahUyk",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b27397d16bd7fa3e07c15f06ba09",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e0297d16bd7fa3e07c15f06ba09",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000485197d16bd7fa3e07c15f06ba09",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/3g6uxrpVfHQpCYOEkahUyk",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/1CG8FcfigkTS4xVpIuNDOZ",
                          },
                          {
                            name: "Hurt Me",
                            id: "3XRQT7EoS4U87rUuJwg5P3",
                            album: {
                              name: "Goodbye & Good Riddance",
                              id: "6tkjU4Umpo79wwkgPMV3nZ",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273f7db43292a6a99b21b51d5b4",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02f7db43292a6a99b21b51d5b4",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851f7db43292a6a99b21b51d5b4",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/6tkjU4Umpo79wwkgPMV3nZ",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/3XRQT7EoS4U87rUuJwg5P3",
                          },
                          {
                            name: "Calling My Phone",
                            id: "0LyFks8nymyx5uJz8Ldcab",
                            album: {
                              name: "TMBG4L",
                              id: "1gAwMB28nNss6LP22ZyUj1",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b2734efab5baae06dcb5f6645e27",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e024efab5baae06dcb5f6645e27",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d000048514efab5baae06dcb5f6645e27",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/1gAwMB28nNss6LP22ZyUj1",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/0LyFks8nymyx5uJz8Ldcab",
                          },
                          {
                            name: "Calling My Phone",
                            id: "7ttccyDY7hfzvzPXmA7E8t",
                            album: {
                              name: "Headshot",
                              id: "74nxdn9ypqp3hqJEttpDNU",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273c3c0cf41da2bb35e19acc875",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02c3c0cf41da2bb35e19acc875",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851c3c0cf41da2bb35e19acc875",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/74nxdn9ypqp3hqJEttpDNU",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/7ttccyDY7hfzvzPXmA7E8t",
                          },
                          {
                            name: "Calling My Phone",
                            id: "40nmy5pHfCyoMlFiqa0ImR",
                            album: {
                              name: "Calling My Phone",
                              id: "1yciTZmMMVHJwlqCK1asHI",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273833e8182c9dceca999ad223b",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02833e8182c9dceca999ad223b",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851833e8182c9dceca999ad223b",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/1yciTZmMMVHJwlqCK1asHI",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/40nmy5pHfCyoMlFiqa0ImR",
                          },
                          {
                            name: "1-800-273-8255",
                            id: "5tz69p7tJuGPeMGwNTxYuV",
                            album: {
                              name: "Everybody",
                              id: "1HiN2YXZcc3EjmVZ4WjfBk",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273cfdf40cf325b609a52457805",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02cfdf40cf325b609a52457805",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851cfdf40cf325b609a52457805",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/1HiN2YXZcc3EjmVZ4WjfBk",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/5tz69p7tJuGPeMGwNTxYuV",
                          },
                          {
                            name: "Calling My Phone - Instrumental",
                            id: "1AsLQgAemuaRYAWKzp07K7",
                            album: {
                              name: "Calling My Phone (Instrumental)",
                              id: "2a41YkxO5XqCz7UuycJxr1",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b2731b98dcc57736f585afe525ea",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e021b98dcc57736f585afe525ea",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d000048511b98dcc57736f585afe525ea",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/2a41YkxO5XqCz7UuycJxr1",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/1AsLQgAemuaRYAWKzp07K7",
                          },
                          {
                            name: "ghost boy",
                            id: "4Am4agzcSdFnKLSEB56ODY",
                            album: {
                              name: "EVERYBODY'S EVERYTHING",
                              id: "1r1Xt6oUnY3VMYbQb1U7CO",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273c73bd9b0e34b067d7d3bd7b9",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02c73bd9b0e34b067d7d3bd7b9",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851c73bd9b0e34b067d7d3bd7b9",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/1r1Xt6oUnY3VMYbQb1U7CO",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/4Am4agzcSdFnKLSEB56ODY",
                          },
                          {
                            name: "Calling My Phone (lofi version)",
                            id: "319uz5mk3s6GmqErQoeHXb",
                            album: {
                              name: "Calling My Phone (lofi version)",
                              id: "5BUhnXW1vmVbH0Mn81WCJL",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b27373eb20baa5563cf0f92c554e",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e0273eb20baa5563cf0f92c554e",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000485173eb20baa5563cf0f92c554e",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/5BUhnXW1vmVbH0Mn81WCJL",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/319uz5mk3s6GmqErQoeHXb",
                          },
                          {
                            name: "Let Her Go",
                            id: "0c6SqvH32BMgbEFvpHc2gs",
                            album: {
                              name: "Let Her Go",
                              id: "2PMhID6CzdaI8t4dlPSodY",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273b42765a5921d09cad8bac5e2",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02b42765a5921d09cad8bac5e2",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851b42765a5921d09cad8bac5e2",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/2PMhID6CzdaI8t4dlPSodY",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/0c6SqvH32BMgbEFvpHc2gs",
                          },
                          {
                            name: "Calling My Phone - Instrumental",
                            id: "44ZnnYBMGtxyZLo4ioGFSJ",
                            album: {
                              name: "Calling My Phone (Instrumental)",
                              id: "3DijJ3lKR1MMEXyM16RpYh",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273a3aeb6759ed9a7c36c656a1e",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02a3aeb6759ed9a7c36c656a1e",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851a3aeb6759ed9a7c36c656a1e",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/3DijJ3lKR1MMEXyM16RpYh",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/44ZnnYBMGtxyZLo4ioGFSJ",
                          },
                          {
                            name: "Tia Tamera (feat. Rico Nasty)",
                            id: "1uNePI826aqh9uC9pgbeHU",
                            album: {
                              name: "Amala (Deluxe Version)",
                              id: "3wOMqxNHgkga91RBC7BaZU",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b27305d15f02b484a462368cce63",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e0205d15f02b484a462368cce63",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000485105d15f02b484a462368cce63",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/3wOMqxNHgkga91RBC7BaZU",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/1uNePI826aqh9uC9pgbeHU",
                          },
                          {
                            name: "Calling My Phone",
                            id: "0ab6RSPJSTE14pGvwKRYti",
                            album: {
                              name: "Calling My Phone",
                              id: "6qfGfoOI66NJPFh43009L8",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b27372b38f949fc185ce545c64de",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e0272b38f949fc185ce545c64de",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000485172b38f949fc185ce545c64de",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/6qfGfoOI66NJPFh43009L8",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/0ab6RSPJSTE14pGvwKRYti",
                          },
                          {
                            name: "Let It Go",
                            id: "2RqZFOLOnzVmHUX7ZMcaES",
                            album: {
                              name: "Just Like You",
                              id: "7mdy09EO4q6F9VWBtXDDjK",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273911ef35f75422d0482cec8bf",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02911ef35f75422d0482cec8bf",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851911ef35f75422d0482cec8bf",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/7mdy09EO4q6F9VWBtXDDjK",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/2RqZFOLOnzVmHUX7ZMcaES",
                          },
                          {
                            name: "Stop Calling My Phone",
                            id: "6mspqbQTCjhAxGCZIa0i64",
                            album: {
                              name: "Love is War",
                              id: "2lAMEqY57VoWCHZxMK7M47",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273396085625a614b67235e12bf",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02396085625a614b67235e12bf",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851396085625a614b67235e12bf",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/2lAMEqY57VoWCHZxMK7M47",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/6mspqbQTCjhAxGCZIa0i64",
                          },
                          {
                            name: "The Race",
                            id: "45lzMXVHXToapMnGyKMCyB",
                            album: {
                              name:
                                "Rolling Papers (Deluxe 10 Year Anniversary Edition)",
                              id: "22rKa9MG4cHIRxvL1Vbs0q",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273117ad8c714eeb4cf950101d5",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02117ad8c714eeb4cf950101d5",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851117ad8c714eeb4cf950101d5",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/22rKa9MG4cHIRxvL1Vbs0q",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/45lzMXVHXToapMnGyKMCyB",
                          },
                          {
                            name: "Calling My Phone",
                            id: "5QRBK8PcwFS2cDPyKiWNr7",
                            album: {
                              name: "Calling My Phone",
                              id: "7h5rQItycT454ovVre4CSb",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b27395ebae1e7d26bcb18859c9f1",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e0295ebae1e7d26bcb18859c9f1",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000485195ebae1e7d26bcb18859c9f1",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/7h5rQItycT454ovVre4CSb",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/5QRBK8PcwFS2cDPyKiWNr7",
                          },
                          {
                            name: "Beat It (feat. Chris Brown & Wiz Khalifa)",
                            id: "3bwCMbwDZVtvJDnUTQIdCX",
                            album: {
                              name: "Back 2 Life",
                              id: "1fOIkbQO1zU1rO3GLIGJBH",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b273d62e2e5e48912cac698d7eeb",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e02d62e2e5e48912cac698d7eeb",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00004851d62e2e5e48912cac698d7eeb",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/1fOIkbQO1zU1rO3GLIGJBH",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/3bwCMbwDZVtvJDnUTQIdCX",
                          },
                          {
                            name: "Calling My Phone",
                            id: "13jDUXklCu8AYWzufW7LMq",
                            album: {
                              name: "Jawn to the Head Yo",
                              id: "5sKLuk1cTLgH9lrt148OBd",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b2737bc2872cd6ef45fa2dfc513c",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e027bc2872cd6ef45fa2dfc513c",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d000048517bc2872cd6ef45fa2dfc513c",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/5sKLuk1cTLgH9lrt148OBd",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/13jDUXklCu8AYWzufW7LMq",
                          },
                          {
                            name: "Calling My Phone",
                            id: "08QAkBRyWLUQ3UniIyMFtP",
                            album: {
                              name: "Calling My Phone",
                              id: "0Fa2FLw7jMeao6UzKE1VoN",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b2735fead3083c55648b09d68807",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e025fead3083c55648b09d68807",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d000048515fead3083c55648b09d68807",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/0Fa2FLw7jMeao6UzKE1VoN",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/08QAkBRyWLUQ3UniIyMFtP",
                          },
                          {
                            name: "Calling My Phone (Remix)",
                            id: "528R4JR48GJPxsSd8njyAX",
                            album: {
                              name: "Calling My Phone (Remix)",
                              id: "51XgyVk75JHDtWGSzjK9Cu",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b2737419a4b391142e385fca603d",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e027419a4b391142e385fca603d",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d000048517419a4b391142e385fca603d",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/51XgyVk75JHDtWGSzjK9Cu",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/528R4JR48GJPxsSd8njyAX",
                          },
                          {
                            name: "Only The Team (with Lil Mosey & Lil Tjay)",
                            id: "6UHfW9PmGAUjIVeIkPzPQ2",
                            album: {
                              name: "Only The Team (with Lil Mosey & Lil Tjay)",
                              id: "7oEKNLjZtm5UEIezuR2Hfy",
                              images: [
                                {
                                  height: 640,
                                  url:
                                    "https://i.scdn.co/image/ab67616d0000b2731b382fb4a70157f7b47af1ed",
                                  width: 640,
                                },
                                {
                                  height: 300,
                                  url:
                                    "https://i.scdn.co/image/ab67616d00001e021b382fb4a70157f7b47af1ed",
                                  width: 300,
                                },
                                {
                                  height: 64,
                                  url:
                                    "https://i.scdn.co/image/ab67616d000048511b382fb4a70157f7b47af1ed",
                                  width: 64,
                                },
                              ],
                              href:
                                "https://api.spotify.com/v1/albums/7oEKNLjZtm5UEIezuR2Hfy",
                            },
                            href:
                              "https://api.spotify.com/v1/tracks/6UHfW9PmGAUjIVeIkPzPQ2",
                          },
                        ],
                      },
                    },
                  },
                },
              ],
              argumentDependencies: [],
            },
            {
              request: {
                id: "ComputeType",
              },
              result: [
                {
                  data: {
                    oneGraph: {
                      message: "Enjoy the song!",
                      name: "Sean",
                      positionMs: 0,
                    },
                  },
                },
              ],
              argumentDependencies: [],
            },
            {
              request: {
                id: "SetSlackStatus",
              },
              result: [
                {
                  data: {
                    slack: {
                      makeRestCall: {
                        post: {
                          jsonBody: {
                            ok: true,
                            profile: {
                              title: "",
                              phone: "",
                              skype: "",
                              real_name: "Sean Grove",
                              real_name_normalized: "Sean Grove",
                              display_name: "sgrove",
                              display_name_normalized: "sgrove",
                              fields: [],
                              status_text:
                                'Listening to "Calling My Phone" on Calling My Phone, &gt; Sean says, "Enjoy the song!"',
                              status_emoji: ":mountain_railway:",
                              status_expiration: 0,
                              avatar_hash: "3449f5b8b1c0",
                              image_original:
                                "https://avatars.slack-edge.com/2018-01-02/292766579264_3449f5b8b1c069b97d27_original.jpg",
                              is_custom_image: true,
                              email: "sean@bushi.do",
                              first_name: "Sean",
                              last_name: "Grove",
                              image_24:
                                "https://avatars.slack-edge.com/2018-01-02/292766579264_3449f5b8b1c069b97d27_24.jpg",
                              image_32:
                                "https://avatars.slack-edge.com/2018-01-02/292766579264_3449f5b8b1c069b97d27_32.jpg",
                              image_48:
                                "https://avatars.slack-edge.com/2018-01-02/292766579264_3449f5b8b1c069b97d27_48.jpg",
                              image_72:
                                "https://avatars.slack-edge.com/2018-01-02/292766579264_3449f5b8b1c069b97d27_72.jpg",
                              image_192:
                                "https://avatars.slack-edge.com/2018-01-02/292766579264_3449f5b8b1c069b97d27_192.jpg",
                              image_512:
                                "https://avatars.slack-edge.com/2018-01-02/292766579264_3449f5b8b1c069b97d27_512.jpg",
                              image_1024:
                                "https://avatars.slack-edge.com/2018-01-02/292766579264_3449f5b8b1c069b97d27_1024.jpg",
                              status_text_canonical: "",
                            },
                            username: "sean",
                            warning: "missing_charset",
                            response_metadata: {
                              warnings: ["missing_charset"],
                            },
                          },
                        },
                      },
                    },
                  },
                },
              ],
              argumentDependencies: [
                {
                  name: "jsonBody",
                  returnValues: [
                    {
                      profile: {
                        status_text:
                          'Listening to "Calling My Phone" on Calling My Phone, > Sean says, "Enjoy the song!"',
                        status_emoji: ":mountain_railway:",
                      },
                    },
                  ],
                  logs: [],
                  error: null,
                },
              ],
            },
            {
              request: {
                id: "SpotifyPlayTrack",
              },
              result: [
                {
                  data: {
                    spotify: {
                      playTrack: {
                        player: {
                          isPlaying: true,
                          item: {
                            name: "Calling My Phone",
                            album: {
                              name: "Calling My Phone",
                            },
                          },
                        },
                      },
                    },
                  },
                },
              ],
              argumentDependencies: [
                {
                  name: "positionMs",
                  returnValues: [0],
                  logs: [],
                  error: null,
                },
                {
                  name: "trackId",
                  returnValues: ["5Kskr9LcNYa0tpt5f0ZEJx"],
                  logs: [],
                  error: null,
                },
              ],
            },
          ],
        },
      },
    },
    extensions: {
      metrics: {
        api: {
          avoidedRequestCount: 0,
          requestCount: 4,
          totalRequestMs: 1227,
          byHost: {
            "api.spotify.com": {
              requestCount: 3,
              totalRequestMs: 900,
            },
            "slack.com": {
              requestCount: 1,
              totalRequestMs: 327,
            },
          },
        },
      },
      apiRequests: [
        {
          uri: "https://slack.com/api/users.profile.set",
          host: "slack.com",
          method: "POST",
          port: 443,
          path: "/api/users.profile.set",
          requestHeaders: {
            accept: "application/json",
            "content-length": "153",
            "content-type": "application/json",
            host: "slack.com",
            "user-agent": "ocaml-cohttp/2.5.4",
          },
          queryParams: {},
          requestBody:
            '{"profile":{"status_text":"Listening to \\"Calling My Phone\\" on Calling My Phone, > Sean says, \\"Enjoy the song!\\"","status_emoji":":mountain_railway:"}}',
          responseBody:
            '{"ok":true,"profile":{"title":"","phone":"","skype":"","real_name":"Sean Grove","real_name_normalized":"Sean Grove","display_name":"sgrove","display_name_normalized":"sgrove","fields":[],"status_text":"Listening to \\"Calling My Phone\\" on Calling My Phone, &gt; Sean says, \\"Enjoy the song!\\"","status_emoji":":mountain_railway:","status_expiration":0,"avatar_hash":"3449f5b8b1c0","image_original":"https:\\/\\/avatars.slack-edge.com\\/2018-01-02\\/292766579264_3449f5b8b1c069b97d27_original.jpg","is_custom_image":true,"email":"sean@bushi.do","first_name":"Sean","last_name":"Grove","image_24":"https:\\/\\/avatars.slack-edge.com\\/2018-01-02\\/292766579264_3449f5b8b1c069b97d27_24.jpg","image_32":"https:\\/\\/avatars.slack-edge.com\\/2018-01-02\\/292766579264_3449f5b8b1c069b97d27_32.jpg","image_48":"https:\\/\\/avatars.slack-edge.com\\/2018-01-02\\/292766579264_3449f5b8b1c069b97d27_48.jpg","image_72":"https:\\/\\/avatars.slack-edge.com\\/2018-01-02\\/292766579264_3449f5b8b1c069b97d27_72.jpg","image_192":"https:\\/\\/avatars.slack-edge.com\\/2018-01-02\\/292766579264_3449f5b8b1c069b97d27_192.jpg","image_512":"https:\\/\\/avatars.slack-edge.com\\/2018-01-02\\/292766579264_3449f5b8b1c069b97d27_512.jpg","image_1024":"https:\\/\\/avatars.slack-edge.com\\/2018-01-02\\/292766579264_3449f5b8b1c069b97d27_1024.jpg","status_text_canonical":""},"username":"sean","warning":"missing_charset","response_metadata":{"warnings":["missing_charset"]}}',
          responseHeaders: {
            "access-control-allow-headers":
              "slack-route, x-slack-version-ts, x-b3-traceid, x-b3-spanid, x-b3-parentspanid, x-b3-sampled, x-b3-flags",
            "access-control-allow-origin": "*",
            "access-control-expose-headers": "x-slack-req-id, retry-after",
            "cache-control": "private, no-cache, no-store, must-revalidate",
            "content-encoding": "gzip",
            "content-length": "478",
            "content-type": "application/json; charset=utf-8",
            date: "Sun, 28 Mar 2021 18:17:25 GMT",
            expires: "Mon, 26 Jul 1997 05:00:00 GMT",
            pragma: "no-cache",
            "referrer-policy": "no-referrer",
            server: "Apache",
            "strict-transport-security":
              "max-age=31536000; includeSubDomains; preload",
            vary: "Accept-Encoding",
            via: "envoy-www-iad-lpdk",
            "x-accepted-oauth-scopes": "users.profile:write",
            "x-backend":
              "main_normal main_bedrock_normal_with_overflow main_canary_with_overflow main_bedrock_canary_with_overflow main_control_with_overflow main_bedrock_control_with_overflow",
            "x-content-type-options": "nosniff",
            "x-envoy-upstream-service-time": "198",
            "x-oauth-scopes": "identify,chat:write:user,users.profile:write",
            "x-server": "slack-www-hhvm-main-iad-w2nu",
            "x-slack-backend": "r",
            "x-slack-req-id": "f49c74cd1d66b2b4d3567e5ce3f5092a",
            "x-slack-shared-secret-outcome": "shared-secret",
            "x-via": "envoy-www-iad-lpdk, haproxy-edge-pdx-zjvm",
            "x-xss-protection": "0",
          },
          status: 200,
          requestMs: 327.4350166320801,
        },
        {
          uri: "https://api.spotify.com/v1/me/player",
          host: "api.spotify.com",
          method: "GET",
          port: 443,
          path: "/v1/me/player",
          requestHeaders: {
            accept: "application/json",
            host: "api.spotify.com",
            "user-agent": "OneGraph (https://www.onegraph.com)",
          },
          queryParams: {},
          requestBody: null,
          responseBody:
            '{\n  "device" : {\n    "id" : "35e412daf16e852c05409dc0ee63f1d82774381d",\n    "is_active" : true,\n    "is_private_session" : false,\n    "is_restricted" : false,\n    "name" : "Sean’s MacBook Pro",\n    "type" : "Computer",\n    "volume_percent" : 100\n  },\n  "shuffle_state" : false,\n  "repeat_state" : "off",\n  "timestamp" : 1616955443309,\n  "context" : null,\n  "progress_ms" : 1681,\n  "item" : {\n    "album" : {\n      "album_type" : "single",\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/6jGMq4yGs7aQzuGsMgVgZR"\n        },\n        "href" : "https://api.spotify.com/v1/artists/6jGMq4yGs7aQzuGsMgVgZR",\n        "id" : "6jGMq4yGs7aQzuGsMgVgZR",\n        "name" : "Lil Tjay",\n        "type" : "artist",\n        "uri" : "spotify:artist:6jGMq4yGs7aQzuGsMgVgZR"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/4IVAbR2w4JJNJDDRFP3E83"\n        },\n        "href" : "https://api.spotify.com/v1/artists/4IVAbR2w4JJNJDDRFP3E83",\n        "id" : "4IVAbR2w4JJNJDDRFP3E83",\n        "name" : "6LACK",\n        "type" : "artist",\n        "uri" : "spotify:artist:4IVAbR2w4JJNJDDRFP3E83"\n      } ],\n      "available_markets" : [ "AD", "AE", "AL", "AR", "AT", "AU", "BA", "BE", "BG", "BH", "BO", "BR", "BY", "CA", "CH", "CL", "CO", "CR", "CY", "CZ", "DE", "DK", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FR", "GB", "GR", "GT", "HK", "HN", "HR", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JO", "JP", "KW", "KZ", "LB", "LI", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MK", "MT", "MX", "MY", "NI", "NL", "NO", "NZ", "OM", "PA", "PE", "PH", "PL", "PS", "PT", "PY", "QA", "RO", "RS", "RU", "SA", "SE", "SG", "SI", "SK", "SV", "TH", "TN", "TR", "TW", "UA", "US", "UY", "VN", "XK", "ZA" ],\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/album/1QhKOq11hGEoNA42rV2IHp"\n      },\n      "href" : "https://api.spotify.com/v1/albums/1QhKOq11hGEoNA42rV2IHp",\n      "id" : "1QhKOq11hGEoNA42rV2IHp",\n      "images" : [ {\n        "height" : 640,\n        "url" : "https://i.scdn.co/image/ab67616d0000b2731b36f91abf80aedb7c88f460",\n        "width" : 640\n      }, {\n        "height" : 300,\n        "url" : "https://i.scdn.co/image/ab67616d00001e021b36f91abf80aedb7c88f460",\n        "width" : 300\n      }, {\n        "height" : 64,\n        "url" : "https://i.scdn.co/image/ab67616d000048511b36f91abf80aedb7c88f460",\n        "width" : 64\n      } ],\n      "name" : "Calling My Phone",\n      "release_date" : "2021-02-12",\n      "release_date_precision" : "day",\n      "total_tracks" : 1,\n      "type" : "album",\n      "uri" : "spotify:album:1QhKOq11hGEoNA42rV2IHp"\n    },\n    "artists" : [ {\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/artist/6jGMq4yGs7aQzuGsMgVgZR"\n      },\n      "href" : "https://api.spotify.com/v1/artists/6jGMq4yGs7aQzuGsMgVgZR",\n      "id" : "6jGMq4yGs7aQzuGsMgVgZR",\n      "name" : "Lil Tjay",\n      "type" : "artist",\n      "uri" : "spotify:artist:6jGMq4yGs7aQzuGsMgVgZR"\n    }, {\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/artist/4IVAbR2w4JJNJDDRFP3E83"\n      },\n      "href" : "https://api.spotify.com/v1/artists/4IVAbR2w4JJNJDDRFP3E83",\n      "id" : "4IVAbR2w4JJNJDDRFP3E83",\n      "name" : "6LACK",\n      "type" : "artist",\n      "uri" : "spotify:artist:4IVAbR2w4JJNJDDRFP3E83"\n    } ],\n    "available_markets" : [ "AD", "AE", "AL", "AR", "AT", "AU", "BA", "BE", "BG", "BH", "BO", "BR", "BY", "CA", "CH", "CL", "CO", "CR", "CY", "CZ", "DE", "DK", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FR", "GB", "GR", "GT", "HK", "HN", "HR", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JO", "JP", "KW", "KZ", "LB", "LI", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MK", "MT", "MX", "MY", "NI", "NL", "NO", "NZ", "OM", "PA", "PE", "PH", "PL", "PS", "PT", "PY", "QA", "RO", "RS", "RU", "SA", "SE", "SG", "SI", "SK", "SV", "TH", "TN", "TR", "TW", "UA", "US", "UY", "VN", "XK", "ZA" ],\n    "disc_number" : 1,\n    "duration_ms" : 205458,\n    "explicit" : true,\n    "external_ids" : {\n      "isrc" : "USSM12100388"\n    },\n    "external_urls" : {\n      "spotify" : "https://open.spotify.com/track/5Kskr9LcNYa0tpt5f0ZEJx"\n    },\n    "href" : "https://api.spotify.com/v1/tracks/5Kskr9LcNYa0tpt5f0ZEJx",\n    "id" : "5Kskr9LcNYa0tpt5f0ZEJx",\n    "is_local" : false,\n    "name" : "Calling My Phone",\n    "popularity" : 95,\n    "preview_url" : "https://p.scdn.co/mp3-preview/557aa1208c5f9acb079cb23e71abb58431056ad0?cid=e348b05a9d5b404084480a58c25dd36e",\n    "track_number" : 1,\n    "type" : "track",\n    "uri" : "spotify:track:5Kskr9LcNYa0tpt5f0ZEJx"\n  },\n  "currently_playing_type" : "track",\n  "actions" : {\n    "disallows" : {\n      "resuming" : true,\n      "skipping_prev" : true\n    }\n  },\n  "is_playing" : true\n}',
          responseHeaders: {
            "access-control-allow-credentials": "true",
            "access-control-allow-headers":
              "Accept, App-Platform, Authorization, Content-Type, Origin, Retry-After, Spotify-App-Version, X-Cloud-Trace-Context, client-token, content-access-token",
            "access-control-allow-methods":
              "GET, POST, OPTIONS, PUT, DELETE, PATCH",
            "access-control-allow-origin": "*",
            "access-control-max-age": "604800",
            "alt-svc": "clear",
            "cache-control": "private, max-age=0",
            "content-encoding": "gzip",
            "content-length": "1313",
            "content-type": "application/json; charset=utf-8",
            date: "Sun, 28 Mar 2021 18:17:24 GMT",
            server: "envoy",
            "strict-transport-security": "max-age=31536000",
            via: "HTTP/2 edgeproxy, 1.1 google",
            "x-content-type-options": "nosniff",
            "x-robots-tag": "noindex, nofollow",
          },
          status: 200,
          requestMs: 62.68620491027832,
        },
        {
          uri: "https://api.spotify.com/v1/me/player/play",
          host: "api.spotify.com",
          method: "PUT",
          port: 443,
          path: "/v1/me/player/play",
          requestHeaders: {
            accept: "application/json",
            "content-type": "application/json",
            host: "api.spotify.com",
            "user-agent": "OneGraph (https://www.onegraph.com)",
          },
          queryParams: {},
          requestBody:
            '{"position_ms":0,"uris":["spotify:track:5Kskr9LcNYa0tpt5f0ZEJx"]}',
          responseBody: "",
          responseHeaders: {
            "access-control-allow-credentials": "true",
            "access-control-allow-headers":
              "Accept, App-Platform, Authorization, Content-Type, Origin, Retry-After, Spotify-App-Version, X-Cloud-Trace-Context, client-token, content-access-token",
            "access-control-allow-methods":
              "GET, POST, OPTIONS, PUT, DELETE, PATCH",
            "access-control-allow-origin": "*",
            "access-control-max-age": "604800",
            "alt-svc": "clear",
            "cache-control": "private, max-age=0",
            date: "Sun, 28 Mar 2021 18:17:23 GMT",
            server: "envoy",
            "strict-transport-security": "max-age=31536000",
            via: "HTTP/2 edgeproxy, 1.1 google",
            "x-content-type-options": "nosniff",
            "x-robots-tag": "noindex, nofollow",
          },
          status: 204,
          requestMs: 641.0109996795654,
        },
        {
          uri:
            "https://api.spotify.com/v1/search?limit=25&offset=0&q=calling%20my%20phone&type=track",
          host: "api.spotify.com",
          method: "GET",
          port: 443,
          path: "/v1/search",
          requestHeaders: {
            accept: "application/json",
            host: "api.spotify.com",
            "user-agent": "OneGraph (https://www.onegraph.com)",
          },
          queryParams: {
            type: "track",
            q: "calling my phone",
            offset: "0",
            limit: "25",
          },
          requestBody: null,
          responseBody:
            '{\n  "tracks" : {\n    "href" : "https://api.spotify.com/v1/search?query=calling+my+phone&type=track&offset=0&limit=25",\n    "items" : [ {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/6jGMq4yGs7aQzuGsMgVgZR"\n          },\n          "href" : "https://api.spotify.com/v1/artists/6jGMq4yGs7aQzuGsMgVgZR",\n          "id" : "6jGMq4yGs7aQzuGsMgVgZR",\n          "name" : "Lil Tjay",\n          "type" : "artist",\n          "uri" : "spotify:artist:6jGMq4yGs7aQzuGsMgVgZR"\n        }, {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/4IVAbR2w4JJNJDDRFP3E83"\n          },\n          "href" : "https://api.spotify.com/v1/artists/4IVAbR2w4JJNJDDRFP3E83",\n          "id" : "4IVAbR2w4JJNJDDRFP3E83",\n          "name" : "6LACK",\n          "type" : "artist",\n          "uri" : "spotify:artist:4IVAbR2w4JJNJDDRFP3E83"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/1QhKOq11hGEoNA42rV2IHp"\n        },\n        "href" : "https://api.spotify.com/v1/albums/1QhKOq11hGEoNA42rV2IHp",\n        "id" : "1QhKOq11hGEoNA42rV2IHp",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b2731b36f91abf80aedb7c88f460",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e021b36f91abf80aedb7c88f460",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d000048511b36f91abf80aedb7c88f460",\n          "width" : 64\n        } ],\n        "name" : "Calling My Phone",\n        "release_date" : "2021-02-12",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:1QhKOq11hGEoNA42rV2IHp"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/6jGMq4yGs7aQzuGsMgVgZR"\n        },\n        "href" : "https://api.spotify.com/v1/artists/6jGMq4yGs7aQzuGsMgVgZR",\n        "id" : "6jGMq4yGs7aQzuGsMgVgZR",\n        "name" : "Lil Tjay",\n        "type" : "artist",\n        "uri" : "spotify:artist:6jGMq4yGs7aQzuGsMgVgZR"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/4IVAbR2w4JJNJDDRFP3E83"\n        },\n        "href" : "https://api.spotify.com/v1/artists/4IVAbR2w4JJNJDDRFP3E83",\n        "id" : "4IVAbR2w4JJNJDDRFP3E83",\n        "name" : "6LACK",\n        "type" : "artist",\n        "uri" : "spotify:artist:4IVAbR2w4JJNJDDRFP3E83"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 205458,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "USSM12100388"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/5Kskr9LcNYa0tpt5f0ZEJx"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/5Kskr9LcNYa0tpt5f0ZEJx",\n      "id" : "5Kskr9LcNYa0tpt5f0ZEJx",\n      "is_local" : false,\n      "name" : "Calling My Phone",\n      "popularity" : 95,\n      "preview_url" : "https://p.scdn.co/mp3-preview/557aa1208c5f9acb079cb23e71abb58431056ad0?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:5Kskr9LcNYa0tpt5f0ZEJx"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/3WSK3JppX3N41XHVwQp7Gt"\n          },\n          "href" : "https://api.spotify.com/v1/artists/3WSK3JppX3N41XHVwQp7Gt",\n          "id" : "3WSK3JppX3N41XHVwQp7Gt",\n          "name" : "Steve Void",\n          "type" : "artist",\n          "uri" : "spotify:artist:3WSK3JppX3N41XHVwQp7Gt"\n        }, {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/12nEr6QOfSKkiTXjEp8tBB"\n          },\n          "href" : "https://api.spotify.com/v1/artists/12nEr6QOfSKkiTXjEp8tBB",\n          "id" : "12nEr6QOfSKkiTXjEp8tBB",\n          "name" : "Koosen",\n          "type" : "artist",\n          "uri" : "spotify:artist:12nEr6QOfSKkiTXjEp8tBB"\n        }, {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/3HphLd0XiELTvIPYf55dYC"\n          },\n          "href" : "https://api.spotify.com/v1/artists/3HphLd0XiELTvIPYf55dYC",\n          "id" : "3HphLd0XiELTvIPYf55dYC",\n          "name" : "Strange Fruits Music",\n          "type" : "artist",\n          "uri" : "spotify:artist:3HphLd0XiELTvIPYf55dYC"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/489jwFiGVqmcZqc5hH52pa"\n        },\n        "href" : "https://api.spotify.com/v1/albums/489jwFiGVqmcZqc5hH52pa",\n        "id" : "489jwFiGVqmcZqc5hH52pa",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b2735e134a0f3143b3df8e6b4f72",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e025e134a0f3143b3df8e6b4f72",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d000048515e134a0f3143b3df8e6b4f72",\n          "width" : 64\n        } ],\n        "name" : "Calling My Phone",\n        "release_date" : "2021-03-26",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:489jwFiGVqmcZqc5hH52pa"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/3WSK3JppX3N41XHVwQp7Gt"\n        },\n        "href" : "https://api.spotify.com/v1/artists/3WSK3JppX3N41XHVwQp7Gt",\n        "id" : "3WSK3JppX3N41XHVwQp7Gt",\n        "name" : "Steve Void",\n        "type" : "artist",\n        "uri" : "spotify:artist:3WSK3JppX3N41XHVwQp7Gt"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/12nEr6QOfSKkiTXjEp8tBB"\n        },\n        "href" : "https://api.spotify.com/v1/artists/12nEr6QOfSKkiTXjEp8tBB",\n        "id" : "12nEr6QOfSKkiTXjEp8tBB",\n        "name" : "Koosen",\n        "type" : "artist",\n        "uri" : "spotify:artist:12nEr6QOfSKkiTXjEp8tBB"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/3HphLd0XiELTvIPYf55dYC"\n        },\n        "href" : "https://api.spotify.com/v1/artists/3HphLd0XiELTvIPYf55dYC",\n        "id" : "3HphLd0XiELTvIPYf55dYC",\n        "name" : "Strange Fruits Music",\n        "type" : "artist",\n        "uri" : "spotify:artist:3HphLd0XiELTvIPYf55dYC"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 136059,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "GBSMU9739776"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/0irplcCrIYLzpPn2B9CjKw"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/0irplcCrIYLzpPn2B9CjKw",\n      "id" : "0irplcCrIYLzpPn2B9CjKw",\n      "is_local" : false,\n      "name" : "Calling My Phone",\n      "popularity" : 39,\n      "preview_url" : "https://p.scdn.co/mp3-preview/fa56f4964b9dde55189615a7b1b3bd59e26428be?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:0irplcCrIYLzpPn2B9CjKw"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/0QHgL1lAIqAw0HtD7YldmP"\n          },\n          "href" : "https://api.spotify.com/v1/artists/0QHgL1lAIqAw0HtD7YldmP",\n          "id" : "0QHgL1lAIqAw0HtD7YldmP",\n          "name" : "DJ Khaled",\n          "type" : "artist",\n          "uri" : "spotify:artist:0QHgL1lAIqAw0HtD7YldmP"\n        }, {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/3TVXtAsR1Inumwj472S9r4"\n          },\n          "href" : "https://api.spotify.com/v1/artists/3TVXtAsR1Inumwj472S9r4",\n          "id" : "3TVXtAsR1Inumwj472S9r4",\n          "name" : "Drake",\n          "type" : "artist",\n          "uri" : "spotify:artist:3TVXtAsR1Inumwj472S9r4"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/5nNtpPsSUgb9Hlb3dF1gXa"\n        },\n        "href" : "https://api.spotify.com/v1/albums/5nNtpPsSUgb9Hlb3dF1gXa",\n        "id" : "5nNtpPsSUgb9Hlb3dF1gXa",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273efaecb4b9cbae7c120d14617",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02efaecb4b9cbae7c120d14617",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851efaecb4b9cbae7c120d14617",\n          "width" : 64\n        } ],\n        "name" : "POPSTAR (feat. Drake)",\n        "release_date" : "2020-07-17",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:5nNtpPsSUgb9Hlb3dF1gXa"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/0QHgL1lAIqAw0HtD7YldmP"\n        },\n        "href" : "https://api.spotify.com/v1/artists/0QHgL1lAIqAw0HtD7YldmP",\n        "id" : "0QHgL1lAIqAw0HtD7YldmP",\n        "name" : "DJ Khaled",\n        "type" : "artist",\n        "uri" : "spotify:artist:0QHgL1lAIqAw0HtD7YldmP"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/3TVXtAsR1Inumwj472S9r4"\n        },\n        "href" : "https://api.spotify.com/v1/artists/3TVXtAsR1Inumwj472S9r4",\n        "id" : "3TVXtAsR1Inumwj472S9r4",\n        "name" : "Drake",\n        "type" : "artist",\n        "uri" : "spotify:artist:3TVXtAsR1Inumwj472S9r4"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 200221,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "USSM12004501"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/6EDO9iiTtwNv6waLwa1UUq"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/6EDO9iiTtwNv6waLwa1UUq",\n      "id" : "6EDO9iiTtwNv6waLwa1UUq",\n      "is_local" : false,\n      "name" : "POPSTAR (feat. Drake)",\n      "popularity" : 86,\n      "preview_url" : "https://p.scdn.co/mp3-preview/f06dde25172503546a3b136fba9822a89866a2d3?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:6EDO9iiTtwNv6waLwa1UUq"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/4wfMyaoM1U8nnEvdI8BZnC"\n          },\n          "href" : "https://api.spotify.com/v1/artists/4wfMyaoM1U8nnEvdI8BZnC",\n          "id" : "4wfMyaoM1U8nnEvdI8BZnC",\n          "name" : "Anth",\n          "type" : "artist",\n          "uri" : "spotify:artist:4wfMyaoM1U8nnEvdI8BZnC"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/3g6uxrpVfHQpCYOEkahUyk"\n        },\n        "href" : "https://api.spotify.com/v1/albums/3g6uxrpVfHQpCYOEkahUyk",\n        "id" : "3g6uxrpVfHQpCYOEkahUyk",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b27397d16bd7fa3e07c15f06ba09",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e0297d16bd7fa3e07c15f06ba09",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d0000485197d16bd7fa3e07c15f06ba09",\n          "width" : 64\n        } ],\n        "name" : "Calling My Phone",\n        "release_date" : "2021-03-05",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:3g6uxrpVfHQpCYOEkahUyk"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/4wfMyaoM1U8nnEvdI8BZnC"\n        },\n        "href" : "https://api.spotify.com/v1/artists/4wfMyaoM1U8nnEvdI8BZnC",\n        "id" : "4wfMyaoM1U8nnEvdI8BZnC",\n        "name" : "Anth",\n        "type" : "artist",\n        "uri" : "spotify:artist:4wfMyaoM1U8nnEvdI8BZnC"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/0wTo7DrA2tFVMqzWl3oco9"\n        },\n        "href" : "https://api.spotify.com/v1/artists/0wTo7DrA2tFVMqzWl3oco9",\n        "id" : "0wTo7DrA2tFVMqzWl3oco9",\n        "name" : "Corey Nyell",\n        "type" : "artist",\n        "uri" : "spotify:artist:0wTo7DrA2tFVMqzWl3oco9"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 67950,\n      "explicit" : false,\n      "external_ids" : {\n        "isrc" : "TCAFL2103823"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/1CG8FcfigkTS4xVpIuNDOZ"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/1CG8FcfigkTS4xVpIuNDOZ",\n      "id" : "1CG8FcfigkTS4xVpIuNDOZ",\n      "is_local" : false,\n      "name" : "Calling My Phone",\n      "popularity" : 42,\n      "preview_url" : "https://p.scdn.co/mp3-preview/036a5b78154fa167b654b5f92833b921b7d4ce52?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:1CG8FcfigkTS4xVpIuNDOZ"\n    }, {\n      "album" : {\n        "album_type" : "album",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/4MCBfE4596Uoi2O4DtmEMz"\n          },\n          "href" : "https://api.spotify.com/v1/artists/4MCBfE4596Uoi2O4DtmEMz",\n          "id" : "4MCBfE4596Uoi2O4DtmEMz",\n          "name" : "Juice WRLD",\n          "type" : "artist",\n          "uri" : "spotify:artist:4MCBfE4596Uoi2O4DtmEMz"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BG", "BH", "BI", "BJ", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/6tkjU4Umpo79wwkgPMV3nZ"\n        },\n        "href" : "https://api.spotify.com/v1/albums/6tkjU4Umpo79wwkgPMV3nZ",\n        "id" : "6tkjU4Umpo79wwkgPMV3nZ",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273f7db43292a6a99b21b51d5b4",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02f7db43292a6a99b21b51d5b4",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851f7db43292a6a99b21b51d5b4",\n          "width" : 64\n        } ],\n        "name" : "Goodbye & Good Riddance",\n        "release_date" : "2018-12-10",\n        "release_date_precision" : "day",\n        "total_tracks" : 17,\n        "type" : "album",\n        "uri" : "spotify:album:6tkjU4Umpo79wwkgPMV3nZ"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/4MCBfE4596Uoi2O4DtmEMz"\n        },\n        "href" : "https://api.spotify.com/v1/artists/4MCBfE4596Uoi2O4DtmEMz",\n        "id" : "4MCBfE4596Uoi2O4DtmEMz",\n        "name" : "Juice WRLD",\n        "type" : "artist",\n        "uri" : "spotify:artist:4MCBfE4596Uoi2O4DtmEMz"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BG", "BH", "BI", "BJ", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 122285,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "USUG11800953"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/3XRQT7EoS4U87rUuJwg5P3"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/3XRQT7EoS4U87rUuJwg5P3",\n      "id" : "3XRQT7EoS4U87rUuJwg5P3",\n      "is_local" : false,\n      "name" : "Hurt Me",\n      "popularity" : 74,\n      "preview_url" : null,\n      "track_number" : 12,\n      "type" : "track",\n      "uri" : "spotify:track:3XRQT7EoS4U87rUuJwg5P3"\n    }, {\n      "album" : {\n        "album_type" : "album",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/3UT1RvZWegCJFsqCSJJF5U"\n          },\n          "href" : "https://api.spotify.com/v1/artists/3UT1RvZWegCJFsqCSJJF5U",\n          "id" : "3UT1RvZWegCJFsqCSJJF5U",\n          "name" : "TrenchMobb",\n          "type" : "artist",\n          "uri" : "spotify:artist:3UT1RvZWegCJFsqCSJJF5U"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/1gAwMB28nNss6LP22ZyUj1"\n        },\n        "href" : "https://api.spotify.com/v1/albums/1gAwMB28nNss6LP22ZyUj1",\n        "id" : "1gAwMB28nNss6LP22ZyUj1",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b2734efab5baae06dcb5f6645e27",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e024efab5baae06dcb5f6645e27",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d000048514efab5baae06dcb5f6645e27",\n          "width" : 64\n        } ],\n        "name" : "TMBG4L",\n        "release_date" : "2019-06-12",\n        "release_date_precision" : "day",\n        "total_tracks" : 12,\n        "type" : "album",\n        "uri" : "spotify:album:1gAwMB28nNss6LP22ZyUj1"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/3UT1RvZWegCJFsqCSJJF5U"\n        },\n        "href" : "https://api.spotify.com/v1/artists/3UT1RvZWegCJFsqCSJJF5U",\n        "id" : "3UT1RvZWegCJFsqCSJJF5U",\n        "name" : "TrenchMobb",\n        "type" : "artist",\n        "uri" : "spotify:artist:3UT1RvZWegCJFsqCSJJF5U"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 223533,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "QMGR32033419"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/0LyFks8nymyx5uJz8Ldcab"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/0LyFks8nymyx5uJz8Ldcab",\n      "id" : "0LyFks8nymyx5uJz8Ldcab",\n      "is_local" : false,\n      "name" : "Calling My Phone",\n      "popularity" : 26,\n      "preview_url" : "https://p.scdn.co/mp3-preview/958d35cf63adb5dd6a98a2826ae37fb2f3072f0d?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 5,\n      "type" : "track",\n      "uri" : "spotify:track:0LyFks8nymyx5uJz8Ldcab"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/6jGMq4yGs7aQzuGsMgVgZR"\n          },\n          "href" : "https://api.spotify.com/v1/artists/6jGMq4yGs7aQzuGsMgVgZR",\n          "id" : "6jGMq4yGs7aQzuGsMgVgZR",\n          "name" : "Lil Tjay",\n          "type" : "artist",\n          "uri" : "spotify:artist:6jGMq4yGs7aQzuGsMgVgZR"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/74nxdn9ypqp3hqJEttpDNU"\n        },\n        "href" : "https://api.spotify.com/v1/albums/74nxdn9ypqp3hqJEttpDNU",\n        "id" : "74nxdn9ypqp3hqJEttpDNU",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273c3c0cf41da2bb35e19acc875",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02c3c0cf41da2bb35e19acc875",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851c3c0cf41da2bb35e19acc875",\n          "width" : 64\n        } ],\n        "name" : "Headshot",\n        "release_date" : "2021-03-19",\n        "release_date_precision" : "day",\n        "total_tracks" : 2,\n        "type" : "album",\n        "uri" : "spotify:album:74nxdn9ypqp3hqJEttpDNU"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/6jGMq4yGs7aQzuGsMgVgZR"\n        },\n        "href" : "https://api.spotify.com/v1/artists/6jGMq4yGs7aQzuGsMgVgZR",\n        "id" : "6jGMq4yGs7aQzuGsMgVgZR",\n        "name" : "Lil Tjay",\n        "type" : "artist",\n        "uri" : "spotify:artist:6jGMq4yGs7aQzuGsMgVgZR"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/4IVAbR2w4JJNJDDRFP3E83"\n        },\n        "href" : "https://api.spotify.com/v1/artists/4IVAbR2w4JJNJDDRFP3E83",\n        "id" : "4IVAbR2w4JJNJDDRFP3E83",\n        "name" : "6LACK",\n        "type" : "artist",\n        "uri" : "spotify:artist:4IVAbR2w4JJNJDDRFP3E83"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 205458,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "USSM12100388"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/7ttccyDY7hfzvzPXmA7E8t"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/7ttccyDY7hfzvzPXmA7E8t",\n      "id" : "7ttccyDY7hfzvzPXmA7E8t",\n      "is_local" : false,\n      "name" : "Calling My Phone",\n      "popularity" : 58,\n      "preview_url" : "https://p.scdn.co/mp3-preview/557aa1208c5f9acb079cb23e71abb58431056ad0?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:7ttccyDY7hfzvzPXmA7E8t"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/0Eteu6PFYUcOFloRlgZOBP"\n          },\n          "href" : "https://api.spotify.com/v1/artists/0Eteu6PFYUcOFloRlgZOBP",\n          "id" : "0Eteu6PFYUcOFloRlgZOBP",\n          "name" : "Lacy B",\n          "type" : "artist",\n          "uri" : "spotify:artist:0Eteu6PFYUcOFloRlgZOBP"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/1yciTZmMMVHJwlqCK1asHI"\n        },\n        "href" : "https://api.spotify.com/v1/albums/1yciTZmMMVHJwlqCK1asHI",\n        "id" : "1yciTZmMMVHJwlqCK1asHI",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273833e8182c9dceca999ad223b",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02833e8182c9dceca999ad223b",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851833e8182c9dceca999ad223b",\n          "width" : 64\n        } ],\n        "name" : "Calling My Phone",\n        "release_date" : "2021-03-13",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:1yciTZmMMVHJwlqCK1asHI"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/0Eteu6PFYUcOFloRlgZOBP"\n        },\n        "href" : "https://api.spotify.com/v1/artists/0Eteu6PFYUcOFloRlgZOBP",\n        "id" : "0Eteu6PFYUcOFloRlgZOBP",\n        "name" : "Lacy B",\n        "type" : "artist",\n        "uri" : "spotify:artist:0Eteu6PFYUcOFloRlgZOBP"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 208326,\n      "explicit" : false,\n      "external_ids" : {\n        "isrc" : "QZDA82147243"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/40nmy5pHfCyoMlFiqa0ImR"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/40nmy5pHfCyoMlFiqa0ImR",\n      "id" : "40nmy5pHfCyoMlFiqa0ImR",\n      "is_local" : false,\n      "name" : "Calling My Phone",\n      "popularity" : 21,\n      "preview_url" : "https://p.scdn.co/mp3-preview/09f1e85c4c93605e26f21c16a35f22d0a64407b3?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:40nmy5pHfCyoMlFiqa0ImR"\n    }, {\n      "album" : {\n        "album_type" : "album",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/4xRYI6VqpkE3UwrDrAZL8L"\n          },\n          "href" : "https://api.spotify.com/v1/artists/4xRYI6VqpkE3UwrDrAZL8L",\n          "id" : "4xRYI6VqpkE3UwrDrAZL8L",\n          "name" : "Logic",\n          "type" : "artist",\n          "uri" : "spotify:artist:4xRYI6VqpkE3UwrDrAZL8L"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BG", "BH", "BI", "BJ", "BO", "BR", "BS", "BT", "BW", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/1HiN2YXZcc3EjmVZ4WjfBk"\n        },\n        "href" : "https://api.spotify.com/v1/albums/1HiN2YXZcc3EjmVZ4WjfBk",\n        "id" : "1HiN2YXZcc3EjmVZ4WjfBk",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273cfdf40cf325b609a52457805",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02cfdf40cf325b609a52457805",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851cfdf40cf325b609a52457805",\n          "width" : 64\n        } ],\n        "name" : "Everybody",\n        "release_date" : "2017-05-05",\n        "release_date_precision" : "day",\n        "total_tracks" : 13,\n        "type" : "album",\n        "uri" : "spotify:album:1HiN2YXZcc3EjmVZ4WjfBk"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/4xRYI6VqpkE3UwrDrAZL8L"\n        },\n        "href" : "https://api.spotify.com/v1/artists/4xRYI6VqpkE3UwrDrAZL8L",\n        "id" : "4xRYI6VqpkE3UwrDrAZL8L",\n        "name" : "Logic",\n        "type" : "artist",\n        "uri" : "spotify:artist:4xRYI6VqpkE3UwrDrAZL8L"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/2wUjUUtkb5lvLKcGKsKqsR"\n        },\n        "href" : "https://api.spotify.com/v1/artists/2wUjUUtkb5lvLKcGKsKqsR",\n        "id" : "2wUjUUtkb5lvLKcGKsKqsR",\n        "name" : "Alessia Cara",\n        "type" : "artist",\n        "uri" : "spotify:artist:2wUjUUtkb5lvLKcGKsKqsR"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/6LuN9FCkKOj5PcnpouEgny"\n        },\n        "href" : "https://api.spotify.com/v1/artists/6LuN9FCkKOj5PcnpouEgny",\n        "id" : "6LuN9FCkKOj5PcnpouEgny",\n        "name" : "Khalid",\n        "type" : "artist",\n        "uri" : "spotify:artist:6LuN9FCkKOj5PcnpouEgny"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BG", "BH", "BI", "BJ", "BO", "BR", "BS", "BT", "BW", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 250173,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "USUM71702778"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/5tz69p7tJuGPeMGwNTxYuV"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/5tz69p7tJuGPeMGwNTxYuV",\n      "id" : "5tz69p7tJuGPeMGwNTxYuV",\n      "is_local" : false,\n      "name" : "1-800-273-8255",\n      "popularity" : 79,\n      "preview_url" : null,\n      "track_number" : 10,\n      "type" : "track",\n      "uri" : "spotify:track:5tz69p7tJuGPeMGwNTxYuV"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/5SlNmBUe6YvQ6PczVQIFL5"\n          },\n          "href" : "https://api.spotify.com/v1/artists/5SlNmBUe6YvQ6PczVQIFL5",\n          "id" : "5SlNmBUe6YvQ6PczVQIFL5",\n          "name" : "Dayshock Beats",\n          "type" : "artist",\n          "uri" : "spotify:artist:5SlNmBUe6YvQ6PczVQIFL5"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/2a41YkxO5XqCz7UuycJxr1"\n        },\n        "href" : "https://api.spotify.com/v1/albums/2a41YkxO5XqCz7UuycJxr1",\n        "id" : "2a41YkxO5XqCz7UuycJxr1",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b2731b98dcc57736f585afe525ea",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e021b98dcc57736f585afe525ea",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d000048511b98dcc57736f585afe525ea",\n          "width" : 64\n        } ],\n        "name" : "Calling My Phone (Instrumental)",\n        "release_date" : "2021-02-16",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:2a41YkxO5XqCz7UuycJxr1"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/5SlNmBUe6YvQ6PczVQIFL5"\n        },\n        "href" : "https://api.spotify.com/v1/artists/5SlNmBUe6YvQ6PczVQIFL5",\n        "id" : "5SlNmBUe6YvQ6PczVQIFL5",\n        "name" : "Dayshock Beats",\n        "type" : "artist",\n        "uri" : "spotify:artist:5SlNmBUe6YvQ6PczVQIFL5"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 201325,\n      "explicit" : false,\n      "external_ids" : {\n        "isrc" : "QZKDK2161009"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/1AsLQgAemuaRYAWKzp07K7"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/1AsLQgAemuaRYAWKzp07K7",\n      "id" : "1AsLQgAemuaRYAWKzp07K7",\n      "is_local" : false,\n      "name" : "Calling My Phone - Instrumental",\n      "popularity" : 25,\n      "preview_url" : "https://p.scdn.co/mp3-preview/48ddbbab965bac37158bcf62351cf45bd7001500?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:1AsLQgAemuaRYAWKzp07K7"\n    }, {\n      "album" : {\n        "album_type" : "album",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/2kCcBybjl3SAtIcwdWpUe3"\n          },\n          "href" : "https://api.spotify.com/v1/artists/2kCcBybjl3SAtIcwdWpUe3",\n          "id" : "2kCcBybjl3SAtIcwdWpUe3",\n          "name" : "Lil Peep",\n          "type" : "artist",\n          "uri" : "spotify:artist:2kCcBybjl3SAtIcwdWpUe3"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/1r1Xt6oUnY3VMYbQb1U7CO"\n        },\n        "href" : "https://api.spotify.com/v1/albums/1r1Xt6oUnY3VMYbQb1U7CO",\n        "id" : "1r1Xt6oUnY3VMYbQb1U7CO",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273c73bd9b0e34b067d7d3bd7b9",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02c73bd9b0e34b067d7d3bd7b9",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851c73bd9b0e34b067d7d3bd7b9",\n          "width" : 64\n        } ],\n        "name" : "EVERYBODY\'S EVERYTHING",\n        "release_date" : "2019-11-15",\n        "release_date_precision" : "day",\n        "total_tracks" : 19,\n        "type" : "album",\n        "uri" : "spotify:album:1r1Xt6oUnY3VMYbQb1U7CO"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/2kCcBybjl3SAtIcwdWpUe3"\n        },\n        "href" : "https://api.spotify.com/v1/artists/2kCcBybjl3SAtIcwdWpUe3",\n        "id" : "2kCcBybjl3SAtIcwdWpUe3",\n        "name" : "Lil Peep",\n        "type" : "artist",\n        "uri" : "spotify:artist:2kCcBybjl3SAtIcwdWpUe3"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 130973,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "USQX91903109"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/4Am4agzcSdFnKLSEB56ODY"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/4Am4agzcSdFnKLSEB56ODY",\n      "id" : "4Am4agzcSdFnKLSEB56ODY",\n      "is_local" : false,\n      "name" : "ghost boy",\n      "popularity" : 70,\n      "preview_url" : "https://p.scdn.co/mp3-preview/6c63f3bbc0e215d67d9b63a28e6cca42d17266fa?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 14,\n      "type" : "track",\n      "uri" : "spotify:track:4Am4agzcSdFnKLSEB56ODY"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/0zfNkbfXyVpesD3S0XFKB8"\n          },\n          "href" : "https://api.spotify.com/v1/artists/0zfNkbfXyVpesD3S0XFKB8",\n          "id" : "0zfNkbfXyVpesD3S0XFKB8",\n          "name" : "golden era",\n          "type" : "artist",\n          "uri" : "spotify:artist:0zfNkbfXyVpesD3S0XFKB8"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/5BUhnXW1vmVbH0Mn81WCJL"\n        },\n        "href" : "https://api.spotify.com/v1/albums/5BUhnXW1vmVbH0Mn81WCJL",\n        "id" : "5BUhnXW1vmVbH0Mn81WCJL",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b27373eb20baa5563cf0f92c554e",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e0273eb20baa5563cf0f92c554e",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d0000485173eb20baa5563cf0f92c554e",\n          "width" : 64\n        } ],\n        "name" : "Calling My Phone (lofi version)",\n        "release_date" : "2021-02-26",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:5BUhnXW1vmVbH0Mn81WCJL"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/0zfNkbfXyVpesD3S0XFKB8"\n        },\n        "href" : "https://api.spotify.com/v1/artists/0zfNkbfXyVpesD3S0XFKB8",\n        "id" : "0zfNkbfXyVpesD3S0XFKB8",\n        "name" : "golden era",\n        "type" : "artist",\n        "uri" : "spotify:artist:0zfNkbfXyVpesD3S0XFKB8"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 120000,\n      "explicit" : false,\n      "external_ids" : {\n        "isrc" : "GBSMU9613092"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/319uz5mk3s6GmqErQoeHXb"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/319uz5mk3s6GmqErQoeHXb",\n      "id" : "319uz5mk3s6GmqErQoeHXb",\n      "is_local" : false,\n      "name" : "Calling My Phone (lofi version)",\n      "popularity" : 32,\n      "preview_url" : "https://p.scdn.co/mp3-preview/79ffa0eac5f16cfd753c7910c1187ec60bdd86f6?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:319uz5mk3s6GmqErQoeHXb"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/2tIP7SsRs7vjIcLrU85W8J"\n          },\n          "href" : "https://api.spotify.com/v1/artists/2tIP7SsRs7vjIcLrU85W8J",\n          "id" : "2tIP7SsRs7vjIcLrU85W8J",\n          "name" : "The Kid LAROI",\n          "type" : "artist",\n          "uri" : "spotify:artist:2tIP7SsRs7vjIcLrU85W8J"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/2PMhID6CzdaI8t4dlPSodY"\n        },\n        "href" : "https://api.spotify.com/v1/albums/2PMhID6CzdaI8t4dlPSodY",\n        "id" : "2PMhID6CzdaI8t4dlPSodY",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273b42765a5921d09cad8bac5e2",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02b42765a5921d09cad8bac5e2",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851b42765a5921d09cad8bac5e2",\n          "width" : 64\n        } ],\n        "name" : "Let Her Go",\n        "release_date" : "2019-12-06",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:2PMhID6CzdaI8t4dlPSodY"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/2tIP7SsRs7vjIcLrU85W8J"\n        },\n        "href" : "https://api.spotify.com/v1/artists/2tIP7SsRs7vjIcLrU85W8J",\n        "id" : "2tIP7SsRs7vjIcLrU85W8J",\n        "name" : "The Kid LAROI",\n        "type" : "artist",\n        "uri" : "spotify:artist:2tIP7SsRs7vjIcLrU85W8J"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 122112,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "USSM11914618"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/0c6SqvH32BMgbEFvpHc2gs"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/0c6SqvH32BMgbEFvpHc2gs",\n      "id" : "0c6SqvH32BMgbEFvpHc2gs",\n      "is_local" : false,\n      "name" : "Let Her Go",\n      "popularity" : 74,\n      "preview_url" : "https://p.scdn.co/mp3-preview/bcd77ebae0edfacd01140646ba29e16ba02b9846?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:0c6SqvH32BMgbEFvpHc2gs"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/3uN3xjYywFKhozIwSf2WMN"\n          },\n          "href" : "https://api.spotify.com/v1/artists/3uN3xjYywFKhozIwSf2WMN",\n          "id" : "3uN3xjYywFKhozIwSf2WMN",\n          "name" : "Diamond Audio",\n          "type" : "artist",\n          "uri" : "spotify:artist:3uN3xjYywFKhozIwSf2WMN"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/3DijJ3lKR1MMEXyM16RpYh"\n        },\n        "href" : "https://api.spotify.com/v1/albums/3DijJ3lKR1MMEXyM16RpYh",\n        "id" : "3DijJ3lKR1MMEXyM16RpYh",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273a3aeb6759ed9a7c36c656a1e",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02a3aeb6759ed9a7c36c656a1e",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851a3aeb6759ed9a7c36c656a1e",\n          "width" : 64\n        } ],\n        "name" : "Calling My Phone (Instrumental)",\n        "release_date" : "2021-02-13",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:3DijJ3lKR1MMEXyM16RpYh"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/3uN3xjYywFKhozIwSf2WMN"\n        },\n        "href" : "https://api.spotify.com/v1/artists/3uN3xjYywFKhozIwSf2WMN",\n        "id" : "3uN3xjYywFKhozIwSf2WMN",\n        "name" : "Diamond Audio",\n        "type" : "artist",\n        "uri" : "spotify:artist:3uN3xjYywFKhozIwSf2WMN"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 201800,\n      "explicit" : false,\n      "external_ids" : {\n        "isrc" : "ATR981224276"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/44ZnnYBMGtxyZLo4ioGFSJ"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/44ZnnYBMGtxyZLo4ioGFSJ",\n      "id" : "44ZnnYBMGtxyZLo4ioGFSJ",\n      "is_local" : false,\n      "name" : "Calling My Phone - Instrumental",\n      "popularity" : 27,\n      "preview_url" : "https://p.scdn.co/mp3-preview/ef6e038beef10c9c3d1e487921fbc919d0dab9db?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:44ZnnYBMGtxyZLo4ioGFSJ"\n    }, {\n      "album" : {\n        "album_type" : "album",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/5cj0lLjcoR7YOSnhnX0Po5"\n          },\n          "href" : "https://api.spotify.com/v1/artists/5cj0lLjcoR7YOSnhnX0Po5",\n          "id" : "5cj0lLjcoR7YOSnhnX0Po5",\n          "name" : "Doja Cat",\n          "type" : "artist",\n          "uri" : "spotify:artist:5cj0lLjcoR7YOSnhnX0Po5"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/3wOMqxNHgkga91RBC7BaZU"\n        },\n        "href" : "https://api.spotify.com/v1/albums/3wOMqxNHgkga91RBC7BaZU",\n        "id" : "3wOMqxNHgkga91RBC7BaZU",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b27305d15f02b484a462368cce63",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e0205d15f02b484a462368cce63",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d0000485105d15f02b484a462368cce63",\n          "width" : 64\n        } ],\n        "name" : "Amala (Deluxe Version)",\n        "release_date" : "2019-03-01",\n        "release_date_precision" : "day",\n        "total_tracks" : 16,\n        "type" : "album",\n        "uri" : "spotify:album:3wOMqxNHgkga91RBC7BaZU"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/5cj0lLjcoR7YOSnhnX0Po5"\n        },\n        "href" : "https://api.spotify.com/v1/artists/5cj0lLjcoR7YOSnhnX0Po5",\n        "id" : "5cj0lLjcoR7YOSnhnX0Po5",\n        "name" : "Doja Cat",\n        "type" : "artist",\n        "uri" : "spotify:artist:5cj0lLjcoR7YOSnhnX0Po5"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/2OaHYHb2XcFPvqL3VsyPzU"\n        },\n        "href" : "https://api.spotify.com/v1/artists/2OaHYHb2XcFPvqL3VsyPzU",\n        "id" : "2OaHYHb2XcFPvqL3VsyPzU",\n        "name" : "Rico Nasty",\n        "type" : "artist",\n        "uri" : "spotify:artist:2OaHYHb2XcFPvqL3VsyPzU"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 211013,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "USRC11803908"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/1uNePI826aqh9uC9pgbeHU"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/1uNePI826aqh9uC9pgbeHU",\n      "id" : "1uNePI826aqh9uC9pgbeHU",\n      "is_local" : false,\n      "name" : "Tia Tamera (feat. Rico Nasty)",\n      "popularity" : 74,\n      "preview_url" : "https://p.scdn.co/mp3-preview/d475f2f6b029ecf8e327271c01e6c9bd7bb38d3d?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 15,\n      "type" : "track",\n      "uri" : "spotify:track:1uNePI826aqh9uC9pgbeHU"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/4fr883O2ZQigoTV9PVkrd7"\n          },\n          "href" : "https://api.spotify.com/v1/artists/4fr883O2ZQigoTV9PVkrd7",\n          "id" : "4fr883O2ZQigoTV9PVkrd7",\n          "name" : "Delaan",\n          "type" : "artist",\n          "uri" : "spotify:artist:4fr883O2ZQigoTV9PVkrd7"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/6qfGfoOI66NJPFh43009L8"\n        },\n        "href" : "https://api.spotify.com/v1/albums/6qfGfoOI66NJPFh43009L8",\n        "id" : "6qfGfoOI66NJPFh43009L8",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b27372b38f949fc185ce545c64de",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e0272b38f949fc185ce545c64de",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d0000485172b38f949fc185ce545c64de",\n          "width" : 64\n        } ],\n        "name" : "Calling My Phone",\n        "release_date" : "2021-03-26",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:6qfGfoOI66NJPFh43009L8"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/4fr883O2ZQigoTV9PVkrd7"\n        },\n        "href" : "https://api.spotify.com/v1/artists/4fr883O2ZQigoTV9PVkrd7",\n        "id" : "4fr883O2ZQigoTV9PVkrd7",\n        "name" : "Delaan",\n        "type" : "artist",\n        "uri" : "spotify:artist:4fr883O2ZQigoTV9PVkrd7"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 165067,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "TCAFL2111188"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/0ab6RSPJSTE14pGvwKRYti"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/0ab6RSPJSTE14pGvwKRYti",\n      "id" : "0ab6RSPJSTE14pGvwKRYti",\n      "is_local" : false,\n      "name" : "Calling My Phone",\n      "popularity" : 0,\n      "preview_url" : "https://p.scdn.co/mp3-preview/05a8ed80e3749a7e799f67a3a2231262d15539e2?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:0ab6RSPJSTE14pGvwKRYti"\n    }, {\n      "album" : {\n        "album_type" : "album",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/1vfezMIyCr4XUdYRaKIKi3"\n          },\n          "href" : "https://api.spotify.com/v1/artists/1vfezMIyCr4XUdYRaKIKi3",\n          "id" : "1vfezMIyCr4XUdYRaKIKi3",\n          "name" : "Keyshia Cole",\n          "type" : "artist",\n          "uri" : "spotify:artist:1vfezMIyCr4XUdYRaKIKi3"\n        } ],\n        "available_markets" : [ "CA", "MX", "US" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/7mdy09EO4q6F9VWBtXDDjK"\n        },\n        "href" : "https://api.spotify.com/v1/albums/7mdy09EO4q6F9VWBtXDDjK",\n        "id" : "7mdy09EO4q6F9VWBtXDDjK",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273911ef35f75422d0482cec8bf",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02911ef35f75422d0482cec8bf",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851911ef35f75422d0482cec8bf",\n          "width" : 64\n        } ],\n        "name" : "Just Like You",\n        "release_date" : "2007-01-01",\n        "release_date_precision" : "day",\n        "total_tracks" : 15,\n        "type" : "album",\n        "uri" : "spotify:album:7mdy09EO4q6F9VWBtXDDjK"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/1vfezMIyCr4XUdYRaKIKi3"\n        },\n        "href" : "https://api.spotify.com/v1/artists/1vfezMIyCr4XUdYRaKIKi3",\n        "id" : "1vfezMIyCr4XUdYRaKIKi3",\n        "name" : "Keyshia Cole",\n        "type" : "artist",\n        "uri" : "spotify:artist:1vfezMIyCr4XUdYRaKIKi3"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/2wIVse2owClT7go1WT98tk"\n        },\n        "href" : "https://api.spotify.com/v1/artists/2wIVse2owClT7go1WT98tk",\n        "id" : "2wIVse2owClT7go1WT98tk",\n        "name" : "Missy Elliott",\n        "type" : "artist",\n        "uri" : "spotify:artist:2wIVse2owClT7go1WT98tk"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/5tth2a3v0sWwV1C7bApBdX"\n        },\n        "href" : "https://api.spotify.com/v1/artists/5tth2a3v0sWwV1C7bApBdX",\n        "id" : "5tth2a3v0sWwV1C7bApBdX",\n        "name" : "Lil\' Kim",\n        "type" : "artist",\n        "uri" : "spotify:artist:5tth2a3v0sWwV1C7bApBdX"\n      } ],\n      "available_markets" : [ "CA", "MX", "US" ],\n      "disc_number" : 1,\n      "duration_ms" : 238333,\n      "explicit" : false,\n      "external_ids" : {\n        "isrc" : "USUM70740000"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/2RqZFOLOnzVmHUX7ZMcaES"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/2RqZFOLOnzVmHUX7ZMcaES",\n      "id" : "2RqZFOLOnzVmHUX7ZMcaES",\n      "is_local" : false,\n      "name" : "Let It Go",\n      "popularity" : 68,\n      "preview_url" : null,\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:2RqZFOLOnzVmHUX7ZMcaES"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/1HSO8yQZ36mW4dUvzkQkuX"\n          },\n          "href" : "https://api.spotify.com/v1/artists/1HSO8yQZ36mW4dUvzkQkuX",\n          "id" : "1HSO8yQZ36mW4dUvzkQkuX",\n          "name" : "HeartSore Tigris",\n          "type" : "artist",\n          "uri" : "spotify:artist:1HSO8yQZ36mW4dUvzkQkuX"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/2lAMEqY57VoWCHZxMK7M47"\n        },\n        "href" : "https://api.spotify.com/v1/albums/2lAMEqY57VoWCHZxMK7M47",\n        "id" : "2lAMEqY57VoWCHZxMK7M47",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273396085625a614b67235e12bf",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02396085625a614b67235e12bf",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851396085625a614b67235e12bf",\n          "width" : 64\n        } ],\n        "name" : "Love is War",\n        "release_date" : "2020-05-05",\n        "release_date_precision" : "day",\n        "total_tracks" : 4,\n        "type" : "album",\n        "uri" : "spotify:album:2lAMEqY57VoWCHZxMK7M47"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/1HSO8yQZ36mW4dUvzkQkuX"\n        },\n        "href" : "https://api.spotify.com/v1/artists/1HSO8yQZ36mW4dUvzkQkuX",\n        "id" : "1HSO8yQZ36mW4dUvzkQkuX",\n        "name" : "HeartSore Tigris",\n        "type" : "artist",\n        "uri" : "spotify:artist:1HSO8yQZ36mW4dUvzkQkuX"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 192395,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "QZDFP1833134"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/6mspqbQTCjhAxGCZIa0i64"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/6mspqbQTCjhAxGCZIa0i64",\n      "id" : "6mspqbQTCjhAxGCZIa0i64",\n      "is_local" : false,\n      "name" : "Stop Calling My Phone",\n      "popularity" : 20,\n      "preview_url" : "https://p.scdn.co/mp3-preview/52ce252401f2efb1ef4e8c7d6bb32fb5ba5e5958?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 2,\n      "type" : "track",\n      "uri" : "spotify:track:6mspqbQTCjhAxGCZIa0i64"\n    }, {\n      "album" : {\n        "album_type" : "album",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/137W8MRPWKqSmrBGDBFSop"\n          },\n          "href" : "https://api.spotify.com/v1/artists/137W8MRPWKqSmrBGDBFSop",\n          "id" : "137W8MRPWKqSmrBGDBFSop",\n          "name" : "Wiz Khalifa",\n          "type" : "artist",\n          "uri" : "spotify:artist:137W8MRPWKqSmrBGDBFSop"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/22rKa9MG4cHIRxvL1Vbs0q"\n        },\n        "href" : "https://api.spotify.com/v1/albums/22rKa9MG4cHIRxvL1Vbs0q",\n        "id" : "22rKa9MG4cHIRxvL1Vbs0q",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273117ad8c714eeb4cf950101d5",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02117ad8c714eeb4cf950101d5",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851117ad8c714eeb4cf950101d5",\n          "width" : 64\n        } ],\n        "name" : "Rolling Papers (Deluxe 10 Year Anniversary Edition)",\n        "release_date" : "2021-03-26",\n        "release_date_precision" : "day",\n        "total_tracks" : 18,\n        "type" : "album",\n        "uri" : "spotify:album:22rKa9MG4cHIRxvL1Vbs0q"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/137W8MRPWKqSmrBGDBFSop"\n        },\n        "href" : "https://api.spotify.com/v1/artists/137W8MRPWKqSmrBGDBFSop",\n        "id" : "137W8MRPWKqSmrBGDBFSop",\n        "name" : "Wiz Khalifa",\n        "type" : "artist",\n        "uri" : "spotify:artist:137W8MRPWKqSmrBGDBFSop"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 335613,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "USAT21100152"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/45lzMXVHXToapMnGyKMCyB"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/45lzMXVHXToapMnGyKMCyB",\n      "id" : "45lzMXVHXToapMnGyKMCyB",\n      "is_local" : false,\n      "name" : "The Race",\n      "popularity" : 22,\n      "preview_url" : "https://p.scdn.co/mp3-preview/e9a49cb3c76b973b6fd29e982dd85af3b9eec6b0?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 7,\n      "type" : "track",\n      "uri" : "spotify:track:45lzMXVHXToapMnGyKMCyB"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/05xCOJrGpiF3AiEBIFfJPM"\n          },\n          "href" : "https://api.spotify.com/v1/artists/05xCOJrGpiF3AiEBIFfJPM",\n          "id" : "05xCOJrGpiF3AiEBIFfJPM",\n          "name" : "Hollywood Ko",\n          "type" : "artist",\n          "uri" : "spotify:artist:05xCOJrGpiF3AiEBIFfJPM"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/7h5rQItycT454ovVre4CSb"\n        },\n        "href" : "https://api.spotify.com/v1/albums/7h5rQItycT454ovVre4CSb",\n        "id" : "7h5rQItycT454ovVre4CSb",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b27395ebae1e7d26bcb18859c9f1",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e0295ebae1e7d26bcb18859c9f1",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d0000485195ebae1e7d26bcb18859c9f1",\n          "width" : 64\n        } ],\n        "name" : "Calling My Phone",\n        "release_date" : "2021-03-16",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:7h5rQItycT454ovVre4CSb"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/05xCOJrGpiF3AiEBIFfJPM"\n        },\n        "href" : "https://api.spotify.com/v1/artists/05xCOJrGpiF3AiEBIFfJPM",\n        "id" : "05xCOJrGpiF3AiEBIFfJPM",\n        "name" : "Hollywood Ko",\n        "type" : "artist",\n        "uri" : "spotify:artist:05xCOJrGpiF3AiEBIFfJPM"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/2UW1lEqHlTTXeqz13RFGCE"\n        },\n        "href" : "https://api.spotify.com/v1/artists/2UW1lEqHlTTXeqz13RFGCE",\n        "id" : "2UW1lEqHlTTXeqz13RFGCE",\n        "name" : "BritLov3",\n        "type" : "artist",\n        "uri" : "spotify:artist:2UW1lEqHlTTXeqz13RFGCE"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 138668,\n      "explicit" : false,\n      "external_ids" : {\n        "isrc" : "QZNMV2197149"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/5QRBK8PcwFS2cDPyKiWNr7"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/5QRBK8PcwFS2cDPyKiWNr7",\n      "id" : "5QRBK8PcwFS2cDPyKiWNr7",\n      "is_local" : false,\n      "name" : "Calling My Phone",\n      "popularity" : 0,\n      "preview_url" : "https://p.scdn.co/mp3-preview/0569ec04d68489871784c1d3b829cb3b66485c4f?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:5QRBK8PcwFS2cDPyKiWNr7"\n    }, {\n      "album" : {\n        "album_type" : "album",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/6S0dmVVn4udvppDhZIWxCr"\n          },\n          "href" : "https://api.spotify.com/v1/artists/6S0dmVVn4udvppDhZIWxCr",\n          "id" : "6S0dmVVn4udvppDhZIWxCr",\n          "name" : "Sean Kingston",\n          "type" : "artist",\n          "uri" : "spotify:artist:6S0dmVVn4udvppDhZIWxCr"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/1fOIkbQO1zU1rO3GLIGJBH"\n        },\n        "href" : "https://api.spotify.com/v1/albums/1fOIkbQO1zU1rO3GLIGJBH",\n        "id" : "1fOIkbQO1zU1rO3GLIGJBH",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b273d62e2e5e48912cac698d7eeb",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e02d62e2e5e48912cac698d7eeb",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d00004851d62e2e5e48912cac698d7eeb",\n          "width" : 64\n        } ],\n        "name" : "Back 2 Life",\n        "release_date" : "2013-09-10",\n        "release_date_precision" : "day",\n        "total_tracks" : 11,\n        "type" : "album",\n        "uri" : "spotify:album:1fOIkbQO1zU1rO3GLIGJBH"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/6S0dmVVn4udvppDhZIWxCr"\n        },\n        "href" : "https://api.spotify.com/v1/artists/6S0dmVVn4udvppDhZIWxCr",\n        "id" : "6S0dmVVn4udvppDhZIWxCr",\n        "name" : "Sean Kingston",\n        "type" : "artist",\n        "uri" : "spotify:artist:6S0dmVVn4udvppDhZIWxCr"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/7bXgB6jMjp9ATFy66eO08Z"\n        },\n        "href" : "https://api.spotify.com/v1/artists/7bXgB6jMjp9ATFy66eO08Z",\n        "id" : "7bXgB6jMjp9ATFy66eO08Z",\n        "name" : "Chris Brown",\n        "type" : "artist",\n        "uri" : "spotify:artist:7bXgB6jMjp9ATFy66eO08Z"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/137W8MRPWKqSmrBGDBFSop"\n        },\n        "href" : "https://api.spotify.com/v1/artists/137W8MRPWKqSmrBGDBFSop",\n        "id" : "137W8MRPWKqSmrBGDBFSop",\n        "name" : "Wiz Khalifa",\n        "type" : "artist",\n        "uri" : "spotify:artist:137W8MRPWKqSmrBGDBFSop"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 253453,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "USSM11300871"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/3bwCMbwDZVtvJDnUTQIdCX"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/3bwCMbwDZVtvJDnUTQIdCX",\n      "id" : "3bwCMbwDZVtvJDnUTQIdCX",\n      "is_local" : false,\n      "name" : "Beat It (feat. Chris Brown & Wiz Khalifa)",\n      "popularity" : 66,\n      "preview_url" : "https://p.scdn.co/mp3-preview/1d81ddec1bda16846ba1813c202751fc4a851a63?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 2,\n      "type" : "track",\n      "uri" : "spotify:track:3bwCMbwDZVtvJDnUTQIdCX"\n    }, {\n      "album" : {\n        "album_type" : "album",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/0LyfQWJT6nXafLPZqxe9Of"\n          },\n          "href" : "https://api.spotify.com/v1/artists/0LyfQWJT6nXafLPZqxe9Of",\n          "id" : "0LyfQWJT6nXafLPZqxe9Of",\n          "name" : "Various Artists",\n          "type" : "artist",\n          "uri" : "spotify:artist:0LyfQWJT6nXafLPZqxe9Of"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/5sKLuk1cTLgH9lrt148OBd"\n        },\n        "href" : "https://api.spotify.com/v1/albums/5sKLuk1cTLgH9lrt148OBd",\n        "id" : "5sKLuk1cTLgH9lrt148OBd",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b2737bc2872cd6ef45fa2dfc513c",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e027bc2872cd6ef45fa2dfc513c",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d000048517bc2872cd6ef45fa2dfc513c",\n          "width" : 64\n        } ],\n        "name" : "Jawn to the Head Yo",\n        "release_date" : "2021-03-26",\n        "release_date_precision" : "day",\n        "total_tracks" : 21,\n        "type" : "album",\n        "uri" : "spotify:album:5sKLuk1cTLgH9lrt148OBd"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/6CGSqnTOGLYI7ZWKMcaNS5"\n        },\n        "href" : "https://api.spotify.com/v1/artists/6CGSqnTOGLYI7ZWKMcaNS5",\n        "id" : "6CGSqnTOGLYI7ZWKMcaNS5",\n        "name" : "DJ Scarzz",\n        "type" : "artist",\n        "uri" : "spotify:artist:6CGSqnTOGLYI7ZWKMcaNS5"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 206097,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "QM22L2100806"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/13jDUXklCu8AYWzufW7LMq"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/13jDUXklCu8AYWzufW7LMq",\n      "id" : "13jDUXklCu8AYWzufW7LMq",\n      "is_local" : false,\n      "name" : "Calling My Phone",\n      "popularity" : 0,\n      "preview_url" : "https://p.scdn.co/mp3-preview/799cc898d6a0a359bdb6f88c88fb3f99c8357b38?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 5,\n      "type" : "track",\n      "uri" : "spotify:track:13jDUXklCu8AYWzufW7LMq"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/6jGMq4yGs7aQzuGsMgVgZR"\n          },\n          "href" : "https://api.spotify.com/v1/artists/6jGMq4yGs7aQzuGsMgVgZR",\n          "id" : "6jGMq4yGs7aQzuGsMgVgZR",\n          "name" : "Lil Tjay",\n          "type" : "artist",\n          "uri" : "spotify:artist:6jGMq4yGs7aQzuGsMgVgZR"\n        }, {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/4IVAbR2w4JJNJDDRFP3E83"\n          },\n          "href" : "https://api.spotify.com/v1/artists/4IVAbR2w4JJNJDDRFP3E83",\n          "id" : "4IVAbR2w4JJNJDDRFP3E83",\n          "name" : "6LACK",\n          "type" : "artist",\n          "uri" : "spotify:artist:4IVAbR2w4JJNJDDRFP3E83"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/0Fa2FLw7jMeao6UzKE1VoN"\n        },\n        "href" : "https://api.spotify.com/v1/albums/0Fa2FLw7jMeao6UzKE1VoN",\n        "id" : "0Fa2FLw7jMeao6UzKE1VoN",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b2735fead3083c55648b09d68807",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e025fead3083c55648b09d68807",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d000048515fead3083c55648b09d68807",\n          "width" : 64\n        } ],\n        "name" : "Calling My Phone",\n        "release_date" : "2021-02-10",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:0Fa2FLw7jMeao6UzKE1VoN"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/6jGMq4yGs7aQzuGsMgVgZR"\n        },\n        "href" : "https://api.spotify.com/v1/artists/6jGMq4yGs7aQzuGsMgVgZR",\n        "id" : "6jGMq4yGs7aQzuGsMgVgZR",\n        "name" : "Lil Tjay",\n        "type" : "artist",\n        "uri" : "spotify:artist:6jGMq4yGs7aQzuGsMgVgZR"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/4IVAbR2w4JJNJDDRFP3E83"\n        },\n        "href" : "https://api.spotify.com/v1/artists/4IVAbR2w4JJNJDDRFP3E83",\n        "id" : "4IVAbR2w4JJNJDDRFP3E83",\n        "name" : "6LACK",\n        "type" : "artist",\n        "uri" : "spotify:artist:4IVAbR2w4JJNJDDRFP3E83"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 205458,\n      "explicit" : false,\n      "external_ids" : {\n        "isrc" : "USSM12100389"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/08QAkBRyWLUQ3UniIyMFtP"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/08QAkBRyWLUQ3UniIyMFtP",\n      "id" : "08QAkBRyWLUQ3UniIyMFtP",\n      "is_local" : false,\n      "name" : "Calling My Phone",\n      "popularity" : 67,\n      "preview_url" : "https://p.scdn.co/mp3-preview/663d287d2542744070c60229b9d95da50dfa26d1?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:08QAkBRyWLUQ3UniIyMFtP"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/1EGp7XHKC6Gyi35G9AfYKf"\n          },\n          "href" : "https://api.spotify.com/v1/artists/1EGp7XHKC6Gyi35G9AfYKf",\n          "id" : "1EGp7XHKC6Gyi35G9AfYKf",\n          "name" : "Rondo2raww",\n          "type" : "artist",\n          "uri" : "spotify:artist:1EGp7XHKC6Gyi35G9AfYKf"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/51XgyVk75JHDtWGSzjK9Cu"\n        },\n        "href" : "https://api.spotify.com/v1/albums/51XgyVk75JHDtWGSzjK9Cu",\n        "id" : "51XgyVk75JHDtWGSzjK9Cu",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b2737419a4b391142e385fca603d",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e027419a4b391142e385fca603d",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d000048517419a4b391142e385fca603d",\n          "width" : 64\n        } ],\n        "name" : "Calling My Phone (Remix)",\n        "release_date" : "2021-03-22",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:51XgyVk75JHDtWGSzjK9Cu"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/1EGp7XHKC6Gyi35G9AfYKf"\n        },\n        "href" : "https://api.spotify.com/v1/artists/1EGp7XHKC6Gyi35G9AfYKf",\n        "id" : "1EGp7XHKC6Gyi35G9AfYKf",\n        "name" : "Rondo2raww",\n        "type" : "artist",\n        "uri" : "spotify:artist:1EGp7XHKC6Gyi35G9AfYKf"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 201142,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "QZF8N2118256"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/528R4JR48GJPxsSd8njyAX"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/528R4JR48GJPxsSd8njyAX",\n      "id" : "528R4JR48GJPxsSd8njyAX",\n      "is_local" : false,\n      "name" : "Calling My Phone (Remix)",\n      "popularity" : 0,\n      "preview_url" : "https://p.scdn.co/mp3-preview/ef488169e919b0d2d150fd4ef5e1c273f6a2ce91?cid=e348b05a9d5b404084480a58c25dd36e",\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:528R4JR48GJPxsSd8njyAX"\n    }, {\n      "album" : {\n        "album_type" : "single",\n        "artists" : [ {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/1fctva4kpRbg2k3v7kwRuS"\n          },\n          "href" : "https://api.spotify.com/v1/artists/1fctva4kpRbg2k3v7kwRuS",\n          "id" : "1fctva4kpRbg2k3v7kwRuS",\n          "name" : "Rvssian",\n          "type" : "artist",\n          "uri" : "spotify:artist:1fctva4kpRbg2k3v7kwRuS"\n        }, {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/5zctI4wO9XSKS8XwcnqEHk"\n          },\n          "href" : "https://api.spotify.com/v1/artists/5zctI4wO9XSKS8XwcnqEHk",\n          "id" : "5zctI4wO9XSKS8XwcnqEHk",\n          "name" : "Lil Mosey",\n          "type" : "artist",\n          "uri" : "spotify:artist:5zctI4wO9XSKS8XwcnqEHk"\n        }, {\n          "external_urls" : {\n            "spotify" : "https://open.spotify.com/artist/6jGMq4yGs7aQzuGsMgVgZR"\n          },\n          "href" : "https://api.spotify.com/v1/artists/6jGMq4yGs7aQzuGsMgVgZR",\n          "id" : "6jGMq4yGs7aQzuGsMgVgZR",\n          "name" : "Lil Tjay",\n          "type" : "artist",\n          "uri" : "spotify:artist:6jGMq4yGs7aQzuGsMgVgZR"\n        } ],\n        "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/album/7oEKNLjZtm5UEIezuR2Hfy"\n        },\n        "href" : "https://api.spotify.com/v1/albums/7oEKNLjZtm5UEIezuR2Hfy",\n        "id" : "7oEKNLjZtm5UEIezuR2Hfy",\n        "images" : [ {\n          "height" : 640,\n          "url" : "https://i.scdn.co/image/ab67616d0000b2731b382fb4a70157f7b47af1ed",\n          "width" : 640\n        }, {\n          "height" : 300,\n          "url" : "https://i.scdn.co/image/ab67616d00001e021b382fb4a70157f7b47af1ed",\n          "width" : 300\n        }, {\n          "height" : 64,\n          "url" : "https://i.scdn.co/image/ab67616d000048511b382fb4a70157f7b47af1ed",\n          "width" : 64\n        } ],\n        "name" : "Only The Team (with Lil Mosey & Lil Tjay)",\n        "release_date" : "2020-03-11",\n        "release_date_precision" : "day",\n        "total_tracks" : 1,\n        "type" : "album",\n        "uri" : "spotify:album:7oEKNLjZtm5UEIezuR2Hfy"\n      },\n      "artists" : [ {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/1fctva4kpRbg2k3v7kwRuS"\n        },\n        "href" : "https://api.spotify.com/v1/artists/1fctva4kpRbg2k3v7kwRuS",\n        "id" : "1fctva4kpRbg2k3v7kwRuS",\n        "name" : "Rvssian",\n        "type" : "artist",\n        "uri" : "spotify:artist:1fctva4kpRbg2k3v7kwRuS"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/5zctI4wO9XSKS8XwcnqEHk"\n        },\n        "href" : "https://api.spotify.com/v1/artists/5zctI4wO9XSKS8XwcnqEHk",\n        "id" : "5zctI4wO9XSKS8XwcnqEHk",\n        "name" : "Lil Mosey",\n        "type" : "artist",\n        "uri" : "spotify:artist:5zctI4wO9XSKS8XwcnqEHk"\n      }, {\n        "external_urls" : {\n          "spotify" : "https://open.spotify.com/artist/6jGMq4yGs7aQzuGsMgVgZR"\n        },\n        "href" : "https://api.spotify.com/v1/artists/6jGMq4yGs7aQzuGsMgVgZR",\n        "id" : "6jGMq4yGs7aQzuGsMgVgZR",\n        "name" : "Lil Tjay",\n        "type" : "artist",\n        "uri" : "spotify:artist:6jGMq4yGs7aQzuGsMgVgZR"\n      } ],\n      "available_markets" : [ "AD", "AE", "AG", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH", "BI", "BJ", "BN", "BO", "BR", "BS", "BT", "BW", "BY", "BZ", "CA", "CH", "CI", "CL", "CM", "CO", "CR", "CV", "CW", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ES", "FI", "FJ", "FM", "FR", "GA", "GB", "GD", "GE", "GH", "GM", "GN", "GQ", "GR", "GT", "GW", "GY", "HK", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM", "KN", "KR", "KW", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS", "LT", "LU", "LV", "MA", "MC", "MD", "ME", "MG", "MH", "MK", "ML", "MN", "MO", "MR", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA", "NE", "NG", "NI", "NL", "NO", "NP", "NR", "NZ", "OM", "PA", "PE", "PG", "PH", "PK", "PL", "PS", "PT", "PW", "PY", "QA", "RO", "RS", "RU", "RW", "SA", "SB", "SC", "SE", "SG", "SI", "SK", "SL", "SM", "SN", "SR", "ST", "SV", "SZ", "TD", "TG", "TH", "TL", "TN", "TO", "TR", "TT", "TV", "TW", "TZ", "UA", "UG", "US", "UY", "UZ", "VC", "VN", "VU", "WS", "XK", "ZA", "ZM", "ZW" ],\n      "disc_number" : 1,\n      "duration_ms" : 168979,\n      "explicit" : true,\n      "external_ids" : {\n        "isrc" : "USUM72005199"\n      },\n      "external_urls" : {\n        "spotify" : "https://open.spotify.com/track/6UHfW9PmGAUjIVeIkPzPQ2"\n      },\n      "href" : "https://api.spotify.com/v1/tracks/6UHfW9PmGAUjIVeIkPzPQ2",\n      "id" : "6UHfW9PmGAUjIVeIkPzPQ2",\n      "is_local" : false,\n      "name" : "Only The Team (with Lil Mosey & Lil Tjay)",\n      "popularity" : 68,\n      "preview_url" : null,\n      "track_number" : 1,\n      "type" : "track",\n      "uri" : "spotify:track:6UHfW9PmGAUjIVeIkPzPQ2"\n    } ],\n    "limit" : 25,\n    "next" : "https://api.spotify.com/v1/search?query=calling+my+phone&type=track&offset=25&limit=25",\n    "offset" : 0,\n    "previous" : null,\n    "total" : 4274\n  }\n}',
          responseHeaders: {
            "access-control-allow-credentials": "true",
            "access-control-allow-headers":
              "Accept, App-Platform, Authorization, Content-Type, Origin, Retry-After, Spotify-App-Version, X-Cloud-Trace-Context, client-token, content-access-token",
            "access-control-allow-methods":
              "GET, POST, OPTIONS, PUT, DELETE, PATCH",
            "access-control-allow-origin": "*",
            "access-control-max-age": "604800",
            "alt-svc": "clear",
            "cache-control": "public, max-age=7200",
            "content-encoding": "gzip",
            "content-length": "8744",
            "content-type": "application/json; charset=utf-8",
            date: "Sun, 28 Mar 2021 18:17:22 GMT",
            server: "envoy",
            "strict-transport-security": "max-age=31536000",
            via: "HTTP/2 edgeproxy, 1.1 google",
            "x-content-type-options": "nosniff",
            "x-robots-tag": "noindex, nofollow",
          },
          status: 200,
          requestMs: 197.113037109375,
        },
      ],
    },
  },
};

export let traces = [spotifyChainTrace0];
