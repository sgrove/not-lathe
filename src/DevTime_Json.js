export const devJsonChain = {
  name: "og_studio_dev_chain",
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
  name: "new_chain",
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
  name: "new_chain",
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
  name: "new_chain",
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
