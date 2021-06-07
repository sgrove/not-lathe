// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Yjs from "../bindings/Yjs.mjs";
import * as Yjs$1 from "yjs";
import * as Curry from "rescript/lib/es6/curry.js";
import * as React from "react";
import * as YWebrtc from "y-webrtc";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Belt_HashMapString from "rescript/lib/es6/belt_HashMapString.js";

var globalConnectionState = Belt_HashMapString.make(17);

var globalAudioConnectionState = Belt_HashMapString.make(17);

function setLocalStateField(provider, field, value) {
  provider.awareness.setLocalStateField(field, value);
  
}

var encodeUint8Array = (function encodeUint8Array(u8) {
  return btoa(String.fromCharCode.apply(null, u8));
});

var decodeUint8Array = (function decodeUint8Array(str) {
  return new Uint8Array(atob(str).split('').map(function (c) { return c.charCodeAt(0); }));
});

function idempotentCreateChannel(id, concurrentSource, onPeerAdded, localUser, onPeerAudioStream, onSynced, onPeerRemoved, onSignaled, onProviderStream, color, param) {
  var channel = Belt_HashMapString.get(globalConnectionState, id);
  if (channel !== undefined) {
    return channel;
  }
  var update = decodeUint8Array(concurrentSource);
  var ydocument = new Yjs$1.Doc();
  Yjs$1.applyUpdate(ydocument, update);
  var yprovider = new YWebrtc.WebrtcProvider(id, ydocument, {
        maxConns: 20
      });
  Belt_Array.forEach([
        [
          "name",
          localUser
        ],
        [
          "color",
          color
        ]
      ], (function (param) {
          yprovider.awareness.setLocalStateField(param[0], param[1]);
          
        }));
  yprovider.on("synced", (function (update, origin, other) {
          return Belt_Option.forEach(onSynced, (function (onSynced) {
                        return Curry._3(onSynced, update, origin, other);
                      }));
        }));
  yprovider.on("connect", (function (args, param, param$1) {
          console.log("Provider connected! ", args);
          
        }));
  yprovider.on("peers", (function ($$event) {
          Belt_Array.forEach($$event.removed, (function (peerId) {
                  var connection = Yjs.WebRTC.getConnection(yprovider, peerId);
                  var peer = Belt_Option.map(connection, (function (connection) {
                          return connection.peer;
                        }));
                  return Belt_Option.forEach(peer, (function (peer) {
                                return Belt_Option.forEach(onPeerRemoved, (function (onPeerRemoved) {
                                              return Curry._3(onPeerRemoved, yprovider, id, peer);
                                            }));
                              }));
                }));
          return Belt_Array.forEach($$event.added, (function (peerId) {
                        var connection = Yjs.WebRTC.getConnection(yprovider, peerId);
                        var peer = Belt_Option.map(connection, (function (connection) {
                                return connection.peer;
                              }));
                        return Belt_Option.forEach(peer, (function (peer) {
                                      Curry._3(onPeerAdded, yprovider, id, peer);
                                      peer.on("stream", (function (stream) {
                                              return Curry._5(onPeerAudioStream, yprovider, id, peer, peerId, stream);
                                            }));
                                      
                                    }));
                      }));
        }));
  yprovider.on("signal", (function (update, origin, other) {
          return Belt_Option.forEach(onSignaled, (function (onSignaled) {
                        return Curry._3(onSignaled, update, origin, other);
                      }));
        }));
  yprovider.on("stream", (function (update, origin, other) {
          return Belt_Option.forEach(onProviderStream, (function (onProviderStream) {
                        return Curry._3(onProviderStream, update, origin, other);
                      }));
        }));
  var sharedChannel = {
    document: ydocument,
    provider: yprovider
  };
  Belt_HashMapString.set(globalConnectionState, id, sharedChannel);
  return sharedChannel;
}

var context = React.createContext({
      getSharedChannel: (function (param, param$1) {
          
        }),
      globalState: Belt_HashMapString.make(17),
      updateLocalPosition: (function (param, param$1) {
          
        }),
      getSharedChannelState: (function (param) {
          
        }),
      vectorClock: -1.0,
      getAudioStream: (function (param) {
          
        }),
      getSharedMap: (function (param, param$1) {
          
        }),
      updateConnectSourceActionId: (function (param, param$1) {
          
        })
    });

var provider = context.Provider;

function CollaborationContext$Provider(Props) {
  var value = Props.value;
  var children = Props.children;
  return React.createElement(provider, {
              value: value,
              children: children
            });
}

var Provider = {
  provider: provider,
  make: CollaborationContext$Provider
};

export {
  globalConnectionState ,
  globalAudioConnectionState ,
  setLocalStateField ,
  encodeUint8Array ,
  decodeUint8Array ,
  idempotentCreateChannel ,
  context ,
  Provider ,
  
}
/* globalConnectionState Not a pure module */