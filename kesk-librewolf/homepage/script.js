(function () {
  const form = document.getElementById("searchForm");
  const input = document.getElementById("searchInput");
  const hint = document.getElementById("hint");
  const clock = document.getElementById("clock");

  const adsBlocked = document.getElementById("adsBlocked");
  const trackersBlocked = document.getElementById("trackersBlocked");
  const fingerprintShield = document.getElementById("fingerprintShield");
  const cookieIsolation = document.getElementById("cookieIsolation");
  const httpsMode = document.getElementById("httpsMode");
  const sessionTrace = document.getElementById("sessionTrace");
  const protectionBus = document.getElementById("protectionBus");
  const protectionBusText = document.getElementById("protectionBusText");
  const uptimeText = document.getElementById("uptimeText");
  const localNode = document.getElementById("localNode");

  if (!form || !input || !hint) {
    return;
  }

  const sessionStart = Date.now();
  const directSchemePattern = /^(https?:\/\/|file:\/\/|about:)/i;
  const localhostPattern = /^localhost(:\d+)?(\/.*)?$/i;
  const ipv4Pattern = /^(\d{1,3}\.){3}\d{1,3}(:\d+)?(\/.*)?$/;
  const hostnamePattern = /^[a-z0-9-]+(\.[a-z0-9-]+)+(:\d+)?(\/.*)?$/i;
  const probeTimeoutMs = 3500;

  const adProbeUrls = [
    "https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js",
    "https://securepubads.g.doubleclick.net/tag/js/gpt.js",
    "https://static.criteo.net/js/ld/ld.js",
    "https://cdn.taboola.com/libtrc/unip/loader.js"
  ];

  const trackerProbeUrls = [
    "https://www.google-analytics.com/analytics.js",
    "https://www.googletagmanager.com/gtm.js?id=GTM-KESKOS",
    "https://connect.facebook.net/en_US/fbevents.js",
    "https://bat.bing.com/bat.js"
  ];

  function updateClock() {
    const now = new Date();
    const time = now.toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit"
    });
    clock.textContent = `SIGNAL READY // ${time}`;
  }

  function looksLikeUrl(value) {
    const trimmed = value.trim();

    if (directSchemePattern.test(trimmed)) {
      return true;
    }
    if (localhostPattern.test(trimmed)) {
      return true;
    }
    if (ipv4Pattern.test(trimmed)) {
      return true;
    }

    return hostnamePattern.test(trimmed);
  }

  function normalizeUrl(value) {
    const trimmed = value.trim();

    if (directSchemePattern.test(trimmed)) {
      return trimmed;
    }
    if (localhostPattern.test(trimmed) || ipv4Pattern.test(trimmed)) {
      return `http://${trimmed}`;
    }
    return `https://${trimmed}`;
  }

  function updateHintForValue(value) {
    const trimmed = value.trim();

    if (!trimmed) {
      hint.innerHTML = 'ENTER EXECUTE · URL DIRECT OPEN · QUERY DUCKDUCKGO <span class="blink">█</span>';
      return;
    }

    if (looksLikeUrl(trimmed)) {
      hint.innerHTML = 'DIRECT WEB SIGNAL DETECTED <span class="blink">█</span>';
      return;
    }

    hint.innerHTML = 'SEARCH SIGNAL ROUTED THROUGH DUCKDUCKGO <span class="blink">█</span>';
  }

  function updateStaticSignals() {
    const privacySignals = [];
    if (navigator.globalPrivacyControl === true) {
      privacySignals.push("GPC");
    }
    if (navigator.doNotTrack === "1" || window.doNotTrack === "1") {
      privacySignals.push("DNT");
    }

    fingerprintShield.textContent = privacySignals.length > 0 ? "ACTIVE" : "UNKNOWN";
    const storageAvailable = typeof localStorage !== "undefined" && typeof sessionStorage !== "undefined";
    cookieIsolation.textContent = storageAvailable ? "PROFILE" : "LIMITED";
    httpsMode.textContent = "PREFERRED";
    sessionTrace.textContent = "LIVE";

    if (window.location.protocol === "file:") {
      localNode.textContent = "KESK-OS // LOCAL";
    } else {
      localNode.textContent = "KESK-OS // REMOTE";
    }
  }

  async function probeUrl(url) {
    const controller = new AbortController();
    const timeoutId = window.setTimeout(function () {
      controller.abort();
    }, probeTimeoutMs);

    const separator = url.includes("?") ? "&" : "?";
    const cacheBusted = `${url}${separator}kesk_probe=${Date.now()}`;

    try {
      await fetch(cacheBusted, {
        method: "GET",
        mode: "no-cors",
        cache: "no-store",
        credentials: "omit",
        signal: controller.signal
      });
      return "loaded";
    } catch (error) {
      if (error && error.name === "AbortError") {
        return "blocked";
      }
      return "blocked";
    } finally {
      window.clearTimeout(timeoutId);
    }
  }

  async function runProbeSet(urls) {
    const results = await Promise.all(urls.map(probeUrl));
    let blocked = 0;
    let loaded = 0;

    for (const result of results) {
      if (result === "loaded") {
        loaded += 1;
      } else {
        blocked += 1;
      }
    }

    return {
      total: urls.length,
      blocked,
      loaded
    };
  }

  function busBar(total, blocked) {
    const width = 10;
    const filled = total > 0 ? Math.round((blocked / total) * width) : 0;
    return `${"█".repeat(filled)}${"░".repeat(Math.max(0, width - filled))}`;
  }

  async function updateProtectionStats() {
    hint.innerHTML = 'RUNNING PROTECTION PROBES <span class="blink">█</span>';

    const [ads, trackers] = await Promise.all([
      runProbeSet(adProbeUrls),
      runProbeSet(trackerProbeUrls)
    ]);

    const total = ads.total + trackers.total;
    const blocked = ads.blocked + trackers.blocked;

    adsBlocked.textContent = String(ads.blocked).padStart(2, "0");
    trackersBlocked.textContent = String(trackers.blocked).padStart(2, "0");
    protectionBus.textContent = busBar(total, blocked);

    if (!navigator.onLine) {
      protectionBusText.textContent = "offline session detected - probe results may be inflated";
      protectionBusText.classList.add("warn");
    } else {
      protectionBusText.textContent = `${blocked}/${total} probe routes denied by the current browser protection layer`;
      protectionBusText.classList.remove("warn");
    }

    updateHintForValue(input.value);
  }

  function updateUptime() {
    const uptimeSeconds = Math.floor((Date.now() - sessionStart) / 1000);
    const minutes = Math.floor(uptimeSeconds / 60);
    const seconds = String(uptimeSeconds % 60).padStart(2, "0");
    uptimeText.textContent = `session alive ${minutes}:${seconds}`;
  }

  form.addEventListener("submit", function (event) {
    event.preventDefault();
    const query = input.value.trim();

    if (!query) {
      hint.innerHTML = 'NO SIGNAL DETECTED <span class="blink">█</span>';
      input.focus();
      return;
    }

    if (looksLikeUrl(query)) {
      window.location.assign(normalizeUrl(query));
      return;
    }

    const searchUrl = new URL("https://duckduckgo.com/");
    searchUrl.searchParams.set("q", query);
    window.location.assign(searchUrl.toString());
  });

  input.addEventListener("input", function () {
    updateHintForValue(input.value);
  });

  input.addEventListener("keydown", function (event) {
    if (event.key === "Escape") {
      input.value = "";
      updateHintForValue("");
    }
  });

  updateClock();
  updateStaticSignals();
  updateUptime();
  updateHintForValue("");
  updateProtectionStats();

  window.setInterval(updateClock, 15000);
  window.setInterval(updateUptime, 1000);
  window.setInterval(updateProtectionStats, 120000);
})();
