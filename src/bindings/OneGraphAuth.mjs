// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Dom_storage from "rescript/lib/es6/dom_storage.js";
import * as OnegraphAuth from "onegraph-auth";
import * as Js_null_undefined from "rescript/lib/es6/js_null_undefined.js";

function create(options) {
  var match = typeof window === "undefined" ? undefined : window;
  if (match !== undefined) {
    return Caml_option.some(new OnegraphAuth.OneGraphAuth(options));
  }
  
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
  Dom_storage.removeItem(storageKey, localStorage);
  auth.setToken("{}");
  
}

function distinctServices(_services) {
  return ([...new Set(_services)]);
}

export {
  create ,
  logout ,
  authHeaders ,
  clearToken ,
  distinctServices ,
  
}
/* onegraph-auth Not a pure module */