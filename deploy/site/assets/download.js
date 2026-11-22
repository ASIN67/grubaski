(() => {
  const release = window.grubasekRelease ?? {};

  function showVersionWhenVisible(info, url, label, readVersion) {
    async function loadVersion() {
      try {
        const response = await fetch(url, { credentials: "omit", referrerPolicy: "no-referrer", cache: "no-cache" });
        if (!response.ok) return;
        const version = readVersion(await response.json());
        if (typeof version === "string" && /^\d+\.\d+\.\d+(?:[-+][\w.-]+)?$/.test(version)) {
          info.textContent = `${label} · wersja ${version}`;
        }
      } catch {
        // Installation links remain available when version metadata cannot be read.
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
      const info = document.querySelector("#release-info");
      if (release.version) info.textContent = `APK · ARM64 · wersja ${release.version}`;
      if (release.releaseInfoUrl) {
        showVersionWhenVisible(info, release.releaseInfoUrl, "APK · ARM64", ({ name }) =>
          /^Grubasek (\S+) \(Android APK\)$/.exec(name)?.[1]);
      }
    }
  }

  showVersionWhenVisible(document.querySelector("#web-release-info"), "/app/version.json",
    "Aplikacja webowa", ({ version }) => version);
})();

