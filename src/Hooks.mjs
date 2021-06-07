// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Curry from "rescript/lib/es6/curry.js";
import * as React from "react";

function useLeadingDebounce(value, delay) {
  var match = React.useState(function () {
        return value;
      });
  var setDebouncedValue = match[1];
  var match$1 = React.useState(function () {
        return true;
      });
  var setAfterSleep = match$1[1];
  var afterSleep = match$1[0];
  React.useEffect((function () {
          if (afterSleep) {
            Curry._1(setDebouncedValue, (function (param) {
                    return value;
                  }));
            Curry._1(setAfterSleep, (function (param) {
                    return false;
                  }));
          }
          var handler = setTimeout((function (param) {
                  Curry._1(setDebouncedValue, (function (param) {
                          return value;
                        }));
                  return Curry._1(setAfterSleep, (function (param) {
                                return true;
                              }));
                }), delay);
          return (function (param) {
                    clearTimeout(handler);
                    
                  });
        }), [
        value,
        delay
      ]);
  return match[0];
}

function useThrottle(callback, interval) {
  var match = React.useState(function () {
        return false;
      });
  var setPendingFire = match[1];
  React.useEffect((function () {
          var handler = setTimeout((function (param) {
                  Curry._1(callback, undefined);
                  return Curry._1(setPendingFire, (function (param) {
                                return false;
                              }));
                }), interval);
          return (function (param) {
                    clearTimeout(handler);
                    
                  });
        }), [
        match[0],
        callback,
        interval
      ]);
  return function (param) {
    return Curry._1(setPendingFire, (function (param) {
                  return true;
                }));
  };
}

export {
  useLeadingDebounce ,
  useThrottle ,
  
}
/* react Not a pure module */