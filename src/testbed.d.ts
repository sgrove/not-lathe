type executeNewChainParams = {};

type executeNewChainReturn = {
  errors: Array<any>,
  ListeningTo: {
    data: {
      spotify: {
        me: {
          player: {
            item: {
              album: {
                id: string,
                name: string,
              },
              name: string,
            },
          },
        },
      },
    },
    errors: Array<any>,
  },
  PushToList: {
    data: {
      firebase: {
        pushData: {
          json: any,
        },
      },
    },
    errors: Array<any>,
  },
  SalesforceLeadsQuery: {
    data: {
      salesforce: {
        leads: {
          nodes: Array<{
            firstName: string,
            lastName: string,
            email: string,
            createdDate: string,
          }>,
        },
      },
    },
    errors: Array<any>,
  },
};

export function executeNewChain(
  input: executeNewChainParams
): Promise<executeNewChainReturn> {}

type fetchMatyChainParams = {};

type fetchMatyChainReturn = { errors: Array<any> };

export function fetchMatyChain(
  input: fetchMatyChainParams
): Promise<fetchMatyChainReturn> {}

type subscribeToNpmStuffParams = {
  databaseName: string,
  path: string,
  data: any,
};

type subscribeToNpmStuffReturn = {
  errors: Array<any>,
  NewPackages: {
    data: {
      npm: {
        allPublishActivity: {
          package: {
            name: string,
            homepage: string,
            description: string,
            distTags: {
              latest: {
                versionString: string,
              },
            },
          },
        },
      },
    },
    errors: Array<any>,
  },
  PushToList: {
    data: {
      firebase: {
        pushData: {
          json: any,
        },
      },
    },
    errors: Array<any>,
  },
};

export function subscribeToNpmStuff(
  input: subscribeToNpmStuffParams
): Promise<subscribeToNpmStuffReturn> {}

type fetchTypeTestParams = {};

type fetchTypeTestReturn = { errors: Array<any> };

export function fetchTypeTest(
  input: fetchTypeTestParams
): Promise<fetchTypeTestReturn> {}

type executeSpotifyGetLuckyParams = {
  query: string,
  message: string,
  name: string,
  positionMs: number,
};

type executeSpotifyGetLuckyReturn = {
  errors: Array<any>,
  Search: {
    data: {
      spotify: {
        search: {
          tracks: Array<{
            name: string,
            id: string,
            album: {
              name: string,
              id: string,
              images: Array<{
                height: number,
                url: string,
                width: number,
              }>,
              href: string,
            },
            href: string,
          }>,
        },
      },
    },
    errors: Array<any>,
  },
  ComputeType: {
    data: {
      oneGraph: {
        message: any,
        name: any,
        positionMs: any,
      },
    },
    errors: Array<any>,
  },
  SetSlackStatus: {
    data: {
      slack: {
        makeRestCall: {
          post: {
            jsonBody: any,
          },
        },
      },
    },
    errors: Array<any>,
  },
  SpotifyPlayTrack: {
    data: {
      spotify: {
        playTrack: {
          player: {
            isPlaying: boolean,
            item: {
              name: string,
              album: {
                name: string,
              },
            },
          },
        },
      },
    },
    errors: Array<any>,
  },
};

/**
 * Let's do this!
 */
export function executeSpotifyGetLucky(
  input: executeSpotifyGetLuckyParams
): Promise<executeSpotifyGetLuckyReturn> {}

type fetchSiteMonitoringChainParams = { url: string };

type fetchSiteMonitoringChainReturn = {
  errors: Array<any>,
  CheckSiteLinks: {
    data: {
      descuri: {
        other: Array<{
          uri: string,
        }>,
      },
    },
    errors: Array<any>,
  },
  ComputeType: {
    data: {
      oneGraph: {
        message: any,
      },
    },
    errors: Array<any>,
  },
};

export function fetchSiteMonitoringChain(
  input: fetchSiteMonitoringChainParams
): Promise<fetchSiteMonitoringChainReturn> {}

type executeSpotifyGetLuckyParams = {
  query: string,
  message: string,
  name: string,
  positionMs: number,
};

type executeSpotifyGetLuckyReturn = {
  errors: Array<any>,
  Search: {
    data: {
      spotify: {
        search: {
          tracks: Array<{
            name: string,
            id: string,
            album: {
              name: string,
              id: string,
              images: Array<{
                height: number,
                url: string,
                width: number,
              }>,
              href: string,
            },
            href: string,
          }>,
        },
      },
    },
    errors: Array<any>,
  },
  ComputeType: {
    data: {
      oneGraph: {
        message: any,
        name: any,
        positionMs: any,
      },
    },
    errors: Array<any>,
  },
  SetSlackStatus: {
    data: {
      slack: {
        makeRestCall: {
          post: {
            jsonBody: any,
          },
        },
      },
    },
    errors: Array<any>,
  },
  SpotifyPlayTrack: {
    data: {
      spotify: {
        playTrack: {
          player: {
            isPlaying: boolean,
            item: {
              name: string,
              album: {
                name: string,
              },
            },
          },
        },
      },
    },
    errors: Array<any>,
  },
};

