<script>
(function () {
  'use strict';

  // ── subtitle bar element ─────────────────────────────────────────────────────
  var bar = document.createElement('div');
  bar.id = 'slide-subtitle-bar';
  bar.setAttribute('aria-live', 'polite');
  bar.setAttribute('aria-atomic', 'true');
  document.querySelector('.reveal').appendChild(bar);

  // ── helpers ──────────────────────────────────────────────────────────────────

  function getSubtitles(slide) {
    if (!slide) return null;
    var dataDiv = slide.querySelector('.slide-subtitle-data');
    if (!dataDiv) return null;
    try {
      var parsed = JSON.parse(dataDiv.dataset.subtitles);
      return (Array.isArray(parsed) && parsed.length > 0) ? parsed : null;
    } catch (e) {
      return null;
    }
  }

  // ── toggle state ─────────────────────────────────────────────────────────────
  var subtitlesHidden = false;

  // ── update callback ──────────────────────────────────────────────────────────
  // RevealJS exposes the current fragment index as Reveal.getState().indexf.
  // It is -1 when no fragment is active on the current slide, and increments
  // with each fragment advance.  We map:
  //   indexf == -1  →  subtitle segment 0  (initial slide state)
  //   indexf ==  0  →  subtitle segment 1  (after 1st click)
  //   indexf ==  k  →  subtitle segment k+1 (clamped to last segment)

  function updateSubtitle() {
    if (subtitlesHidden) return;

    var slide = Reveal.getCurrentSlide();
    var subs  = getSubtitles(slide);

    if (!subs) {
      bar.style.display = 'none';
      return;
    }

    var state   = Reveal.getState();
    var fragIdx = (typeof state.indexf === 'number') ? state.indexf : -1;
    var subIdx  = Math.max(0, Math.min(fragIdx + 1, subs.length - 1));

    bar.textContent = subs[subIdx];
    bar.style.display = 'block';
  }

  // ── toggle keystroke (\) ─────────────────────────────────────────────────────
  document.addEventListener('keydown', function (e) {
    if (e.code !== 'Backslash') return;
    subtitlesHidden = !subtitlesHidden;
    if (subtitlesHidden) {
      bar.style.display = 'none';
    } else {
      updateSubtitle();
    }
  });

  // ── RevealJS event hooks ─────────────────────────────────────────────────────
  Reveal.on('ready',          updateSubtitle);
  Reveal.on('slidechanged',   updateSubtitle);
  Reveal.on('fragmentshown',  updateSubtitle);
  Reveal.on('fragmenthidden', updateSubtitle);

})();
</script>
