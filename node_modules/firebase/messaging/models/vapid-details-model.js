/*! @license Firebase v4.1.3
Build: rev-1234895
Terms: https://firebase.google.com/terms/ */

/**
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
'use strict';

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _dbInterface = require('./db-interface');

var _dbInterface2 = _interopRequireDefault(_dbInterface);

var _errors = require('./errors');

var _errors2 = _interopRequireDefault(_errors);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var FCM_VAPID_OBJ_STORE = 'fcm_vapid_object_Store';
var DB_VERSION = 1;

var VapidDetailsModel = function (_DBInterface) {
    _inherits(VapidDetailsModel, _DBInterface);

    function VapidDetailsModel() {
        _classCallCheck(this, VapidDetailsModel);

        return _possibleConstructorReturn(this, (VapidDetailsModel.__proto__ || Object.getPrototypeOf(VapidDetailsModel)).call(this, VapidDetailsModel.dbName, DB_VERSION));
    }

    _createClass(VapidDetailsModel, [{
        key: 'onDBUpgrade',

        /**
         * @override
         * @param {IDBDatabase} db
         */
        value: function onDBUpgrade(db) {
            db.createObjectStore(FCM_VAPID_OBJ_STORE, {
                keyPath: 'swScope'
            });
        }
        /**
         * Given a service worker scope, this method will look up the vapid key
         * in indexedDB.
         * @param {string} swScope
         * @return {Promise<string>} The vapid key associated with that scope.
         */

    }, {
        key: 'getVapidFromSWScope',
        value: function getVapidFromSWScope(swScope) {
            if (typeof swScope !== 'string' || swScope.length === 0) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_SCOPE));
            }
            return this.openDatabase().then(function (db) {
                return new Promise(function (resolve, reject) {
                    var transaction = db.transaction([FCM_VAPID_OBJ_STORE]);
                    var objectStore = transaction.objectStore(FCM_VAPID_OBJ_STORE);
                    var scopeRequest = objectStore.get(swScope);
                    scopeRequest.onerror = function (event) {
                        reject(event.target.error);
                    };
                    scopeRequest.onsuccess = function (event) {
                        var result = event.target.result;
                        var vapidKey = null;
                        if (result) {
                            vapidKey = result.vapidKey;
                        }
                        resolve(vapidKey);
                    };
                });
            });
        }
        /**
         * Save a vapid key against a swScope for later date.
         * @param  {string} swScope The service worker scope to be associated with
         * this push subscription.
         * @param {string} vapidKey The public vapid key to be associated with
         * the swScope.
         * @return {Promise<void>}
         */

    }, {
        key: 'saveVapidDetails',
        value: function saveVapidDetails(swScope, vapidKey) {
            var _this2 = this;

            if (typeof swScope !== 'string' || swScope.length === 0) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_SCOPE));
            }
            if (typeof vapidKey !== 'string' || vapidKey.length === 0) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_VAPID_KEY));
            }
            var details = {
                'swScope': swScope,
                'vapidKey': vapidKey
            };
            return this.openDatabase().then(function (db) {
                return new Promise(function (resolve, reject) {
                    var transaction = db.transaction([FCM_VAPID_OBJ_STORE], _this2.TRANSACTION_READ_WRITE);
                    var objectStore = transaction.objectStore(FCM_VAPID_OBJ_STORE);
                    var request = objectStore.put(details);
                    request.onerror = function (event) {
                        reject(event.target.error);
                    };
                    request.onsuccess = function () {
                        resolve();
                    };
                });
            });
        }
        /**
         * This method deletes details of the current FCM VAPID key for a SW scope.
         * @param {string} swScope Scope to be deleted
         * @return {Promise<string>} Resolves once the scope / vapid details have been
         * deleted and returns the deleted vapid key.
         */

    }, {
        key: 'deleteVapidDetails',
        value: function deleteVapidDetails(swScope) {
            var _this3 = this;

            return this.getVapidFromSWScope(swScope).then(function (vapidKey) {
                if (!vapidKey) {
                    throw _this3.errorFactory_.create(_errors2.default.codes.DELETE_SCOPE_NOT_FOUND);
                }
                return _this3.openDatabase().then(function (db) {
                    return new Promise(function (resolve, reject) {
                        var transaction = db.transaction([FCM_VAPID_OBJ_STORE], _this3.TRANSACTION_READ_WRITE);
                        var objectStore = transaction.objectStore(FCM_VAPID_OBJ_STORE);
                        var request = objectStore.delete(swScope);
                        request.onerror = function (event) {
                            reject(event.target.error);
                        };
                        request.onsuccess = function (event) {
                            if (event.target.result === 0) {
                                reject(_this3.errorFactory_.create(_errors2.default.codes.FAILED_DELETE_VAPID_KEY));
                                return;
                            }
                            resolve(vapidKey);
                        };
                    });
                });
            });
        }
    }], [{
        key: 'dbName',
        get: function get() {
            return 'fcm_vapid_details_db';
        }
    }]);

    return VapidDetailsModel;
}(_dbInterface2.default);

exports.default = VapidDetailsModel;
module.exports = exports['default'];
//# sourceMappingURL=vapid-details-model.js.map
