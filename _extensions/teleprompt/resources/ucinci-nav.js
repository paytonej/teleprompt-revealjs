<script>
// UCinci Quarto Reveal.js Navigation & Logo Script

Reveal.on('slidechanged', event => {
  const slide = event.currentSlide;

  // Determine nav color based on slide class
  let navColor = '#ffffff';
  if (slide.classList.contains('official-uc-red-gradient')) navColor = '#ffffff';
  if (slide.classList.contains('beyond-black-gradient')) navColor = '#ffffff';
  if (slide.classList.contains('white-gradient')) navColor =  '#000000';
  if (slide.classList.contains('uc-red-flat')) navColor = "#ffffff";
  if (slide.classList.contains('uc-black-flat')) navColor = "#ffffff";
  if (slide.classList.contains('black-and-white')) navColor = "#000000";

  // Standard nav elements
  document.querySelectorAll(
    '.reveal .progress span, .reveal .slide-number'
  ).forEach(el => {
    el.style.color = navColor;
    el.style.fill = navColor;
  });

  // Hamburger menu button
  const menuBtn = document.querySelector('.reveal .slide-menu-button');
  if(menuBtn) {
    // Set color for all child SVG paths
    menuBtn.querySelectorAll('svg path, svg line').forEach(path => {
      path.setAttribute('stroke', #000000);
      path.setAttribute('fill', #000000);
    });
  }
});

// Function to get nav color for a slide
function getNavColor(slide) {
  for (const cls of Object.keys(navColors)) {
    if (slide.classList.contains(cls)) return navColors[cls];
  }
  return "#E00122"; // default
}

// Update nav elements: controls, progress, slide numbers
function updateNavElements(slide) {
  const color = getNavColor(slide);
  document.querySelectorAll('.reveal .progress span, .reveal .slide-number')
    .forEach(el => {
      el.style.color = color;
      el.style.fill = color;
    });
}

// Update nav elements: controls, progress, slide numbers
function updateNavElements2(slide) {
  document.querySelectorAll('.reveal .controls')
    .forEach(el => {
      el.style.color = "#000000";
      el.style.fill = "#000000";
    });
}

// Update hamburger menu
function updateMenuIcon(slide) {
  const menuBtn = document.querySelector('.slide-menu-button');
  if (!menuBtn) return;

  const color = getNavColor(slide);
  const size = 32; // px

  // Remove old SVG
  const oldSvg = menuBtn.querySelector('svg');
  if (oldSvg) oldSvg.remove();

  // Create new SVG
  const svgNS = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(svgNS, "svg");
  svg.setAttribute("width", size);
  svg.setAttribute("height", size);
  svg.setAttribute("viewBox", "0 0 16 16");
  svg.setAttribute("fill", color);
  svg.setAttribute("class", "bi bi-list");

  const path = document.createElementNS(svgNS, "path");
  path.setAttribute("fill-rule", "evenodd");
  path.setAttribute("d", "M2.5 12a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5z");
  svg.appendChild(path);

  menuBtn.appendChild(svg);
}

// Main function to update everything
function updateSlideUI(slide) {
  if (!slide) return;
  updateNavElements(slide);
  updateNavElements2(slide);
  updateMenuIcon(slide);
  updateLogoColor(slide);
}

// Initial load
document.addEventListener('DOMContentLoaded', () => {
  updateSlideUI(Reveal.getCurrentSlide());
  updateLogoColor(Reveal.getCurrentSlide());
});

function updateLogoColor(slide) {
  const logo = document.querySelector('.reveal.has-logo .slide-logo svg');
  if (!logo) return;

  let logoColor = '#ffffff'; // default

  // Change the fill for all paths inside the SVG
  logo.querySelectorAll('*').forEach(el => {
    el.setAttribute('fill', logoColor);
  });
}

Reveal.on('slidechanged', function(event) {
  const slide = event.currentSlide;
  updateLogoColor(slide);
});

function updateTitleSlideLogo() {
  const currentIndex = Reveal.getIndices().h; // horizontal slide index
  const logo = document.querySelector('.title-slide-logo');
  if (!logo) return;

  if (currentIndex === 0) { // first slide is the title slide
    logo.style.display = 'block';
  } else {
    logo.style.display = 'none';
  }
}

// On slide change
Reveal.on('slidechanged', updateTitleSlideLogo);

/* On initial load */
document.addEventListener('DOMContentLoaded', updateTitleSlideLogo);
</script>