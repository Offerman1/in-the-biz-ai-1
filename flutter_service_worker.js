'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "c1397ca18c966527e2a04dbc115d604d",
".git/config": "427a28c55ec8f93b5706a3b2020bd9ad",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "03e4f9d819e97d97d0d1501e3fbb81ba",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "3d65ae1320e3812e68a9f9fb56e0fd6f",
".git/logs/refs/heads/gh-pages": "5d520d49059cd3eddd25de8e3bd9adec",
".git/logs/refs/remotes/origin/gh-pages": "9c484bd9d1e2dc4d478a750a09b12fd8",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/0c/15211ed9a281138756f99b0cfa58591cac8d78": "9f591623c96a2edf4674ac6d78edc73a",
".git/objects/0f/ee40cc40a348ad39b33c8971e764575b4e8830": "30a4e4aadde7846d7d9647e079408585",
".git/objects/22/f28effc4d69021ab4d354fe9fd8e61abab0a74": "9dcf5052520ec8442f76e7dbdd11e6d1",
".git/objects/26/6983994e59154622a1b02b8c3e7dd368a86fbd": "a8d6ae11f5f541e8cf988dcefb00c629",
".git/objects/2a/0e9bbe5025427ac777c10f1590e8d1de068e5f": "776d2c947b4396d1390e61a2f8a14856",
".git/objects/2a/eabfa76010fba5ce5503e3ed0a7c6b9e0b410a": "af3abf1478750523b02502985b074c63",
".git/objects/33/c2d583cb4ccaa271fc88c8d8ecec5208196cc7": "b4ddfab947a2fb9dd45c25d2c1de49d0",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3e/d4f4336f5ac08e337c94729d2cb874583bbd7a": "8254c0db70c7cbd106c8231f068a2056",
".git/objects/42/4a6ac7b85a9e29721579d6ca37f6a609a77866": "ee7aba207e0106133e7ad1e65ff80211",
".git/objects/43/cce53d341887fcf9568db9cdd244a90439c59b": "b351f7a000e55924188ca9e15e65c063",
".git/objects/49/3813051c0115a04c1ec7d5f3ab878ad8d6efaf": "8da8965337d0cc0ab8fbbb0b245d42b3",
".git/objects/4f/40dabe4430b4d7288c6ae92d8fc3e17cf8e410": "7c1843130f2c3787540ded5445c7793a",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/5f/2fd87c891c7377521ac63074b1771b7854fa38": "0a634defbb94653f8277861a2e994582",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6e/d964f5cea9673049af9c562e8ced18904cc954": "cbcc0af8992e61b9f9a8b793d24be2e6",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/70/4d9db20afd2dc8a377f2c8de7aa0a7c05d0448": "eec53c11255d0e25b65bb9401a8e7ffe",
".git/objects/70/b42c377f0384718b1ca5113cbbdd1191d550e5": "7de9a9bf19785abd81943eac8b7e5727",
".git/objects/78/d5a95f1b8d9fa96f74dbd3d73d3064c3bd0bbc": "ec061190bae88a99c8b7167b1f4602ea",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/7e/c26bfea68057ed80e27fec9bbbee707154cd8b": "b0be250fb837e5ec0368ae0ca5b55720",
".git/objects/82/039646eae58381941a128edf3dd254c98a2961": "ba71a4099c57c699fe2ac9b609735b8e",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/8c/954ae4321cc9fd71af9f89f37aeeb083ac50e5": "aeb8948bd360d97cbbb086ece320b4b3",
".git/objects/8e/21753cdb204192a414b235db41da6a8446c8b4": "1e467e19cabb5d3d38b8fe200c37479e",
".git/objects/92/45001ec2aa3d910da31bc23472688f9d9c5e08": "2771bc356459e54de4df278312f99b8b",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/94/59ddb92869e2f89a9da1cee643c470ceb1a142": "0395347e41476032a0a971373f61e4db",
".git/objects/95/d16a82583f5a617926cdddf0de4a77c23da8d6": "b0e7531c2196e367614df44bbb62a98b",
".git/objects/9f/7432be4537d776b8373567258a04516dfa3d44": "811330f6d16722ea84894308363f89c4",
".git/objects/a2/eaa0ba9454958f552caacda17e1c87d87376ac": "cf49bb7a37239bfec3039dbf0abf4e7b",
".git/objects/a7/3f4b23dde68ce5a05ce4c658ccd690c7f707ec": "ee275830276a88bac752feff80ed6470",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/ae/7d13fd7ffd53f594b1b19b1aecc8c0feb5020b": "a320cd97c19fbe1449e777ea16f27743",
".git/objects/b8/be37b7b8cddf89f19111dc0d739a6ec350bf23": "464dcf49523b639c94c6796cb6bd6665",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/cd/ea95759f1530a1f7e6a8d4d9a7af679e7a5638": "dd5c696f3893f877eca0e3d1a97033e5",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/da/7cf0e19fb5c76b7c73e18a1dc5e68d592084f2": "71f70ab92639b523647de16e5afb5467",
".git/objects/e5/2ebc6cf3d4f261ca21548428335956be311999": "618670b90dcb04e90d2e9ff004a97420",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/ed/d990a6b4a972cc2a0a4df30efc171244d37fe2": "404db3c3f07afc16a33b1b586b253d95",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f5/590c3a6e5ab9e640ae68c02d877485705d25d8": "1c118a829f8158a514830532950c9c91",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f6/92ce2e8a46264851784d2b9f4fa4022de6c66e": "34729389e6e5b3110c6cf5f3f27148d9",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/fc/a409d432111e29a57dd2a96201c8c2ca7545ed": "99d87bd9147f8cd474e54a239fb419d3",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/refs/heads/gh-pages": "241249a67642a2b1e115cb6015158c1b",
".git/refs/remotes/origin/gh-pages": "241249a67642a2b1e115cb6015158c1b",
"assets/AssetManifest.bin": "f6ec71c5a69ac0a809a271da0291e20f",
"assets/AssetManifest.bin.json": "8c8e0e1905d45ec10b8f105ed572cfd3",
"assets/assets/icon/app_icon.png": "936ce96f46f5e470dd8c49c53058ecd4",
"assets/assets/icon/app_icon.svg": "a2de3976cc19640c187e8882cbd5f7e1",
"assets/FontManifest.json": "c75f7af11fb9919e042ad2ee704db319",
"assets/fonts/MaterialIcons-Regular.otf": "80fad1df278f277a09ea494d9e3bc24c",
"assets/NOTICES": "5a717f6f1417c6a66425c168b36437d0",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf": "c84195a237fd2bfe4ae7a705b49d5036",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Regular-400.otf": "b2703f18eee8303425a5342dba6958db",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Solid-900.otf": "5b8d20acec3e57711717f61417c1be44",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"CNAME": "d459710bab53304321e611af170644c1",
"favicon.png": "e6bdaa9d8a1c6923d20b9a70906c0f3d",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "9b5d4ded850de92e8ee9e177b8293809",
"icons/Icon-192.png": "580b043989b3135d5f2a3eb8c95d8913",
"icons/Icon-512.png": "3736d87ceafb7b94a0f2b68f779b2779",
"icons/Icon-maskable-192.png": "580b043989b3135d5f2a3eb8c95d8913",
"icons/Icon-maskable-512.png": "3736d87ceafb7b94a0f2b68f779b2779",
"index.html": "fdf13692f5ce0d729b33418112f36ae7",
"/": "fdf13692f5ce0d729b33418112f36ae7",
"main.dart.js": "deac908dcd13098e8e8e0c33491cbadd",
"manifest.json": "2643e8f0e390049a4a96b0c3ff59093c",
"version.json": "11808a529ddc21c9804888b0ef621892"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
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
