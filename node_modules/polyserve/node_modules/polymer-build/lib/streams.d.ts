/// <reference types="vinyl" />
/// <reference types="node" />
/**
 * @license
 * Copyright (c) 2016 The Polymer Project Authors. All rights reserved.
 * This code may only be used under the BSD style license found at
 * http://polymer.github.io/LICENSE.txt
 * The complete set of authors may be found at
 * http://polymer.github.io/AUTHORS.txt
 * The complete set of contributors may be found at
 * http://polymer.github.io/CONTRIBUTORS.txt
 * Code distributed by Google as part of the polymer project is also
 * subject to an additional IP rights grant found at
 * http://polymer.github.io/PATENTS.txt
 */
import { Transform } from 'stream';
import File = require('vinyl');
export declare type FileCB = (error?: any, file?: File) => void;
/**
 * Waits for the given ReadableStream
 */
export declare function waitFor(stream: NodeJS.ReadableStream): Promise<NodeJS.ReadableStream>;
/**
 * Waits for all the given ReadableStreams
 */
export declare function waitForAll(streams: NodeJS.ReadableStream[]): Promise<NodeJS.ReadableStream[]>;
/**
 * Composes multiple streams (or Transforms) into one.
 */
export declare function compose(streams: NodeJS.ReadWriteStream[]): any;
/**
 * A stream that takes file path strings, and outputs full Vinyl file objects
 * for the file at each location.
 */
export declare class VinylReaderTransform extends Transform {
    constructor();
    _transform(filePath: string, _encoding: string, callback: (error?: Error, data?: File) => void): void;
}
