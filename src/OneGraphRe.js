// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Curry from "bs-platform/lib/es6/curry.mjs";
import * as OneGraphJs from "./OneGraph.js";

function fetchOneGraph(prim, prim$1, prim$2, prim$3) {
  return OneGraphJs.fetchOneGraph(prim, prim$1, prim$2, prim$3);
}

function persistQuery(prim, prim$1, prim$2, prim$3, prim$4, prim$5, prim$6) {
  OneGraphJs.persistQuery(prim, prim$1, prim$2, prim$3, prim$4, prim$5, prim$6);
  
}

function basicFetchOneGraphPersistedQuery(prim, prim$1, prim$2, prim$3, prim$4) {
  return OneGraphJs.basicFetchOneGraphPersistedQuery(prim, prim$1, prim$2, prim$3, prim$4);
}

function fetchOneGraphPersistedQuery(prim, prim$1, prim$2, prim$3) {
  return OneGraphJs.fetchOneGraphPersistedQuery(prim, prim$1, prim$2, prim$3);
}

function friendlyOfProjectType(t) {
  if (typeof t === "number") {
    if (t !== 0) {
      return "Next.js";
    } else {
      return "Unknown";
    }
  } else if (t._0 === "any") {
    return "Netlify Site";
  } else {
    return "Next.js on Netlify";
  }
}

var _guessProjecType = (async function listRepositories(owner, name) {
let resp = await fetch("https://serve.onegraph.com/graphql?app_id=993a3e2d-de45-44fa-bff4-0c58c6150cbf",
  {
    method: "POST",
    "Content-Type": "application/json",
    body: JSON.stringify({
      "doc_id": "14d10e67-0c1f-473e-8959-696a9fb90963",
      "operationName": "ExecuteChainMutation_hello_onegraph_its_netlify",
      "variables": {"owner": owner, "name": name}
      }
    )
  }
)

let res = await resp.json()


const value = res?.data?.oneGraph?.executeChain?.results?.find(res => res?.request?.id === 'ProjectType')?.result?.[0]?.data?.oneGraph?.identity

console.log(owner, name, value, res)

return value
});

function guessProjecType(owner, name) {
  var __x = Curry._2(_guessProjecType, owner, name);
  return __x.then(function (result) {
              var typ;
              switch (result) {
                case "netlify/*" :
                    typ = {
                      _0: "any",
                      [Symbol.for("name")]: "Netlify"
                    };
                    break;
                case "netlify/next.js" :
                    typ = {
                      _0: "nextjs",
                      [Symbol.for("name")]: "Netlify"
                    };
                    break;
                case "next.js" :
                    typ = /* Nextjs */1;
                    break;
                case "unknown" :
                    typ = /* Unknown */0;
                    break;
                default:
                  typ = /* Unknown */0;
              }
              console.log(owner, name, friendlyOfProjectType(typ));
              return Promise.resolve(typ);
            });
}

var pushToRepo = (async function pushToRepo(variables){
const resp = await fetch("https://serve.onegraph.com/graphql?app_id=993a3e2d-de45-44fa-bff4-0c58c6150cbf",
  {
    method: "POST",
    "Content-Type": "application/json",
    body: JSON.stringify({
      "doc_id": "93e83185-a2b3-4b20-9cfd-34d2d0bb2e91",
      "operationName": "ExecuteChainMutation_og_studio_dev_chain",
      "variables": variables
      }
    )
  }
)

let res = await resp.json()

return res
});

var GitHub = {
  friendlyOfProjectType: friendlyOfProjectType,
  _guessProjecType: _guessProjecType,
  guessProjecType: guessProjecType,
  pushToRepo: pushToRepo
};

export {
  fetchOneGraph ,
  persistQuery ,
  basicFetchOneGraphPersistedQuery ,
  fetchOneGraphPersistedQuery ,
  GitHub ,
  
}
/* _guessProjecType Not a pure module */
