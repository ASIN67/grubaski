(() => {
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const finePointer = window.matchMedia("(hover: hover) and (pointer: fine)");

  function isInViewport(rect, viewport = window.innerHeight) {
    return rect.height > 0 && rect.bottom > 0 && rect.top < viewport;
  }

  function initReveals() {
    const pending = new Set(document.querySelectorAll("[data-reveal]"));
    if (!pending.size || reducedMotion.matches || !("IntersectionObserver" in window)) return;

    const root = document.documentElement;
    const observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) reveal(entry.target);
      }
    }, { rootMargin: "0px 0px -28px 0px" });

    function reveal(element, immediate = false) {
      if (immediate) element.classList.add("is-immediate");
      element.classList.add("is-visible");
      if (pending.delete(element)) observer.unobserve(element);
    }

    function revealContaining(target) {
      for (let element = target; element; element = element.parentElement) {
        if (element.hasAttribute("data-reveal")) reveal(element, true);
      }
    }

    function revealViewport(immediate = false, within = document) {
      for (const element of pending) {
        if (within.contains(element) && isInViewport(element.getBoundingClientRect())) {
          reveal(element, immediate);
        }
      }
    }

    function revealAnchor() {
      const hash = window.location.hash.slice(1);
      if (!hash) return;

      let id = hash;
      try {
        id = decodeURIComponent(hash);
      } catch {
        // An invalid escape can still be part of a literal element ID.
      }
      const target = document.getElementById(id);
      if (!target) return;

      revealContaining(target);
      const headingId = target.getAttribute("aria-labelledby")?.split(/\s+/)[0];
      if (headingId) revealContaining(document.getElementById(headingId));
      revealViewport(true, target);
    }

    revealViewport(true);
    revealAnchor();
    revealContaining(document.activeElement);
    for (const element of pending) observer.observe(element);

    document.addEventListener("focusin", (event) => revealContaining(event.target));
    window.addEventListener("hashchange", revealAnchor);
    window.addEventListener("pageshow", (event) => {
      if (event.persisted) revealViewport(true);
    });
    window.addEventListener("beforeprint", () => {
      for (const element of pending) reveal(element, true);
    }, { once: true });
    reducedMotion.addEventListener?.("change", () => {
      if (!reducedMotion.matches) return;
      root.classList.remove("motion-ready");
      for (const element of pending) reveal(element, true);
      observer.disconnect();
    });

    root.classList.add("motion-ready");
    return revealViewport;
  }

  function initScrollFeedback(revealAtBottom) {
    const header = document.querySelector(".site-header");
    const progress = document.querySelector("[data-scroll-progress]");
    const artwork = [...document.querySelectorAll("[data-scroll-art]")];
    if (!header && !progress && !artwork.length && !revealAtBottom) return;

    const visibleArt = new Set();
    let frame = 0;
    const artObserver = artwork.length && "IntersectionObserver" in window
      ? new IntersectionObserver((entries) => {
        if (reducedMotion.matches) return;
        for (const entry of entries) {
          if (entry.isIntersecting) {
            visibleArt.add(entry.target);
          } else {
            visibleArt.delete(entry.target);
          }
        }
        requestUpdate();
      })
      : null;

    function update() {
      frame = 0;
      const offset = Math.max(0, window.scrollY);
      const viewport = window.innerHeight;
      const distance = document.documentElement.scrollHeight - viewport;
      const drifts = [];

      if (!reducedMotion.matches) {
        for (const art of visibleArt) {
          const rect = art.getBoundingClientRect();
          if (!isInViewport(rect, viewport)) continue;
          const center = rect.top + rect.height / 2;
          const passage = (viewport - 2 * center) / (viewport + rect.height);
          drifts.push([art, Math.round(Math.max(-1, Math.min(1, passage)) * 24)]);
        }
      }

      if (distance - offset <= 2) revealAtBottom?.();
      header?.classList.toggle("is-scrolled", offset > 12);

      if (progress) {
        progress.style.setProperty("--progress", distance > 0 ? Math.min(1, offset / distance) : 0);
      }

      for (const [art, drift] of drifts) {
        art.style.setProperty("--scroll-drift", `${drift}px`);
      }
    }

    function requestUpdate() {
      if (!frame) frame = window.requestAnimationFrame(update);
    }

    function syncArtPreference() {
      if (!artObserver) return;
      if (reducedMotion.matches) {
        artObserver.disconnect();
        visibleArt.clear();
        for (const art of artwork) art.style.removeProperty("--scroll-drift");
      } else {
        for (const art of artwork) artObserver.observe(art);
      }
    }

    window.addEventListener("scroll", requestUpdate, { passive: true });
    window.addEventListener("resize", requestUpdate);
    window.addEventListener("pageshow", requestUpdate);
    if ("ResizeObserver" in window) {
      new ResizeObserver(requestUpdate).observe(document.body);
    }
    reducedMotion.addEventListener?.("change", syncArtPreference);
    syncArtPreference();
    update();
  }

  function initParallax() {
    const art = document.querySelector("[data-parallax]");
    if (!art) return;

    let frame = 0;
    let pointerX = 0;
    let pointerY = 0;

    function reset() {
      if (frame) window.cancelAnimationFrame(frame);
      frame = 0;
      art.style.removeProperty("--pan-x");
      art.style.removeProperty("--pan-y");
    }

    art.addEventListener("pointermove", (event) => {
      if (reducedMotion.matches || !finePointer.matches || event.pointerType === "touch") return;

      pointerX = event.clientX;
      pointerY = event.clientY;
      if (frame) return;

      frame = window.requestAnimationFrame(() => {
        frame = 0;
        const rect = art.getBoundingClientRect();
        if (!rect.width || !rect.height) return;

        const x = Math.min(1, Math.max(-1, 2 * (pointerX - rect.left) / rect.width - 1));
        const y = Math.min(1, Math.max(-1, 2 * (pointerY - rect.top) / rect.height - 1));
        art.style.setProperty("--pan-x", `${x * 8}px`);
        art.style.setProperty("--pan-y", `${y * 6}px`);
      });
    }, { passive: true });

    art.addEventListener("pointerleave", reset);
    art.addEventListener("pointercancel", reset);
    reducedMotion.addEventListener?.("change", reset);
    finePointer.addEventListener?.("change", reset);
  }

  function initTabs() {
    document.querySelectorAll("[data-demo]").forEach((demo, demoIndex) => {
      const list = demo.querySelector("[data-demo-tabs]");
      if (!list) return;

      const tabs = [...list.querySelectorAll("button[data-demo-tab]")];
      const availablePanels = [...demo.querySelectorAll("[data-demo-panel]")]
        .filter((panel) => panel.closest("[data-demo]") === demo);
      const panels = tabs.map((tab) => availablePanels.find(
        (panel) => panel.dataset.demoPanel === tab.dataset.demoTab,
      ));
      if (tabs.length < 2 || panels.some((panel) => !panel) || new Set(panels).size !== tabs.length) return;

      list.setAttribute("role", "tablist");
      if (!list.hasAttribute("aria-label") && !list.hasAttribute("aria-labelledby")) {
        list.setAttribute("aria-label", "Ekrany aplikacji");
      }
      const vertical = list.getAttribute("aria-orientation") === "vertical";
      const previousKey = vertical ? "ArrowUp" : "ArrowLeft";
      const nextKey = vertical ? "ArrowDown" : "ArrowRight";

      function select(index, { focus = false, showPanel = false } = {}) {
        tabs.forEach((tab, tabIndex) => {
          const selected = tabIndex === index;
          tab.setAttribute("aria-selected", String(selected));
          tab.tabIndex = selected ? 0 : -1;
          panels[tabIndex].hidden = !selected;
        });
        if (showPanel && panels[index].hasAttribute("data-reveal")) {
          panels[index].classList.add("is-immediate", "is-visible");
        }
        if (focus) tabs[index].focus({ preventScroll: true });
      }

      tabs.forEach((tab, index) => {
        const panel = panels[index];
        const id = `grubasek-demo-${demoIndex + 1}-${index + 1}`;
        tab.id ||= `${id}-tab`;
        panel.id ||= `${id}-panel`;
        tab.type = "button";
        tab.setAttribute("role", "tab");
        tab.setAttribute("aria-controls", panel.id);
        panel.setAttribute("role", "tabpanel");
        panel.setAttribute("aria-labelledby", tab.id);
        panel.tabIndex = 0;

        tab.addEventListener("click", () => select(index, { showPanel: true }));
        tab.addEventListener("keydown", (event) => {
          let destination;
          switch (event.key) {
            case previousKey:
              destination = (index + tabs.length - 1) % tabs.length;
              break;
            case nextKey:
              destination = (index + 1) % tabs.length;
              break;
            case "Home":
              destination = 0;
              break;
            case "End":
              destination = tabs.length - 1;
              break;
            default:
              return;
          }
          event.preventDefault();
          select(destination, { focus: true, showPanel: true });
        });
      });

      select(0);
      list.hidden = false;
    });
  }

  function initScreenPreview() {
    const dialog = document.querySelector(".preview-dialog");
    if (!dialog || typeof dialog.showModal !== "function") return;

    const title = dialog.querySelector("h2");
    const image = dialog.querySelector("img");
    let opener;

    for (const link of document.querySelectorAll("[data-screen-preview]")) {
      link.setAttribute("aria-haspopup", "dialog");
      link.addEventListener("click", (event) => {
        if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey || event.button !== 0) return;
        event.preventDefault();
        opener = link;
        title.textContent = link.dataset.screenPreview;
        image.src = link.href;
        image.alt = link.querySelector("img").alt;
        dialog.showModal();
        image.parentElement.scrollTop = 0;
      });
    }

    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) dialog.close();
    });
    dialog.addEventListener("close", () => opener?.focus({ preventScroll: true }));
  }

  initTabs();
  initScreenPreview();
  initScrollFeedback(initReveals());
  initParallax();
})();
