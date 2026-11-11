(function () {
  const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if (prefersReducedMotion) {
    document.body.classList.add("home-loaded");
    document.querySelectorAll("section").forEach(function (section) {
      section.classList.add("visible");
    });
    return;
  }

  document.body.classList.add("motion-ready");

  function prepareRevealChildren(section) {
    const revealTargets = section.querySelectorAll(
      ":scope > h2, :scope > p, :scope > .row, :scope .cards > .card"
    );

    revealTargets.forEach(function (target, index) {
      target.classList.add("reveal-child");
      target.style.setProperty("--reveal-index", String(index));
    });
  }

  document.querySelectorAll("section").forEach(function (section) {
    prepareRevealChildren(section);
  });

  const observer = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("visible");
          observer.unobserve(entry.target);
        }
      });
    },
    {
      rootMargin: "0px 0px -12% 0px",
      threshold: 0.16,
    }
  );

  document.querySelectorAll("section").forEach(function (section) {
    observer.observe(section);
  });

  window.requestAnimationFrame(function () {
    document.body.classList.add("home-loaded");
    const homeSection = document.getElementById("home");

    if (homeSection) {
      homeSection.classList.add("visible");
    }
  });
})();
