const CACHE_NAME = 'blitzlesen-isabella-v32';
const CACHE_PREFIX = 'blitzlesen-isabella-';
const PRECACHE_URLS = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/apple-touch-icon.png'
];

function putInCache(request, response) {
  if (!response || response.status !== 200 || response.type === 'opaque') return response;
  const copy = response.clone();
  caches.open(CACHE_NAME).then(cache => cache.put(request, copy)).catch(() => {});
  return response;
}

function networkFirst(request) {
  return fetch(request)
    .then(response => putInCache(request, response))
    .catch(() => caches.match(request));
}

function cacheFirst(request) {
  return caches.match(request).then(cached => {
    if (cached) return cached;
    return fetch(request).then(response => putInCache(request, response));
  });
}

function isNavigationRequest(request) {
  return request.mode === 'navigate';
}

function isNetworkFirstRequest(request, url) {
  return isNavigationRequest(request) ||
    url.pathname.endsWith('/index.html') ||
    url.pathname.endsWith('/manifest.webmanifest');
}

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(PRECACHE_URLS)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys
        .filter(key => key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME)
        .map(key => caches.delete(key))
    )).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);

  if (url.origin !== self.location.origin) {
    event.respondWith(networkFirst(request));
    return;
  }

  if (isNetworkFirstRequest(request, url)) {
    event.respondWith(networkFirst(request));
    return;
  }

  event.respondWith(cacheFirst(request));
});
