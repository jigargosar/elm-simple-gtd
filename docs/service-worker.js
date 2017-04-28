/**
 * Copyright 2016 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

// DO NOT EDIT THIS GENERATED OUTPUT DIRECTLY!
// This file should be overwritten as part of your build process.
// If you need to extend the behavior of the generated service worker, the best approach is to write
// additional code and include it using the importScripts option:
//   https://github.com/GoogleChrome/sw-precache#importscripts-arraystring
//
// Alternatively, it's possible to make changes to the underlying template file and then use that as the
// new base for generating output, via the templateFilePath option:
//   https://github.com/GoogleChrome/sw-precache#templatefilepath-string
//
// If you go that route, make sure that whenever you update your sw-precache dependency, you reconcile any
// changes made to this original template file with your modified copy.

// This generated service worker JavaScript will precache your site's resources.
// The code needs to be saved in a .js file at the top-level of your site, and registered
// from your pages in order to be used. See
// https://github.com/googlechrome/sw-precache/blob/master/demo/app/js/service-worker-registration.js
// for an example of how you can register this script and handle various service worker events.

/* eslint-env worker, serviceworker */
/* eslint-disable indent, no-unused-vars, no-multiple-empty-lines, max-nested-callbacks, space-before-function-paren, quotes, comma-spacing */
'use strict';

