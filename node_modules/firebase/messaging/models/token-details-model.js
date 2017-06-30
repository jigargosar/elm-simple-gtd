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

var _arrayBufferToBase = require('../helpers/array-buffer-to-base64');

var _arrayBufferToBase2 = _interopRequireDefault(_arrayBufferToBase);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var FCM_TOKEN_OBJ_STORE = 'fcm_token_object_Store';
var DB_VERSION = 1;
/** @record */
function ValidateInput() {}
/** @type {string|undefined} */
ValidateInput.prototype.fcmToken;
/** @type {string|undefined} */
ValidateInput.prototype.swScope;
/** @type {string|undefined} */
ValidateInput.prototype.vapidKey;
/** @type {PushSubscription|undefined} */
ValidateInput.prototype.subscription;
/** @type {string|undefined} */
ValidateInput.prototype.fcmSenderId;
/** @type {string|undefined} */
ValidateInput.prototype.fcmPushSet;

var TokenDetailsModel = function (_DBInterface) {
    _inherits(TokenDetailsModel, _DBInterface);

    function TokenDetailsModel() {
        _classCallCheck(this, TokenDetailsModel);

        return _possibleConstructorReturn(this, (TokenDetailsModel.__proto__ || Object.getPrototypeOf(TokenDetailsModel)).call(this, TokenDetailsModel.dbName, DB_VERSION));
    }

    _createClass(TokenDetailsModel, [{
        key: 'onDBUpgrade',

        /**
         * @override
         */
        value: function onDBUpgrade(db) {
            var objectStore = db.createObjectStore(FCM_TOKEN_OBJ_STORE, {
                keyPath: 'swScope'
            });
            // Make sure the sender ID can be searched
            objectStore.createIndex('fcmSenderId', 'fcmSenderId', {
                unique: false
            });
            objectStore.createIndex('fcmToken', 'fcmToken', {
                unique: true
            });
        }
        /**
         * This method takes an object and will check for known arguments and
         * validate the input.
         * @private
         * @param {!ValidateInput} input
         * @return {!Promise} Returns promise that resolves if input is valid,
         * rejects otherwise.
         */

    }, {
        key: 'validateInputs_',
        value: function validateInputs_(input) {
            if (input.fcmToken) {
                if (typeof input.fcmToken !== 'string' || input.fcmToken.length === 0) {
                    return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_TOKEN));
                }
            }
            if (input.swScope) {
                if (typeof input.swScope !== 'string' || input.swScope.length === 0) {
                    return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_SCOPE));
                }
            }
            if (input.vapidKey) {
                if (typeof input.vapidKey !== 'string' || input.vapidKey.length === 0) {
                    return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_VAPID_KEY));
                }
            }
            if (input.subscription) {
                if (!(input.subscription instanceof PushSubscription)) {
                    return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_SUBSCRIPTION));
                }
            }
            if (input.fcmSenderId) {
                if (typeof input.fcmSenderId !== 'string' || input.fcmSenderId.length === 0) {
                    return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_SENDER_ID));
                }
            }
            if (input.fcmPushSet) {
                if (typeof input.fcmPushSet !== 'string' || input.fcmPushSet.length === 0) {
                    return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_PUSH_SET));
                }
            }
            return Promise.resolve();
        }
        /**
         * Given a token, this method will look up the details in indexedDB.
         * @param {string} fcmToken
         * @return {Promise<Object>} The details associated with that token.
         */

    }, {
        key: 'getTokenDetailsFromToken',
        value: function getTokenDetailsFromToken(fcmToken) {
            var _this2 = this;

            if (!fcmToken) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_TOKEN));
            }
            return this.validateInputs_({ fcmToken: fcmToken }).then(function () {
                return _this2.openDatabase();
            }).then(function (db) {
                return new Promise(function (resolve, reject) {
                    var transaction = db.transaction([FCM_TOKEN_OBJ_STORE]);
                    var objectStore = transaction.objectStore(FCM_TOKEN_OBJ_STORE);
                    var index = objectStore.index('fcmToken');
                    var request = index.get(fcmToken);
                    request.onerror = function (event) {
                        reject(event.target.error);
                    };
                    request.onsuccess = function (event) {
                        var result = event.target.result ? event.target.result : null;
                        resolve(result);
                    };
                });
            });
        }
        /**
         * Given a service worker scope, this method will look up the details in
         * indexedDB.
         * @public
         * @param {string} swScope
         * @return {Promise<Object>} The details associated with that token.
         */

    }, {
        key: 'getTokenDetailsFromSWScope',
        value: function getTokenDetailsFromSWScope(swScope) {
            var _this3 = this;

            if (!swScope) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_SCOPE));
            }
            return this.validateInputs_({ swScope: swScope }).then(function () {
                return _this3.openDatabase();
            }).then(function (db) {
                return new Promise(function (resolve, reject) {
                    var transaction = db.transaction([FCM_TOKEN_OBJ_STORE]);
                    var objectStore = transaction.objectStore(FCM_TOKEN_OBJ_STORE);
                    var scopeRequest = objectStore.get(swScope);
                    scopeRequest.onerror = function (event) {
                        reject(event.target.error);
                    };
                    scopeRequest.onsuccess = function (event) {
                        var result = event.target.result ? event.target.result : null;
                        resolve(result);
                    };
                });
            });
        }
        /**
         * Save the details for the fcm token for re-use at a later date.
         * @param {{swScope: !string, vapidKey: !string,
         * subscription: !PushSubscription, fcmSenderId: !string, fcmToken: !string,
         * fcmPushSet: !string}} input A plain js object containing args to save.
         * @return {Promise<void>}
         */

    }, {
        key: 'saveTokenDetails',
        value: function saveTokenDetails(_ref) {
            var _this4 = this;

            var swScope = _ref.swScope,
                vapidKey = _ref.vapidKey,
                subscription = _ref.subscription,
                fcmSenderId = _ref.fcmSenderId,
                fcmToken = _ref.fcmToken,
                fcmPushSet = _ref.fcmPushSet;

            if (!swScope) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_SCOPE));
            }
            if (!vapidKey) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_VAPID_KEY));
            }
            if (!subscription) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_SUBSCRIPTION));
            }
            if (!fcmSenderId) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_SENDER_ID));
            }
            if (!fcmToken) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_TOKEN));
            }
            if (!fcmPushSet) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.BAD_PUSH_SET));
            }
            return this.validateInputs_({
                swScope: swScope,
                vapidKey: vapidKey,
                subscription: subscription,
                fcmSenderId: fcmSenderId,
                fcmToken: fcmToken,
                fcmPushSet: fcmPushSet
            }).then(function () {
                return _this4.openDatabase();
            }).then(function (db) {
                /**
                 * @dict
                 */
                var details = {
                    'swScope': swScope,
                    'vapidKey': vapidKey,
                    'endpoint': subscription.endpoint,
                    'auth': (0, _arrayBufferToBase2.default)(subscription['getKey']('auth')),
                    'p256dh': (0, _arrayBufferToBase2.default)(subscription['getKey']('p256dh')),
                    'fcmSenderId': fcmSenderId,
                    'fcmToken': fcmToken,
                    'fcmPushSet': fcmPushSet
                };
                return new Promise(function (resolve, reject) {
                    var transaction = db.transaction([FCM_TOKEN_OBJ_STORE], _this4.TRANSACTION_READ_WRITE);
                    var objectStore = transaction.objectStore(FCM_TOKEN_OBJ_STORE);
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
         * This method deletes details of the current FCM token.
         * It's returning a promise in case we need to move to an async
         * method for deleting at a later date.
         * @param {string} token Token to be deleted
         * @return {Promise<Object>} Resolves once the FCM token details have been
         * deleted and returns the deleted details.
         */

    }, {
        key: 'deleteToken',
        value: function deleteToken(token) {
            var _this5 = this;

            if (typeof token !== 'string' || token.length === 0) {
                return Promise.reject(this.errorFactory_.create(_errors2.default.codes.INVALID_DELETE_TOKEN));
            }
            return this.getTokenDetailsFromToken(token).then(function (details) {
                if (!details) {
                    throw _this5.errorFactory_.create(_errors2.default.codes.DELETE_TOKEN_NOT_FOUND);
                }
                return _this5.openDatabase().then(function (db) {
                    return new Promise(function (resolve, reject) {
                        var transaction = db.transaction([FCM_TOKEN_OBJ_STORE], _this5.TRANSACTION_READ_WRITE);
                        var objectStore = transaction.objectStore(FCM_TOKEN_OBJ_STORE);
                        var request = objectStore.delete(details['swScope']);
                        request.onerror = function (event) {
                            reject(event.target.error);
                        };
                        request.onsuccess = function (event) {
                            if (event.target.result === 0) {
                                reject(_this5.errorFactory_.create(_errors2.default.codes.FAILED_TO_DELETE_TOKEN));
                                return;
                            }
                            resolve(details);
                        };
                    });
                });
            });
        }
    }], [{
        key: 'dbName',
        get: function get() {
            return 'fcm_token_details_db';
        }
    }]);

    return TokenDetailsModel;
}(_dbInterface2.default);

exports.default = TokenDetailsModel;
module.exports = exports['default'];
//# sourceMappingURL=token-details-model.js.map
