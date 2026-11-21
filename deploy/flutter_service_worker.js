const version = "__REVISION__";
const shellFiles = __SHELL_FILES__;

const cachePrefix = 'grubasek-app-';
const cacheName = cachePrefix + version;
const scope = new URL(self.registration.scope);

const urlFor = (filename) => new URL(filename, scope).href;
const indexUrl = urlFor('./');
const indexAlias = new URL('index.html', scope).pathname;
const shellUrls = new Set(shellFiles.map(urlFor));

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(cacheName);
    await cache.addAll([...shellUrls].map((url) => new Request(url, { cache: 'reload' })));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter((name) =>
      name.startsWith(cachePrefix) && name !== cacheName
    ).map((name) => caches.delete(name)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== scope.origin || !url.pathname.startsWith(scope.pathname)) return;

  const isIndex = url.pathname === scope.pathname || url.pathname === indexAlias;
  const shellUrl = isIndex ? indexUrl : url.origin + url.pathname;
  if (!shellUrls.has(shellUrl)) return;
  event.respondWith((async () => {
    const cache = await caches.open(cacheName);
    try {
      return await fetch(request);
    } catch (error) {
      const cached = await cache.match(shellUrl);
      if (cached) return cached;
      throw error;
    }
  })());
});