/**
 * Let's do this!
 */
export function executeSpotifyGetLucky(
  input: executeSpotifyGetLuckyParams
): Promise<executeSpotifyGetLuckyReturn> {}

type executePushFilesToBranchParams = {
  owner: string,
  name: string,
  branch: string,
  message: string,
  treeFiles: any,
  acceptOverrides: boolean,
};

type executePushFilesToBranchReturn = {
  errors: Array<any>,
  CreateTree: {
    data: {
      gitHub: {
        makeRestCall: {
          post: {
            response: {
              statusCode: number,
            },
            jsonBody: any,
          },
        },
      },
    },
    errors: Array<any>,
  },
  DefaultBranchRef: {
    data: {
      gitHub: {
        repository: {
          id: string,
          defaultBranchRef: {
            id: string,
            name: string,
            target: {
              id: string,
              oid: string,
              history: {
                edges: Array<{
                  node: {
                    tree: {
                      entries: Array<{
                        name: string,
                        path: string,
                        oid: string,
                        object: {
                          id: string,
                          entries: Array<{
                            name: string,
                            path: string,
                            oid: string,
                          }>,
                        },
                      }>,
                    },
                  },
                }>,
              },
              tree: {
                id: string,
                oid: string,
              },
            },
          },
        },
      },
    },
    errors: Array<any>,
  },
  UserInput: {
    data: {
      oneGraph: {
        owner: any,
        name: any,
        branch: any,
        message: any,
        treeFiles: any,
        acceptOverrides: any,
      },
    },
    errors: Array<any>,
  },
  CreateRef: {
    data: {
      gitHub: {
        createRef: {
          ref: {
            id: string,
            name: string,
            target: {
              id: string,
              oid: string,
              history: {
                edges: Array<{
                  node: {
                    tree: {
                      entries: Array<{
                        name: string,
                        path: string,
                        oid: string,
                        object: {
                          id: string,
                          entries: Array<{
                            name: string,
                            path: string,
                            oid: string,
                          }>,
                        },
                      }>,
                    },
                  },
                }>,
              },
              tree: {
                id: string,
                oid: string,
              },
            },
          },
        },
      },
    },
    errors: Array<any>,
  },
  CheckIfRefExists: {
    data: {
      gitHub: {
        repository: {
          id: string,
          ref: {
            id: string,
            name: string,
            target: {
              id: string,
              oid: string,
              history: {
                edges: Array<{
                  node: {
                    tree: {
                      entries: Array<{
                        name: string,
                        path: string,
                        oid: string,
                        object: {
                          id: string,
                          entries: Array<{
                            name: string,
                            path: string,
                            oid: string,
                          }>,
                        },
                      }>,
                    },
                  },
                }>,
              },
              tree: {
                id: string,
                oid: string,
              },
            },
          },
        },
      },
    },
    errors: Array<any>,
  },
  FilesOnRef: {
    data: {
      gitHub: {
        repository: {
          id: string,
          ref: {
            id: string,
            name: string,
            target: {
              id: string,
              oid: string,
              history: {
                edges: Array<{
                  node: {
                    tree: {
                      entries: Array<{
                        name: string,
                        path: string,
                        oid: string,
                        object: {
                          id: string,
                          entries: Array<{
                            name: string,
                            path: string,
                            oid: string,
                          }>,
                        },
                      }>,
                    },
                  },
                }>,
              },
              tree: {
                id: string,
                oid: string,
              },
            },
          },
        },
      },
    },
    errors: Array<any>,
  },
  CreateCommit: {
    data: {
      gitHub: {
        makeRestCall: {
          post: {
            response: {
              statusCode: number,
            },
            jsonBody: any,
          },
        },
      },
    },
    errors: Array<any>,
  },
  UpdateRef: {
    data: {
      gitHub: {
        updateRef: {
          clientMutationId: string,
          ref: {
            name: string,
            id: string,
            target: {
              oid: string,
              id: string,
            },
          },
        },
      },
    },
    errors: Array<any>,
  },
};

export function executePushFilesToBranch(
  input: executePushFilesToBranchParams
): Promise<executePushFilesToBranchReturn> {}
