(() => {
  const release = window.grubasekRelease;
  if (!release?.url) return;

  let url;
  try {
    url = new URL(release.url, document.baseURI);
  } catch {
    return;
  }

  const localApk =
    url.protocol === location.protocol &&
    url.origin === location.origin &&
    url.pathname.toLowerCase().endsWith(".apk");
  if (url.protocol !== "https:" && !localApk) return;

  const link = document.querySelector("#release-download");
  link.href = url.href;
  if (localApk) link.download = "";
  if (release.version) {
    document.querySelector("#release-info").textContent = `Plik instalacyjny APK · wersja ${release.version}`;
  }
  document.querySelector("#release-status").hidden = true;
  link.hidden = false;
})();

