// ReqLab — service worker (PWA + notificações)
self.addEventListener('install', function () { self.skipWaiting(); });
self.addEventListener('activate', function (e) { e.waitUntil(self.clients.claim()); });

// recebe push de fundo (quando houver servidor disparando)
self.addEventListener('push', function (e) {
  var data = {};
  try { data = e.data ? e.data.json() : {}; } catch (_) {}
  e.waitUntil(self.registration.showNotification(data.title || 'ReqLab', {
    body: data.body || 'Você tem uma tarefa pendente.',
    icon: 'assets/icone-app.png',
    badge: 'assets/icone-app.png'
  }));
});

self.addEventListener('notificationclick', function (e) {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: 'window' }).then(function (cl) {
    for (var i = 0; i < cl.length; i++) { if ('focus' in cl[i]) return cl[i].focus(); }
    if (self.clients.openWindow) return self.clients.openWindow('./');
  }));
});
