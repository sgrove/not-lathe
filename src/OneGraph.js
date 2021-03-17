import OneGraphAuth from "onegraph-auth";
import { isSsr } from "./common";
import { ONE_GRAPH_APP_ID } from "./constants";
import ErrorPage from "next/error";

const PERSIST_QUERY_TOKEN = "___";

// This setup is only needed once per application
export async function basicFetchOneGraph(
  appId,
  accessToken,
  operationsDoc,
  variables,
  operationName
) {
  const authHeaders = !!accessToken
    ? { Authorization: `Bearer ${accessToken}` }
    : {};

  const result = await fetch(
    `https://serve.onegraph.com/graphql?app_id=${appId}`,
    {
      method: "POST",
      headers: { ...authHeaders, "Content-Type": "application/json" },
      body: JSON.stringify({
        query: operationsDoc,
        variables: variables,
        operationName: operationName,
      }),
    }
  );

  const json = await result.json();

  if (!!json.errors) {
    console.warn(`Errors in GraphQL for "${operationName}":`, json.errors);
  }

  return json;
}

export function fetchOneGraph(auth, operationsDoc, operationName, variables) {
  return basicFetchOneGraph(
    auth?.appId,
    auth?.accessToken()?.accessToken,
    operationsDoc,
    variables,
    operationName
  );
}

export async function basicFetchOneGraphPersistedQuery(
  appId,
  accessToken,
  docId,
  variables,
  operationName
) {
  const authHeaders = !!accessToken
    ? { Authorization: `Bearer ${accessToken}` }
    : {};

  const result = await fetch(
    `https://serve.onegraph.com/graphql?app_id=${appId}`,
    {
      method: "POST",
      headers: { ...authHeaders, "Content-Type": "application/json" },
      body: JSON.stringify({
        doc_id: docId,
        variables: variables,
        operationName: operationName,
      }),
    }
  );

  const json = await result.json();

  if (!!json.errors) {
    console.warn(`Errors in GraphQL for "${operationName}":`, json.errors);
  }

  return json;
}

export function fetchOneGraphPersistedQuery(
  auth,
  docId,
  operationName,
  variables
) {
  return basicFetchOneGraphPersistedQuery(
    auth?.appId,
    auth?.accessToken()?.accessToken,
    docId,
    variables,
    operationName
  );
}

export function checkErrorForCorsConfigurationRequired(error) {
  if (error?.message?.match("not allowed by Access-Control-Allow-Origin")) {
    return true;
  }
  return false;
}

export function checkErrorForMissingOneGraphAppId(error) {
  window.eeeerror = error;
  if (error?.message?.match("app_id must be a valid UUID")) {
    debugger;
    return true;
  }
  return false;
}

// export const _auth = isSsr
//   ? {
//       accessToken: () => null,
//     }
//   : new OneGraphAuth({
//       appId: ONE_GRAPH_APP_ID,
//       oneGraphOrigin: "https://serve.onegraph.com",
//     });

const atob = (str) => {
  return Buffer.from(str, "base64").toString("binary");
};

const persistQueryMutation = `
  mutation PersistQuery(
    # variables that the caller of the query can provide
    $freeVariables: [String!]
    # default variables for the query
    $fixedVariables: JSON
    # Your app's id
    $appId: String!
    # Optional access token ifK you want the caller of the query to use your auth
    $accessToken: String
    $query: String!
  ) {
    oneGraph {
      createPersistedQuery(
        input: {
          query: $query
          accessToken: $accessToken
          appId: $appId
          freeVariables: $freeVariables
        }
      ) {
        persistedQuery {
          id
        }
      }
    }
  }
`;

export function persistQuery(
  appId,
  persistQueryToken,
  queryToPersist,
  freeVariables,
  accessToken,
  fixedVariables,
  onComplete
) {
  fetch(`https://serve.onegraph.com/graphql?app_id=${appId}`, {
    method: "POST",
    headers: {
      Authorization: "Bearer " + persistQueryToken,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      query: persistQueryMutation,
      variables: {
        query: queryToPersist,
        // Allows the client to provide the "package" variable
        freeVariables: freeVariables || [],
        appId: appId,
        accessToken: accessToken,
        fixedVariables: fixedVariables,
      },
    }),
  })
    .then((resp) =>
      resp.json().then((json) => {
        onComplete(json);
      })
    )
    .catch((e) => console.error("Error saving query", e));
}
