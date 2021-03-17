// Generated by ReScript, PLEASE EDIT WITH CARE

import * as OneGraphAuth from "./OneGraphAuth.js";

function stringOfService(service) {
  if (service) {
    return "github";
  } else {
    return "eggheadio";
  }
}

var logout = OneGraphAuth.logout;

var authHeaders = OneGraphAuth.authHeaders;

var clearToken = OneGraphAuth.clearToken;

var distinctServices = OneGraphAuth.distinctServices;

export {
  logout ,
  authHeaders ,
  clearToken ,
  distinctServices ,
  stringOfService ,
  
}
/* No side effect */
