const getIn = (x, path) => x;

export async function executeSpotifyGetLucky(params: {
  query: string;
  message: string;
  name: string;
  positionMs: number;
}): Promise<{
  Search: {
    data: {
      spotify: {
        search: {
          tracks: Array<{
            name: string;
            id: string;
            album: {
              name: string;
              id: string;
              images: Array<{
                height: number;
                url: string;
                width: number;
              }>;
              href: string;
            };
            href: string;
          }>;
        };
      };
    };
    errors: Array<any>;
  };
  ComputeType: {
    data: {
      oneGraph: {
        message: any;
        name: any;
        positionMs: any;
      };
    };
    errors: Array<any>;
  };
  SetSlackStatus: {
    data: {
      slack: {
        makeRestCall: {
          post: {
            jsonBody: any;
          };
        };
      };
    };
    errors: Array<any>;
  };
  SpotifyPlayTrack: {
    data: {
      spotify: {
        playTrack: {
          player: {
            isPlaying: boolean;
            item: {
              name: string;
              album: {
                name: string;
              };
            };
          };
        };
      };
    };
    errors: Array<any>;
  };
}> {
  const resp = await fetch(
    "https://serve.onegraph.com/graphql?app_id=4c1c8469-89fa-4995-ab5a-b22db4587381",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        doc_id: "TODO",
        operationName: "ExecuteChainMutation_spotifyGetLucky",
        variables: {
          query: params.query,
          message: params.message,
          name: params.name,
          positionMs: params.positionMs,
        },
      }),
    }
  );

  const json = await resp.json();

  const SearchResults = getIn(json, [
    "data",
    "oneGraph",
    "executeChain",
    "results",
  ]).map((result) => result?.["request"]?.["id"] == "Search")?.["result"]?.[0];
  const ComputeTypeResults = getIn(json, [
    "data",
    "oneGraph",
    "executeChain",
    "results",
  ]).map((result) => result?.["request"]?.["id"] == "ComputeType")?.[
    "result"
  ]?.[0];
  const SetSlackStatusResults = getIn(json, [
    "data",
    "oneGraph",
    "executeChain",
    "results",
  ]).map((result) => result?.["request"]?.["id"] == "SetSlackStatus")?.[
    "result"
  ]?.[0];
  const SpotifyPlayTrackResults = getIn(json, [
    "data",
    "oneGraph",
    "executeChain",
    "results",
  ]).map((result) => result?.["request"]?.["id"] == "SpotifyPlayTrack")?.[
    "result"
  ]?.[0];

  return {
    Search: SearchResults,
    ComputeType: ComputeTypeResults,
    SetSlackStatus: SetSlackStatusResults,
    SpotifyPlayTrack: SpotifyPlayTrackResults,
  };
}
