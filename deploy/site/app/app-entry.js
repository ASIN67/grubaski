(() => {
  const startup = document.getElementById('startup');
  const guide = document.getElementById('ios-guide');
  const bootstrapUrl = document.currentScript.dataset.bootstrap;
  const url = new URL(window.location.href);
  const storageKey = 'grubasek.ios-guide-read';

  const fromInstallLink = url.searchParams.get('instalacja') === 'ios';
  const isIOS = /iPhone|iPad|iPod/.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  const isInstalled = navigator.standalone === true ||
    window.matchMedia('(display-mode: standalone)').matches;

  function hasReadGuide() {
    try {
      return window.localStorage.getItem(storageKey) === 'yes';
    } catch {
      return false;
    }
  }

  function startApp() {
    guide.hidden = true;
    startup.hidden = false;

    const bootstrap = document.createElement('script');
    bootstrap.src = bootstrapUrl;
    bootstrap.addEventListener('error', () => {
      document.getElementById('startup-message').textContent = 'Nie udało się uruchomić aplikacji.';
      document.getElementById('startup-retry').hidden = false;
    }, { once: true });
    document.head.append(bootstrap);
  }

  if (isInstalled || (!fromInstallLink && (!isIOS || hasReadGuide()))) {
    startApp();
    return;
  }

  startup.hidden = true;
  guide.hidden = false;
  document.getElementById('ios-guide-title').focus({ preventScroll: true });

  document.getElementById('ios-guide-continue').addEventListener('click', () => {
    try {
      window.localStorage.setItem(storageKey, 'yes');
    } catch {
      // The app can still open when the browser blocks storage.
    }

    if (fromInstallLink) {
      url.searchParams.delete('instalacja');
      window.history.replaceState(window.history.state, '', url);
    }

    startApp();
  }, { once: true });
})();