var precacheConfig = [["/alarm.ogg","15a849a06ed28d19e43556b0bf2ab7ce"],["/bower_components/app-layout/app-box/app-box.html","bd4a78d2fcd064925ad91e839e69d08f"],["/bower_components/app-layout/app-drawer-layout/app-drawer-layout.html","af5029265f7792adf2385a0cfe078b8f"],["/bower_components/app-layout/app-drawer/app-drawer.html","d1b0eef93a0f942f3b97b79c62fa868d"],["/bower_components/app-layout/app-grid/app-grid-style.html","4c9aacec111919f1e4d7498ef1404ccd"],["/bower_components/app-layout/app-header-layout/app-header-layout.html","e6a3db467fa78e032f289d2404228492"],["/bower_components/app-layout/app-header/app-header.html","5a97fae3155d3595461c7ce8c9e88415"],["/bower_components/app-layout/app-layout.html","3c689a8c4534de1cf09c1f2b1c4bb10d"],["/bower_components/app-layout/app-scroll-effects/app-scroll-effects-behavior.html","8739b82717401303dad2017e74687cbc"],["/bower_components/app-layout/app-scroll-effects/app-scroll-effects.html","334eac7f54a828baedbe8f09574571b7"],["/bower_components/app-layout/app-scroll-effects/effects/blend-background.html","dead12f7659321c7fe4928aae467519f"],["/bower_components/app-layout/app-scroll-effects/effects/fade-background.html","35e9b86069d272d5e086d324e6afa01a"],["/bower_components/app-layout/app-scroll-effects/effects/material.html","26f969f3f845031af5f3c728d550638b"],["/bower_components/app-layout/app-scroll-effects/effects/parallax-background.html","6ca6cd1f7972a53c6b5d38360f39459e"],["/bower_components/app-layout/app-scroll-effects/effects/resize-snapped-title.html","22c4d4328472d5dc35906793fe731a2f"],["/bower_components/app-layout/app-scroll-effects/effects/resize-title.html","d8f18dc2f86c5727c6656c63f5a92b4a"],["/bower_components/app-layout/app-scroll-effects/effects/waterfall.html","059e8ca24132d7f55f5b972ba3459ff6"],["/bower_components/app-layout/app-scrollpos-control/app-scrollpos-control.html","9b1440dcdbfc991c11652f656810e7bc"],["/bower_components/app-layout/app-toolbar/app-toolbar.html","72cdb6a42549b8351ff9f49c248a8750"],["/bower_components/app-layout/helpers/helpers.html","6e948b2af4167cc02b9e41d27aa89c34"],["/bower_components/font-roboto/roboto.html","196f915c2bb639c50e0748d057754841"],["/bower_components/iron-a11y-announcer/iron-a11y-announcer.html","0728d32ca62675f5088b63a6aa60ab4e"],["/bower_components/iron-a11y-keys-behavior/iron-a11y-keys-behavior.html","7440176796d324569bd0f45139250f6f"],["/bower_components/iron-ajax/iron-ajax.html","34cdc2556683c94eeb3008c0e4605bcc"],["/bower_components/iron-ajax/iron-request.html","b34bb10c5d2fcb6daec06fe283abca18"],["/bower_components/iron-autogrow-textarea/iron-autogrow-textarea.html","b4164280e27b039906234115c4b5b22d"],["/bower_components/iron-behaviors/iron-button-state.html","49775c63df22d46cec1377ef6d20c037"],["/bower_components/iron-behaviors/iron-control-state.html","4fcbfb77d2aa7022c60500f0dd3b5cb2"],["/bower_components/iron-checked-element-behavior/iron-checked-element-behavior.html","ffbd60e7b7389c26b0f89ed892cbb605"],["/bower_components/iron-dropdown/iron-dropdown-scroll-manager.html","5c38539f4310338f66d9d18657c1a817"],["/bower_components/iron-dropdown/iron-dropdown.html","296d4d4c81e8b2de984bdf35acce87b7"],["/bower_components/iron-fit-behavior/iron-fit-behavior.html","9b3331ee6e21aebec2d3b29af120018b"],["/bower_components/iron-flex-layout/iron-flex-layout-classes.html","1af0f1c4265e9ed22714c7b51c226aa5"],["/bower_components/iron-flex-layout/iron-flex-layout.html","d209230aa135c45c817b0deacd4fe0cf"],["/bower_components/iron-form-element-behavior/iron-form-element-behavior.html","3e799ae5e8d84e04e958d27a98386ad4"],["/bower_components/iron-form/iron-form.html","6c5fc082e3508c1fd8cc5fe6f68e5ec8"],["/bower_components/iron-icon/iron-icon.html","4474495f5880296a71bdfe8c25a9b177"],["/bower_components/iron-icons/av-icons.html","9926bdf47fe074657acf2e8b3822f1ad"],["/bower_components/iron-icons/iron-icons.html","263c425f0e794d1e2fd636f8039a8586"],["/bower_components/iron-icons/notification-icons.html","e586f5b5dc1b292813a0fdf80d7a5a1a"],["/bower_components/iron-iconset-svg/iron-iconset-svg.html","49799926a48566d5123c904f9794a841"],["/bower_components/iron-image/iron-image.html","d7caa4869e3799730a05f2cd140116a3"],["/bower_components/iron-input/iron-input.html","1b9e45693ddceaf411fd8c7be480f0ed"],["/bower_components/iron-media-query/iron-media-query.html","123c237d3e6ef90a435587637dcfa283"],["/bower_components/iron-menu-behavior/iron-menu-behavior.html","d5bd09737f4cb34764e180a8e60e9784"],["/bower_components/iron-menu-behavior/iron-menubar-behavior.html","5c6662113952baa77fb0f5093136abbb"],["/bower_components/iron-meta/iron-meta.html","22640b34ba951b1a444f1214af6ed3b8"],["/bower_components/iron-overlay-behavior/iron-focusables-helper.html","9fc2e540ba2ea395379c8d0bde3d8e1d"],["/bower_components/iron-overlay-behavior/iron-overlay-backdrop.html","3636c9db3ae0dda6f2a80ce0550db70e"],["/bower_components/iron-overlay-behavior/iron-overlay-behavior.html","d69c36fe07fae9d0fd6aceb8a324f980"],["/bower_components/iron-overlay-behavior/iron-overlay-manager.html","23f3f85ba1b3762dc5d81d06c38df470"],["/bower_components/iron-resizable-behavior/iron-resizable-behavior.html","5fe75e822fa832511ee353aa66346dff"],["/bower_components/iron-scroll-target-behavior/iron-scroll-target-behavior.html","1fbb87d3b5b395416850303b3cf737ce"],["/bower_components/iron-selector/iron-multi-selectable.html","a000c889fb84ded9e70e36809b677ba1"],["/bower_components/iron-selector/iron-selectable.html","c5609868c46bae919c8fb40d228f1b26"],["/bower_components/iron-selector/iron-selection.html","6820931a3f3849002e7a95cabd6d23f5"],["/bower_components/iron-validatable-behavior/iron-validatable-behavior.html","b4801617710bab65aa765d10131b1d61"],["/bower_components/neon-animation/animations/fade-in-animation.html","fd444675cc9ad104b2259593141fb4d1"],["/bower_components/neon-animation/animations/fade-out-animation.html","bba0798bd1ff91dbf156175df615bd36"],["/bower_components/neon-animation/animations/opaque-animation.html","0124ca5fdcca152ef7923f18a613cd6d"],["/bower_components/neon-animation/neon-animatable-behavior.html","05b7fd53f09eb308f8167fdc4d531338"],["/bower_components/neon-animation/neon-animation-behavior.html","e23901cd4e71134ec4784a8dc3f0cd78"],["/bower_components/neon-animation/neon-animation-runner-behavior.html","34c79b7256414aa336768c4099b7382c"],["/bower_components/neon-animation/web-animations.html","e83d816f67ab3e8778d4c46f052b8656"],["/bower_components/paper-behaviors/paper-button-behavior.html","1e11f79c55267e65501d85ddcd372f39"],["/bower_components/paper-behaviors/paper-checked-element-behavior.html","c21b300f19f55e621ecb82953a08ac4f"],["/bower_components/paper-behaviors/paper-inky-focus-behavior.html","5e34513d00a9b66055202e85990c1feb"],["/bower_components/paper-behaviors/paper-ripple-behavior.html","99bf6252e996b9400187621a9764d5d8"],["/bower_components/paper-button/paper-button.html","c96c73ec1a9dc5b0aa74deaffb2f98a6"],["/bower_components/paper-card/paper-card.html","2654b1c4eef0e18b754ae7ad58b4c5da"],["/bower_components/paper-checkbox/paper-checkbox.html","8232f5b5f91c9f60ace3a5c2d001703b"],["/bower_components/paper-dialog-behavior/paper-dialog-behavior.html","a4374a90d65f15eee6dcb0729ba53b8d"],["/bower_components/paper-dialog-behavior/paper-dialog-shared-styles.html","e9be5e84da10e2c8126484a4e8fdeb98"],["/bower_components/paper-dialog/paper-dialog.html","07782348bc550cf90fafb89342a5ea8d"],["/bower_components/paper-dropdown-menu/paper-dropdown-menu-icons.html","f683c1089dfe60d79ebbdf072c551e21"],["/bower_components/paper-dropdown-menu/paper-dropdown-menu-shared-styles.html","e3ee1db4137de9758c8cc6b1d301c74f"],["/bower_components/paper-dropdown-menu/paper-dropdown-menu.html","f5f02325491adacc28d0580f13bfce26"],["/bower_components/paper-fab/paper-fab.html","aa145fecbbe4924e2afd743d5e7e5ca9"],["/bower_components/paper-icon-button/paper-icon-button.html","c32efdf00774bffe1ba228b9d03be88f"],["/bower_components/paper-input/all-imports.html","41fc005abaabd68b324e8b275f7f852d"],["/bower_components/paper-input/paper-input-addon-behavior.html","28d2d520f667e85d371921f4b3130674"],["/bower_components/paper-input/paper-input-behavior.html","c45781dcce65bfedf9adff7867c0d769"],["/bower_components/paper-input/paper-input-char-counter.html","87587064555d1273c9c7fdc4a1e6959b"],["/bower_components/paper-input/paper-input-container.html","4749bd9dd783f3fad074b01f822e4cdc"],["/bower_components/paper-input/paper-input-error.html","4eb87b4a6bac8b9644a4358221acb70e"],["/bower_components/paper-input/paper-input.html","83b4d3cacc2a4b0994b1740608be8684"],["/bower_components/paper-input/paper-textarea.html","b0681e5ae64075b65038855319bc41e1"],["/bower_components/paper-item/all-imports.html","db0d0fcce82b933130c83af24155bcb5"],["/bower_components/paper-item/paper-icon-item.html","0e33c161b5148f2b4f61fe5802645205"],["/bower_components/paper-item/paper-item-behavior.html","b8600d86cfee2b34340767a8a89efbfa"],["/bower_components/paper-item/paper-item-body.html","a0018f4a1e9a8fdd2a51b9a6dade3b1d"],["/bower_components/paper-item/paper-item-shared-styles.html","4178a2695e9295e7f141ff3537509603"],["/bower_components/paper-item/paper-item.html","ae6d3f2a50856007fff8c604fb0e22a8"],["/bower_components/paper-listbox/paper-listbox.html","8d63f9857e599a9edd2be10af9bcb2e3"],["/bower_components/paper-material/paper-material-shared-styles.html","96e347b417f6c92a317813cc08a23c8d"],["/bower_components/paper-material/paper-material.html","382036b63514247ef7fbdd934fc421e0"],["/bower_components/paper-menu-button/paper-menu-button-animations.html","f8c2d3f9d6de6930c6305c9e472e6515"],["/bower_components/paper-menu-button/paper-menu-button.html","e361cf70df71b75c04fe792e7454af24"],["/bower_components/paper-menu/paper-menu-shared-styles.html","4e60cac604f30d4c4d4fddbbb7fbffcf"],["/bower_components/paper-menu/paper-menu.html","2131d583b17943b3c824a56700eedb1a"],["/bower_components/paper-ripple/paper-ripple.html","8fe95ef6f8e1ecf994abd0f62c131143"],["/bower_components/paper-styles/color.html","731b5f7949a2c3f26ce829fd9be99c2d"],["/bower_components/paper-styles/default-theme.html","9e845d4da61bd65308eb8e4682cd8506"],["/bower_components/paper-styles/shadow.html","17203fd5db371a3e5cb4efabb11951f9"],["/bower_components/paper-styles/typography.html","dc2b6f8af5ebcb16a63800b46017a08a"],["/bower_components/paper-tabs/paper-tab.html","fa69ba250c596eded61583e36e3af887"],["/bower_components/paper-tabs/paper-tabs-icons.html","c48ea33d583e13726e490f48c721bfa4"],["/bower_components/paper-tabs/paper-tabs.html","e3c6bbc79f234c2a96aeead14d4d1c9b"],["/bower_components/paper-toggle-button/paper-toggle-button.html","6b12288ed6c52f52bd0c51270596384a"],["/bower_components/polymer/polymer-micro.html","66cad9ad9025c377df71e3683775cc8c"],["/bower_components/polymer/polymer-mini.html","7b1fc7418d572f6b7f494e5f40d6c5d4"],["/bower_components/polymer/polymer.html","75fcf6ced91056f8f7538a645b309548"],["/bower_components/promise-polyfill/Promise.js","857c8d202f2689de1a988f9a865e9aef"],["/bower_components/promise-polyfill/promise-polyfill-lite.html","4374446811f98599aa5865b4b0bff0f7"],["/bower_components/vaadin-icons/vaadin-icons.html","5dd72dfc059ed89f1e128162c9ffff6e"],["/bower_components/web-animations-js/web-animations-next-lite.min.js","3d550d65120362fa5c03841f074f2a2f"],["/bower_components/web-animations-js/web-animations.min.html","778768ec9ebb875968565a034cdf6fbd"],["/bower_components/web-animations-js/web-animations.min.js","ffeee7c145a67ca85d0a0141f0151339"],["/common.js","40d3e8bfd9931d34390df56b00d6824f"],["/favicon.ico","17b48e461e0c4fd7cc5c0cd2ba1dc3c4"],["/imports.html","b8562f2d148d474ce465850a90973882"],["/index.html","7b5f25c5ee47a6ff3628c53d0a60a466"],["/main.js","97cf34bb1899e19f2dbe103ca01d4dd2"],["/manifest.json","1cf64a8dfdab51bfe44fafc7b6a1cb26"],["/stack.png","3d665038e72997c9d40f2f77fa08e9a7"]];
var cacheName = 'sw-precache-v2--' + (self.registration ? self.registration.scope : '');


