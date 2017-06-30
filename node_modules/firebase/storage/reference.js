/*! @license Firebase v4.1.3
Build: rev-1234895
Terms: https://firebase.google.com/terms/ */

'use strict';

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.Reference = undefined;

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }(); /**
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
 * @fileoverview Defines the Firebase Storage Reference class.
 */


var _args = require('./implementation/args');

var args = _interopRequireWildcard(_args);

var _blob = require('./implementation/blob');

var _error = require('./implementation/error');

var errorsExports = _interopRequireWildcard(_error);

var _location = require('./implementation/location');

var _metadata = require('./implementation/metadata');

var metadata = _interopRequireWildcard(_metadata);

var _object = require('./implementation/object');

var object = _interopRequireWildcard(_object);

var _path = require('./implementation/path');

var path = _interopRequireWildcard(_path);

var _requests = require('./implementation/requests');

var requests = _interopRequireWildcard(_requests);

var _string = require('./implementation/string');

var fbsString = _interopRequireWildcard(_string);

var _type = require('./implementation/type');

var type = _interopRequireWildcard(_type);

var _task = require('./task');

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/**
 * Provides methods to interact with a bucket in the Firebase Storage service.
 * @param location An fbs.location, or the URL at
 *     which to base this object, in one of the following forms:
 *         gs://<bucket>/<object-path>
 *         http[s]://firebasestorage.googleapis.com/
 *                     <api-version>/b/<bucket>/o/<object-path>
 *     Any query or fragment strings will be ignored in the http[s]
 *     format. If no value is passed, the storage object will use a URL based on
 *     the project ID of the base firebase.App instance.
 */
