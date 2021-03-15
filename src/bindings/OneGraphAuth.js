// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Js_dict from "bs-platform/lib/es6/js_dict.mjs";
import * as Js_null_undefined from "bs-platform/lib/es6/js_null_undefined.mjs";

function findMissingAuthServices(auth, resultIsh) {
  return auth.findMissingAuthServices(resultIsh);
}

function logout(auth, service, foreignUserId, param) {
  return auth.logout(service, Js_null_undefined.fromOption(foreignUserId));
}

function authHeaders(auth) {
  var headers = auth.authHeaders();
  return Js_dict.get(headers, "Authentication");
}

function clearToken(auth) {
  var appId = auth.appId;
  var storageKey = "oneGraph:" + appId;
  localStorage.removeItem(storageKey);
  auth.setToken(Js_null_undefined.fromOption("{}"));
  
}

function distinctServices(_services) {
  return ([...new Set(_services)]);
}

export {
  findMissingAuthServices ,
  logout ,
  authHeaders ,
  clearToken ,
  distinctServices ,
  
}
/* No side effect */