var ignoreUrlParametersMatching = [/^utm_/];



var addDirectoryIndex = function (originalUrl, index) {
    var url = new URL(originalUrl);
    if (url.pathname.slice(-1) === '/') {
      url.pathname += index;
    }
    return url.toString();
  };

var createCacheKey = function (originalUrl, paramName, paramValue,
                           dontCacheBustUrlsMatching) {
    // Create a new URL object to avoid modifying originalUrl.
    var url = new URL(originalUrl);

    // If dontCacheBustUrlsMatching is not set, or if we don't have a match,
    // then add in the extra cache-busting URL parameter.
    if (!dontCacheBustUrlsMatching ||
        !(url.toString().match(dontCacheBustUrlsMatching))) {
      url.search += (url.search ? '&' : '') +
        encodeURIComponent(paramName) + '=' + encodeURIComponent(paramValue);
    }

    return url.toString();
  };

var isPathWhitelisted = function (whitelist, absoluteUrlString) {
    // If the whitelist is empty, then consider all URLs to be whitelisted.
    if (whitelist.length === 0) {
      return true;
    }

    // Otherwise compare each path regex to the path of the URL passed in.
    var path = (new URL(absoluteUrlString)).pathname;
    return whitelist.some(function(whitelistedPathRegex) {
      return path.match(whitelistedPathRegex);
    });
  };

