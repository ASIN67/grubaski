(() => {
  const release = window.grubasekRelease;
  if (!release) return;

  function showVersionWhenVisible(info) {
    const setVersion = (version) => { info.textContent = `APK · ARM64 · wersja ${version}`; };
    if (release.version) setVersion(release.version);
    if (!release.releaseInfoUrl) return;

    async function loadVersion() {
      try {
        const response = await fetch(release.releaseInfoUrl, { credentials: "omit", referrerPolicy: "no-referrer" });
        if (!response.ok) return;
        const { name } = await response.json();
        const match = /^Grubasek (\d+\.\d+\.\d+[\w.+-]*) \(Android APK\)$/.exec(name);
        if (match) setVersion(match[1]);
      } catch {
        // The download links also work when GitHub metadata is unavailable.
      }
    }

    if (!("IntersectionObserver" in window)) {
      loadVersion();
      return;
    }
    const observer = new IntersectionObserver((entries) => {
      if (!entries.some((entry) => entry.isIntersecting)) return;
      observer.disconnect();
      loadVersion();
    }, { rootMargin: "350px" });
    observer.observe(info);
  }

  for (const link of document.querySelectorAll("[data-apk-download]")) {
    const key = link.dataset.apkDownload;
    if (!release[key]) continue;

    let url;
    try {
      url = new URL(release[key], document.baseURI);
    } catch {
      continue;
    }

    const localApk = url.origin === location.origin && url.protocol === location.protocol &&
      url.pathname.toLowerCase().endsWith(".apk");
    if (url.protocol !== "https:" && !localApk) continue;

    link.href = url.href;
    if (localApk) link.download = "";
    link.hidden = false;

    if (key === "url" && link.closest(".release-card")) {
      document.querySelector("#release-fallback").hidden = true;
      showVersionWhenVisible(document.querySelector("#release-info"));
    }
  }
})();