var Reference = exports.Reference = function () {
    function Reference(authWrapper, location) {
        _classCallCheck(this, Reference);

        this.authWrapper = authWrapper;
        if (location instanceof _location.Location) {
            this.location = location;
        } else {
            this.location = _location.Location.makeFromUrl(location);
        }
    }
    /**
     * @return The URL for the bucket and path this object references,
     *     in the form gs://<bucket>/<object-path>
     * @override
     */


    _createClass(Reference, [{
        key: 'toString',
        value: function toString() {
            args.validate('toString', [], arguments);
            return 'gs://' + this.location.bucket + '/' + this.location.path;
        }
    }, {
        key: 'newRef',
        value: function newRef(authWrapper, location) {
            return new Reference(authWrapper, location);
        }
    }, {
        key: 'mappings',
        value: function mappings() {
            return metadata.getMappings();
        }
        /**
         * @return A reference to the object obtained by
         *     appending childPath, removing any duplicate, beginning, or trailing
         *     slashes.
         */

    }, {
        key: 'child',
        value: function child(childPath) {
            args.validate('child', [args.stringSpec()], arguments);
            var newPath = path.child(this.location.path, childPath);
            var location = new _location.Location(this.location.bucket, newPath);
            return this.newRef(this.authWrapper, location);
        }
        /**
         * @return A reference to the parent of the
         *     current object, or null if the current object is the root.
         */

    }, {
        key: 'put',

        /**
         * Uploads a blob to this object's location.
         * @param data The blob to upload.
         * @return An UploadTask that lets you control and
         *     observe the upload.
         */
        value: function put(data) {
            var metadata = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;

            args.validate('put', [args.uploadDataSpec(), args.metadataSpec(true)], arguments);
            this.throwIfRoot_('put');
            return new _task.UploadTask(this, this.authWrapper, this.location, this.mappings(), new _blob.FbsBlob(data), metadata);
        }
        /**
         * Uploads a string to this object's location.
         * @param string The string to upload.
         * @param opt_format The format of the string to upload.
         * @return An UploadTask that lets you control and
         *     observe the upload.
         */

    }, {
        key: 'putString',
        value: function putString(string) {
            var format = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : _string.StringFormat.RAW;
            var opt_metadata = arguments[2];

            args.validate('putString', [args.stringSpec(), args.stringSpec(fbsString.formatValidator, true), args.metadataSpec(true)], arguments);
            this.throwIfRoot_('putString');
            var data = fbsString.dataFromString(format, string);
            var metadata = object.clone(opt_metadata);
            if (!type.isDef(metadata['contentType']) && type.isDef(data.contentType)) {
                metadata['contentType'] = data.contentType;
            }
            return new _task.UploadTask(this, this.authWrapper, this.location, this.mappings(), new _blob.FbsBlob(data.data, true), metadata);
        }
        /**
         * Deletes the object at this location.
         * @return A promise that resolves if the deletion succeeds.
         */

    }, {
        key: 'delete',
        value: function _delete() {
            args.validate('delete', [], arguments);
            this.throwIfRoot_('delete');
            var self = this;
            return this.authWrapper.getAuthToken().then(function (authToken) {
                var requestInfo = requests.deleteObject(self.authWrapper, self.location);
                return self.authWrapper.makeRequest(requestInfo, authToken).getPromise();
            });
        }
        /**
         *     A promise that resolves with the metadata for this object. If this
         *     object doesn't exist or metadata cannot be retreived, the promise is
         *     rejected.
         */

    }, {
        key: 'getMetadata',
        value: function getMetadata() {
            args.validate('getMetadata', [], arguments);
            this.throwIfRoot_('getMetadata');
            var self = this;
            return this.authWrapper.getAuthToken().then(function (authToken) {
                var requestInfo = requests.getMetadata(self.authWrapper, self.location, self.mappings());
                return self.authWrapper.makeRequest(requestInfo, authToken).getPromise();
            });
        }
        /**
         * Updates the metadata for this object.
         * @param metadata The new metadata for the object.
         *     Only values that have been explicitly set will be changed. Explicitly
         *     setting a value to null will remove the metadata.
         * @return A promise that resolves
         *     with the new metadata for this object.
         *     @see firebaseStorage.Reference.prototype.getMetadata
         */

    }, {
        key: 'updateMetadata',
        value: function updateMetadata(metadata) {
            args.validate('updateMetadata', [args.metadataSpec()], arguments);
            this.throwIfRoot_('updateMetadata');
            var self = this;
            return this.authWrapper.getAuthToken().then(function (authToken) {
                var requestInfo = requests.updateMetadata(self.authWrapper, self.location, metadata, self.mappings());
                return self.authWrapper.makeRequest(requestInfo, authToken).getPromise();
            });
        }
        /**
         * @return A promise that resolves with the download
         *     URL for this object.
         */

    }, {
        key: 'getDownloadURL',
        value: function getDownloadURL() {
            args.validate('getDownloadURL', [], arguments);
            this.throwIfRoot_('getDownloadURL');
            return this.getMetadata().then(function (metadata) {
                var url = metadata['downloadURLs'][0];
                if (type.isDef(url)) {
                    return url;
                } else {
                    throw errorsExports.noDownloadURL();
                }
            });
        }
    }, {
        key: 'throwIfRoot_',
        value: function throwIfRoot_(name) {
            if (this.location.path === '') {
                throw errorsExports.invalidRootOperation(name);
            }
        }
    }, {
        key: 'parent',
        get: function get() {
            var newPath = path.parent(this.location.path);
            if (newPath === null) {
                return null;
            }
            var location = new _location.Location(this.location.bucket, newPath);
            return this.newRef(this.authWrapper, location);
        }
        /**
         * @return An reference to the root of this
         *     object's bucket.
         */

    }, {
        key: 'root',
        get: function get() {
            var location = new _location.Location(this.location.bucket, '');
            return this.newRef(this.authWrapper, location);
        }
    }, {
        key: 'bucket',
        get: function get() {
            return this.location.bucket;
        }
    }, {
        key: 'fullPath',
        get: function get() {
            return this.location.path;
        }
    }, {
        key: 'name',
        get: function get() {
            return path.lastComponent(this.location.path);
        }
    }, {
        key: 'storage',
        get: function get() {
            return this.authWrapper.service();
        }
    }]);

    return Reference;
}();
//# sourceMappingURL=reference.js.map