var stripIgnoredUrlParameters = function (originalUrl,
    ignoreUrlParametersMatching) {
    var url = new URL(originalUrl);

    url.search = url.search.slice(1) // Exclude initial '?'
      .split('&') // Split into an array of 'key=value' strings
      .map(function(kv) {
        return kv.split('='); // Split each 'key=value' string into a [key, value] array
      })
      .filter(function(kv) {
        return ignoreUrlParametersMatching.every(function(ignoredRegex) {
          return !ignoredRegex.test(kv[0]); // Return true iff the key doesn't match any of the regexes.
        });
      })
      .map(function(kv) {
        return kv.join('='); // Join each [key, value] array into a 'key=value' string
      })
      .join('&'); // Join the array of 'key=value' strings into a string with '&' in between each

    return url.toString();
  };


var hashParamName = '_sw-precache';
var urlsToCacheKeys = new Map(
  precacheConfig.map(function(item) {
    var relativeUrl = item[0];
    var hash = item[1];
    var absoluteUrl = new URL(relativeUrl, self.location);
    var cacheKey = createCacheKey(absoluteUrl, hashParamName, hash, false);
    return [absoluteUrl.toString(), cacheKey];
  })
);

function setOfCachedUrls(cache) {
  return cache.keys().then(function(requests) {
    return requests.map(function(request) {
      return request.url;
    });
  }).then(function(urls) {
    return new Set(urls);
  });
}

