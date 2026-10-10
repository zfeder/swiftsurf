//
//  PageScripts.swift
//  swiftsurf
//

/// JavaScript snippets evaluated in web pages.
enum PageScripts {
    /// Returns the absolute URL of the page's preferred icon, or the origin's `/favicon.ico`.
    static let faviconURL = """
    (() => {
      const link = document.querySelector('link[rel~="icon"][sizes="32x32"], link[rel~="icon"], link[rel="apple-touch-icon"]');
      return link ? link.href : location.origin + '/favicon.ico';
    })()
    """

    /// Toggles a reader overlay built from the page's main text. Returns `true` when shown,
    /// `false` when hidden and `null` when no readable content was found.
    static let toggleReader = """
    (() => {
      const id = '__swiftsurf_reader__';
      const existing = document.getElementById(id);
      if (existing) {
        existing.remove();
        document.documentElement.style.overflow = '';
        return false;
      }
      const textLength = el => [...el.querySelectorAll('p')].reduce((n, p) => n + p.innerText.length, 0);
      let best = null, bestScore = 0;
      for (const el of document.querySelectorAll('article, main, [role="main"], .post, .article, .entry-content, #content')) {
        const score = textLength(el);
        if (score > bestScore) { best = el; bestScore = score; }
      }
      if (bestScore < 500) {
        const parents = new Map();
        for (const p of document.querySelectorAll('p')) {
          parents.set(p.parentElement, (parents.get(p.parentElement) || 0) + p.innerText.length);
        }
        for (const [el, score] of parents) {
          if (score > bestScore) { best = el; bestScore = score; }
        }
      }
      if (!best || bestScore < 200) return null;

      const content = best.cloneNode(true);
      content.querySelectorAll('script, style, iframe, nav, aside, form, button, noscript, svg, [aria-hidden="true"]')
        .forEach(el => el.remove());
      const overlay = document.createElement('div');
      overlay.id = id;
      overlay.style.cssText = 'position:fixed;inset:0;z-index:2147483647;overflow:auto;';
      const root = overlay.attachShadow({ mode: 'open' });
      root.innerHTML = `<style>
        :host { all: initial; }
        .page { min-height: 100%; box-sizing: border-box; padding: 48px 24px 96px; background: #fbfaf7; color: #1d1d1f;
                font: 19px/1.65 -apple-system-ui-serif, ui-serif, Georgia, serif; }
        article { max-width: 680px; margin: 0 auto; }
        h1 { font: 700 32px/1.2 -apple-system, system-ui, sans-serif; margin: 0 0 28px; }
        img, video, figure { max-width: 100%; height: auto; }
        a { color: #0a66c2; }
        pre, code { white-space: pre-wrap; font-size: 15px; }
        @media (prefers-color-scheme: dark) {
          .page { background: #1c1c1e; color: #e5e5e7; }
          a { color: #64a8ff; }
        }
      </style><div class="page"><article><h1></h1></article></div>`;
      root.querySelector('h1').textContent = document.title;
      root.querySelector('article').appendChild(content);
      document.documentElement.appendChild(overlay);
      document.documentElement.style.overflow = 'hidden';
      return true;
    })()
    """

    /// Toggles Picture in Picture for the playing (or largest) video. Returns `false` without a video.
    static let togglePictureInPicture = """
    (() => {
      const videos = [...document.querySelectorAll('video')];
      const video = videos.find(v => !v.paused)
        || videos.sort((a, b) => b.clientWidth * b.clientHeight - a.clientWidth * a.clientHeight)[0];
      if (!video) return false;
      if (video.webkitSupportsPresentationMode && video.webkitSupportsPresentationMode('picture-in-picture')) {
        const next = video.webkitPresentationMode === 'picture-in-picture' ? 'inline' : 'picture-in-picture';
        video.webkitSetPresentationMode(next);
        return true;
      }
      if (document.pictureInPictureEnabled) {
        if (document.pictureInPictureElement) { document.exitPictureInPicture(); } else { video.requestPictureInPicture(); }
        return true;
      }
      return false;
    })()
    """
}
