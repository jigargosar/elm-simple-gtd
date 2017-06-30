/*! @license Firebase v4.1.3
Build: rev-1234895
Terms: https://firebase.google.com/terms/ */

'use strict';

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.Observer = undefined;

var _type = require('./type');

var type = _interopRequireWildcard(_type);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } } /**
                                                                                                                                                          * Copyright 2017 Google Inc.
                                                                                                                                                          *
                                                                                                                                                          * Licensed under the Apache License, Version 2.0 (the "License");
                                                                                                                                                          * you may not use this file except in compliance with the License.
                                                                                                                                                          * You may obtain a copy of the License at
                                                                                                                                                          *
                                                                                                                                                          *   http://www.apache.org/licenses/LICENSE-2.0
                                                                                                                                                          *
                                                                                                                                                          * Unless required by applicable law or agreed to in writing, software
                                                                                                                                                          * distributed under the License is distributed on an "AS IS" BASIS,
                                                                                                                                                          * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
                                                                                                                                                          * See the License for the specific language governing permissions and
                                                                                                                                                          * limitations under the License.
                                                                                                                                                          */


/**
 * @struct
 */
var Observer = exports.Observer = function Observer(nextOrObserver, opt_error, opt_complete) {
    _classCallCheck(this, Observer);

    var asFunctions = type.isFunction(nextOrObserver) || type.isDef(opt_error) || type.isDef(opt_complete);
    if (asFunctions) {
        this.next = nextOrObserver;
        this.error = opt_error || null;
        this.complete = opt_complete || null;
    } else {
        var observer = nextOrObserver;
        this.next = observer.next || null;
        this.error = observer.error || null;
        this.complete = observer.complete || null;
    }
};
//# sourceMappingURL=observer.js.map