self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(cacheName).then(function(cache) {
      return setOfCachedUrls(cache).then(function(cachedUrls) {
        return Promise.all(
          Array.from(urlsToCacheKeys.values()).map(function(cacheKey) {
            // If we don't have a key matching url in the cache already, add it.
            if (!cachedUrls.has(cacheKey)) {
              return cache.add(new Request(cacheKey, {
                credentials: 'same-origin',
                redirect: 'follow'
              }));
            }
          })
        );
      });
    }).then(function() {
      
      // Force the SW to transition from installing -> active state
      return self.skipWaiting();
      
    })
  );
});

self.addEventListener('activate', function(event) {
  var setOfExpectedUrls = new Set(urlsToCacheKeys.values());

  event.waitUntil(
    caches.open(cacheName).then(function(cache) {
      return cache.keys().then(function(existingRequests) {
        return Promise.all(
          existingRequests.map(function(existingRequest) {
            if (!setOfExpectedUrls.has(existingRequest.url)) {
              return cache.delete(existingRequest);
            }
          })
        );
      });
    }).then(function() {
      
      return self.clients.claim();
      
    })
  );
});


self.addEventListener('fetch', function(event) {
  if (event.request.method === 'GET') {
    // Should we call event.respondWith() inside this fetch event handler?
    // This needs to be determined synchronously, which will give other fetch
    // handlers a chance to handle the request if need be.
    var shouldRespond;

    // First, remove all the ignored parameter and see if we have that URL
    // in our cache. If so, great! shouldRespond will be true.
    var url = stripIgnoredUrlParameters(event.request.url, ignoreUrlParametersMatching);
    shouldRespond = urlsToCacheKeys.has(url);

    // If shouldRespond is false, check again, this time with 'index.html'
    // (or whatever the directoryIndex option is set to) at the end.
    var directoryIndex = 'index.html';
    if (!shouldRespond && directoryIndex) {
      url = addDirectoryIndex(url, directoryIndex);
      shouldRespond = urlsToCacheKeys.has(url);
    }

    // If shouldRespond is still false, check to see if this is a navigation
    // request, and if so, whether the URL matches navigateFallbackWhitelist.
    var navigateFallback = '';
    if (!shouldRespond &&
        navigateFallback &&
        (event.request.mode === 'navigate') &&
        isPathWhitelisted([], event.request.url)) {
      url = new URL(navigateFallback, self.location).toString();
      shouldRespond = urlsToCacheKeys.has(url);
    }

    // If shouldRespond was set to true at any point, then call
    // event.respondWith(), using the appropriate cache key.
    if (shouldRespond) {
      event.respondWith(
        caches.open(cacheName).then(function(cache) {
          return cache.match(urlsToCacheKeys.get(url)).then(function(response) {
            if (response) {
              return response;
            }
            throw Error('The cached response that was expected is missing.');
          });
        }).catch(function(e) {
          // Fall back to just fetch()ing the request if some unexpected error
          // prevented the cached response from being valid.
          console.warn('Couldn\'t serve response for "%s" from cache: %O', event.request.url, e);
          return fetch(event.request);
        })
      );
    }
  }
});







importScripts("notification-sw.js");

