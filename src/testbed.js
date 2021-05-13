const { fetch } = require("fetch-ponyfill")({});

/**
 * What's this then?
 * @param {{a: string, b: number}} test - Some param
 */
export async function executeSpotifyGetLucky(params) {
  const resp = await fetch(
    "https://serve.onegraph.io/graphql?app_id=4c1c8469-89fa-4995-ab5a-b22db4587381",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        doc_id: "1e277abe-bd98-4def-b060-fe8a67533caf",
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

  const SearchResults = json?.data?.oneGraph?.executeChain?.results?.find(
    (result) => result?.request?.id === "Search"
  )?.result?.[0];
  const ComputeTypeResults = json?.data?.oneGraph?.executeChain?.results?.find(
    (result) => result?.request?.id === "ComputeType"
  )?.result?.[0];
  const SetSlackStatusResults = json?.data?.oneGraph?.executeChain?.results?.find(
    (result) => result?.request?.id === "SetSlackStatus"
  )?.result?.[0];
  const SpotifyPlayTrackResults = json?.data?.oneGraph?.executeChain?.results?.find(
    (result) => result?.request?.id === "SpotifyPlayTrack"
  )?.result?.[0];

  const allErrors = json?.data?.oneGraph?.executeChain?.results
    ?.map((step) => step?.result[0].errors)
    .flat()
    .filter(Boolean);

  return {
    errors: [...(json?.errors || []), ...(allErrors || [])],
    Search: SearchResults,
    ComputeType: ComputeTypeResults,
    SetSlackStatus: SetSlackStatusResults,
    SpotifyPlayTrack: SpotifyPlayTrackResults,
  };
}
