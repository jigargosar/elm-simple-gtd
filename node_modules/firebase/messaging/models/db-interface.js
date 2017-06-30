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

var _errors = require('../../app/errors');

var _errors2 = require('./errors');

var _errors3 = _interopRequireDefault(_errors2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var DBInterface = function () {
    /**
     * @param {string} dbName
     * @param {number} dbVersion
     */
    function DBInterface(dbName, dbVersion) {
        _classCallCheck(this, DBInterface);

        this.errorFactory_ = new _errors.ErrorFactory('messaging', 'Messaging', _errors3.default.map);
        this.dbName_ = dbName;
        this.dbVersion_ = dbVersion;
        this.openDbPromise_ = null;
        this.TRANSACTION_READ_WRITE = 'readwrite';
    }
    /**
     * Get the indexedDB as a promsie.
     * @protected
     * @return {!Promise<!IDBDatabase>} The IndexedDB database
     */


    _createClass(DBInterface, [{
        key: 'openDatabase',
        value: function openDatabase() {
            var _this = this;

            if (this.openDbPromise_) {
                return this.openDbPromise_;
            }
            this.openDbPromise_ = new Promise(function (resolve, reject) {
                var request = indexedDB.open(_this.dbName_, _this.dbVersion_);
                request.onerror = function (event) {
                    reject(event.target.error);
                };
                request.onsuccess = function (event) {
                    resolve(event.target.result);
                };
                request.onupgradeneeded = function (event) {
                    var db = event.target.result;
                    _this.onDBUpgrade(db);
                };
            });
            return this.openDbPromise_;
        }
        /**
         * Close the currently open database.
         * @return {!Promise} Returns the result of the promise chain.
         */

    }, {
        key: 'closeDatabase',
        value: function closeDatabase() {
            var _this2 = this;

            return Promise.resolve().then(function () {
                if (_this2.openDbPromise_) {
                    return _this2.openDbPromise_.then(function (db) {
                        db.close();
                        _this2.openDbPromise_ = null;
                    });
                }
            });
        }
        /**
         * @protected
         * @param {!IDBDatabase} db
         */

    }, {
        key: 'onDBUpgrade',
        value: function onDBUpgrade() {
            throw this.errorFactory_.create(_errors3.default.codes.SHOULD_BE_INHERITED);
        }
    }]);

    return DBInterface;
}();

exports.default = DBInterface;
module.exports = exports['default'];
//# sourceMappingURL=db-interface.js.map
