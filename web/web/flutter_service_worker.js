'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "aaf8a744f664699bfa8d74ea93086b8e",
"assets/AssetManifest.bin.json": "a00ec6885d896951c8f4297954893d8e",
"assets/AssetManifest.json": "60e0f2d34311b2192a07c8532a0229ea",
"assets/assets/1.png": "5d6148911fdd4a04f0b62deb983caca4",
"assets/assets/10_db_purchase.png": "e7a099ceb56ee2d468e9f9a121813d29",
"assets/assets/11_db_attendance.png": "aa7da419018e82a3d534ce92db721d38",
"assets/assets/12_db_dailywork.png": "518898b41795c4f0ced7bf423f97da23",
"assets/assets/1_db_sales.png": "d226fcf3caf42ca373f087aa6b8f9cab",
"assets/assets/2_db_pocreate.png": "0c17943d15f591a570db5e0d7ed89dfc",
"assets/assets/3_db_shiftentry.png": "86430dda39cef3a750d001067dbacf43",
"assets/assets/4_db_deliverychallen.png": "e502cd20fdcf64cd8c81787f9f7df17b",
"assets/assets/5_db_employee.png": "da16123e3113dbcdb0e2dd538228da56",
"assets/assets/6_db_productionstock.png": "0c17943d15f591a570db5e0d7ed89dfc",
"assets/assets/8_db_fingerprint.png": "6c403464d492e1cc1bc94e01328c90aa",
"assets/assets/9_db_rawmaterial.jpg": "5f20e5b7932ad8dead2e8d6a25ffb1b8",
"assets/assets/ad_im1.png": "3180335cf9e97c99978157fe704617de",
"assets/assets/ad_im10.jpg": "29496ef39a000b1d9e7287ffd770200b",
"assets/assets/ad_im11.jpg": "c9dab78ac7eee61d9acc469f3d7abe36",
"assets/assets/ad_im12.png": "fc05575d42806348bd878a6923e69907",
"assets/assets/ad_im13.png": "0b315895a1d5aa7132a70f28708ddf82",
"assets/assets/ad_im14.jpg": "d7ee73e140b7fd0a6f6e61919a022c13",
"assets/assets/ad_im15.jpg": "6efaf59877a03f32d65b10f7eafb12b0",
"assets/assets/ad_im16.png": "502728bcce2feae08be0e5082c45e604",
"assets/assets/ad_im17.jpg": "d66d85cb8c4c22da292ba7d312e04c24",
"assets/assets/ad_im18.jpg": "b9ccb72d45ede80dc90f1d96368d6328",
"assets/assets/ad_im19.jpg": "143813d4c0e2b9e86ea7f886aba7fab1",
"assets/assets/ad_im2.png": "98ba9a2bc5d674e9e42be9c0b3b33f4e",
"assets/assets/ad_im3.png": "bb9452a313c86312401f59e63f2bf11e",
"assets/assets/ad_im4.png": "81a3c0977ac8a22a79720357bf7ede1a",
"assets/assets/ad_im5.png": "4e24ddf374377a5d61097a7945ef6973",
"assets/assets/ad_im6.jpg": "9a3d48778af5e2a2d059300bbbe396f4",
"assets/assets/ad_im7.jpg": "0a7b02c1b83c9091f15dd802c5c8d037",
"assets/assets/ad_im8.jpg": "aee328c4721778229e4db29cbadfe1e4",
"assets/assets/attendance.png": "da4596b6ebfe04bf05c9e6e00bf385da",
"assets/assets/bg21.jpg": "95f344aa29fd1e36b2524d1709311805",
"assets/assets/bg22.svg": "c4bf7f17cbd556d24ae67f42ef3ccec8",
"assets/assets/bg_1.jpg": "8a59e12362bc93a33599fcfec3680947",
"assets/assets/bg_10.jpg": "9455c98be6adcd44b86bbae79efd426b",
"assets/assets/bg_11.jpg": "f566afb8d19f728bb212c49a05446f71",
"assets/assets/bg_12.jpg": "7983ed954b7d9e7254dba4711adfac8a",
"assets/assets/bg_13.jpg": "9657375ed7940db7bd07ca174f4b63f4",
"assets/assets/bg_14.png": "04c2c080c26d897cb03682f1388e2d1a",
"assets/assets/bg_15.jpg": "27a705eccfc790026e776eb6f2e9f7b4",
"assets/assets/bg_16.png": "7530d876f6005b1b575ea11a4c37c042",
"assets/assets/bg_17.png": "198f12653fe102e91b8b6a4acce6c1e4",
"assets/assets/bg_18.jpg": "38b5d52829bf6dd2e4fb3d6d016370a6",
"assets/assets/bg_19.jpg": "63a5e886387070846d54e34a9948fec3",
"assets/assets/bg_2.jpg": "8a59e12362bc93a33599fcfec3680947",
"assets/assets/bg_20.jpg": "056edf384c9b1b3b0cc8ab80b4d78191",
"assets/assets/bg_21.jpg": "de8b5f7a8d635a59e3e00543e551acb3",
"assets/assets/bg_22.jpg": "0dbd64da67d527435f2b53d6d1d5bb22",
"assets/assets/bg_23.png": "7c944a98f28f5f35af7fe1eee100fddc",
"assets/assets/bg_3.jpg": "0811293c6c0319b02d9c0c22566e7800",
"assets/assets/bg_4.jpg": "5b0f0ea12af04dda7c3b7bd34a816350",
"assets/assets/bg_5.jpg": "712ccb1b078999ccb53f58a3b32b4c74",
"assets/assets/bg_7.jpg": "1670fbd7e690b082db98aae585318b52",
"assets/assets/bg_8.jpg": "a383b6a6239259594b2d45b6711adcb0",
"assets/assets/bg_9.jpg": "35f8d1baa10ad9ed6441887414181f9f",
"assets/assets/customerorder.JPEG": "3aa66c4b72bc3edc5c544dde13471410",
"assets/assets/custorder.JPEG": "44e8c040064d78b85e73c10838d3f2d3",
"assets/assets/cutomer_order.jpg": "547c49d09b80d3b2070c2f7ee53abdce",
"assets/assets/dailyworkstatus.JPEG": "8115656c84ff73495a8b28356e902797",
"assets/assets/delivery.png": "fb5de7aeea8a17cca885a01bd4e0db12",
"assets/assets/deliverycha.JPEG": "a439f4e327b178d33f9674f2eb294075",
"assets/assets/employee.JPEG": "eee1a59a2972fe23745cd52201ef6aad",
"assets/assets/employee1.png": "da16123e3113dbcdb0e2dd538228da56",
"assets/assets/ewaybill1.png": "973274ebb4ba9f78bf83a52034b81df9",
"assets/assets/fb.JPEG": "83715296f3b78b20a69820acca1e6440",
"assets/assets/fingerprint.png": "205a5a28236459934e0abf1644dbad39",
"assets/assets/fonts/Algerian_Regular.ttf": "b60bb3c69fd2ba6576a27f876ea95042",
"assets/assets/ganpati_images.jpg": "e186e71aedb6068ce53fa416492604b4",
"assets/assets/god1.jpg": "20fb7f3eb349da8e6d5f034aff92eb07",
"assets/assets/god2.jpg": "918b408f19e080093abc119b4aeb603a",
"assets/assets/god3.jpg": "8c467fd0122da69f4e6db20933ef0b7b",
"assets/assets/image_2023_10_11T05_48_45_096Z.png": "205a5a28236459934e0abf1644dbad39",
"assets/assets/image_2023_10_11T05_48_45_099Z.png": "0c17943d15f591a570db5e0d7ed89dfc",
"assets/assets/image_2023_10_11T05_48_45_102Z.png": "da16123e3113dbcdb0e2dd538228da56",
"assets/assets/image_2023_10_11T05_53_27_876Z.png": "a7c086aef5f473f17af3b97623097a63",
"assets/assets/pillaiyar.png": "9c438402ace7ce2df3a6c692f7d7a72f",
"assets/assets/pocreate1.png": "0c17943d15f591a570db5e0d7ed89dfc",
"assets/assets/production.JPEG": "faa4e849f232a945de0b9e614c919de2",
"assets/assets/purchaeentry.JPEG": "afb9070df2961a1e79830251dc7049ab",
"assets/assets/purchaeorder.JPEG": "1a6a0e07f1efd40c09337e5bdbc2af9c",
"assets/assets/purchase1.png": "572a2cc61ae67c3588ed7e22c7b6e7f4",
"assets/assets/purchaseentry2.JPEG": "cccae5a0bcbcbd7f8e8dd933d101d05e",
"assets/assets/rawmaterial.JPEG": "243469ff63ac589a1bfb0abd0e4abbba",
"assets/assets/sale1.png": "1451174940565f7ace1d6d6d5a4fbd28",
"assets/assets/sales.JPEG": "2649a6d08055089647a1bcd6da79b18e",
"assets/assets/sarswathi.png": "92ca765059bce437b775cf6de558cd5c",
"assets/assets/shiftentry.JPEG": "63c22cdd78afdcd5e84bb7241da203dc",
"assets/FontManifest.json": "317019604bef262e2772a3d02431737e",
"assets/fonts/MaterialIcons-Regular.otf": "e7069dfd19b331be16bed984668fe080",
"assets/NOTICES": "b0ae384e240330f435141c00079fc63a",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "6d342eb68f170c97609e9da345464e5e",
"assets/shaders/ink_sparkle.frag": "4096b5150bac93c41cbc9b45276bd90f",
"canvaskit/canvaskit.js": "eb8797020acdbdf96a12fb0405582c1b",
"canvaskit/canvaskit.wasm": "73584c1a3367e3eaf757647a8f5c5989",
"canvaskit/chromium/canvaskit.js": "0ae8bbcc58155679458a0f7a00f66873",
"canvaskit/chromium/canvaskit.wasm": "143af6ff368f9cd21c863bfa4274c406",
"canvaskit/skwasm.js": "87063acf45c5e1ab9565dcf06b0c18b8",
"canvaskit/skwasm.wasm": "2fc47c0a0c3c7af8542b601634fe9674",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "59a12ab9d00ae8f8096fffc417b6e84f",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "10515a9143b60b0f785ad66ccec100f1",
"/": "10515a9143b60b0f785ad66ccec100f1",
"main.dart.js": "126be66aece1c964dad094f222a6c0ad",
"manifest.json": "b10d8a238a98e6740310a1e2a7febdc4",
"version.json": "68b6e809e2323beb69fcf9308ea6e4f2"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
