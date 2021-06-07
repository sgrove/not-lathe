// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Icons from "../Icons.mjs";
import * as React from "react";

function AudioStreamPlayer(Props) {
  var presence = Props.presence;
  var level = presence.audioVolumeLevel;
  return React.createElement(React.Fragment, undefined, level !== undefined ? React.createElement(Icons.Volume.Auto.make, {
                    className: "inline-block",
                    color: presence.color,
                    level: level
                  }) : React.createElement(Icons.Volume.Mute.make, {
                    className: "inline-block",
                    color: presence.color
                  }));
}

var make = AudioStreamPlayer;

export {
  make ,
  
}
/* Icons Not a pure module */
