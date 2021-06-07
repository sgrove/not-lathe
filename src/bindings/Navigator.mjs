// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";

function getUserAudio(param) {
  return Belt_Option.map(Caml_option.undefined_to_opt(typeof navigator === "undefined" ? undefined : navigator), (function ($$navigator) {
                return $$navigator.mediaDevices.getUserMedia({
                            audio: true,
                            video: false
                          });
              }));
}

function getUserAudioAndVideo(param) {
  return Belt_Option.map(Caml_option.undefined_to_opt(typeof navigator === "undefined" ? undefined : navigator), (function ($$navigator) {
                return $$navigator.mediaDevices.getUserMedia({
                            audio: true,
                            video: true
                          });
              }));
}

var $$MediaDevices = {
  getUserAudio: getUserAudio,
  getUserAudioAndVideo: getUserAudioAndVideo
};

export {
  $$MediaDevices ,
  
}
/* No side effect */