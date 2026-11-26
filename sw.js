// Offline support: keeps a copy of the app on the device.
const CACHE = "galesh-sheet-v5";
const SHELL = ["./", "./index.html", "./config.js", "./supabase.js", "./manifest.webmanifest",
  "./icon-192.png", "./icon-512.png", "./icon-maskable-512.png"];

// A newer copy of the page was downloaded: tell open pages so they can offer a reload.
const stamp = r => r.headers.get("etag") || r.headers.get("last-modified");
const changed = (oldRes, newRes) => { const a = stamp(oldRes), b = stamp(newRes); return !!(a && b && a !== b); };
const tellPages = () => {
  const send = () => self.clients.matchAll({ type: "window" }).then(cs => cs.forEach(c => c.postMessage({ type: "update" })));
  return send().then(() => new Promise(r => setTimeout(r, 3000))).then(send); // again later, in case the page wasn't ready yet
};

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});
self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  const sameOrigin = url.origin === self.location.origin;
  const isFont = url.hostname === "fonts.googleapis.com" || url.hostname === "fonts.gstatic.com";
  if (!sameOrigin && !isFont) return; // sync traffic goes straight to the network
  // Only answer for this app's own pages. Anything else under the site (like /town) goes to the network.
  const rel = url.pathname.slice(new URL(self.registration.scope).pathname.length);
  if (sameOrigin && /^town(\/|$)/.test(rel)) return;
  if (req.mode === "navigate" && !(rel === "" || rel === "index.html")) return;

  if (isFont) {
    e.respondWith(caches.match(req).then(hit => hit || fetch(req).then(res => {
      const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); return res;
    }).catch(() => hit)));
    return;
  }
  // App files: answer from the device instantly, refresh the copy in the background.
  e.respondWith(caches.open(CACHE).then(async cache => {
    const key = req.mode === "navigate" ? "./index.html" : req;
    const hit = await cache.match(key, { ignoreSearch: true });
    const net = fetch(req).then(async res => {
      if (res && res.ok) {
        const fresh = res.clone();
        await cache.put(key, res.clone());
        if (hit && req.mode === "navigate" && changed(hit, fresh)) await tellPages();
      }
      return res;
    }).catch(() => null);
    if (hit) { e.waitUntil(net); return hit; }
    const res = await net;
    return res || new Response("Offline and this file isn’t saved yet.", { status: 503 });
  }));
});
