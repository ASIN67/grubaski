const startup = document.getElementById('startup');

window.addEventListener('flutter-first-frame', () => startup.remove(), { once: true });

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/app/flutter_service_worker.js', {
    scope: '/app/',
    updateViaCache: 'none',
  }).catch((error) => console.warn('Nie udało się zapisać aplikacji do pracy offline.', error));
}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: '/app/canvaskit/',
    canvasKitVariant: 'full',
  },
}).catch((error) => {
  console.error(error);
  document.getElementById('startup-message').textContent = 'Nie udało się uruchomić aplikacji.';
  document.getElementById('startup-retry').hidden = false;
});
