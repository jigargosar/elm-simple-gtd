/*! @license Firebase v4.1.3
Build: rev-1234895
Terms: https://firebase.google.com/terms/ */

"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var RequestInfo = exports.RequestInfo = function RequestInfo(url, method,
/**
 * Returns the value with which to resolve the request's promise. Only called
 * if the request is successful. Throw from this function to reject the
 * returned Request's promise with the thrown error.
 * Note: The XhrIo passed to this function may be reused after this callback
 * returns. Do not keep a reference to it in any way.
 */
handler, timeout) {
  _classCallCheck(this, RequestInfo);

  this.url = url;
  this.method = method;
  this.handler = handler;
  this.timeout = timeout;
  this.urlParams = {};
  this.headers = {};
  this.body = null;
  this.errorHandler = null;
  /**
   * Called with the current number of bytes uploaded and total size (-1 if not
   * computable) of the request body (i.e. used to report upload progress).
   */
  this.progressCallback = null;
  this.successCodes = [200];
  this.additionalRetryCodes = [];
};
//# sourceMappingURL=requestinfo.js.map
