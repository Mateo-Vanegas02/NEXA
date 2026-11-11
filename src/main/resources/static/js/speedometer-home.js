class NexaSpeedometerPagination {
  constructor(root) {
    this.root = root;
    this.ticks = Array.from(root.querySelectorAll("[data-speed-page]"));
    this.numbers = root.querySelector(".speedometer-numbers");
    this.release = root.querySelector(".speedometer-release");
    this.title = root.querySelector("[data-speed-title]");
    this.copy = root.querySelector("[data-speed-copy]");
    this.totalPages = Number(root.dataset.totalPages) || this.ticks.length || 1;
    this.currentPage = Number(root.dataset.currentPage) || 1;
    this.minAngle = -108;
    this.maxAngle = 108;
    this.autoplayId = 0;

    this.handleTickClick = this.handleTickClick.bind(this);
    this.handleKeydown = this.handleKeydown.bind(this);
  }

  init() {
    this.ticks.forEach((tick) => {
      tick.addEventListener("click", this.handleTickClick);
      tick.addEventListener("keydown", this.handleKeydown);
    });

    this.setPage(this.currentPage, { emit: false });
    this.startAutoplay();
  }

  getAngle(page) {
    if (this.totalPages <= 1) {
      return 0;
    }

    return this.minAngle + ((page - 1) / (this.totalPages - 1)) * (this.maxAngle - this.minAngle);
  }

  getDigitHeight() {
    const value = getComputedStyle(this.root).getPropertyValue("--digit-height");
    return parseFloat(value) || 42;
  }

  getTickByPage(page) {
    return this.ticks.find((tick) => Number(tick.dataset.speedPage) === page) || this.ticks[0];
  }

  setPage(page, options = { emit: true }) {
    const nextPage = Math.max(1, Math.min(this.totalPages, Number(page)));
    const activeTick = this.getTickByPage(nextPage);

    this.currentPage = nextPage;
    this.root.dataset.currentPage = String(nextPage);
    this.root.style.setProperty("--needle-angle", `${this.getAngle(nextPage)}deg`);

    if (this.numbers) {
      this.numbers.style.transform = `translate3d(0, -${(nextPage - 1) * this.getDigitHeight()}px, 0)`;
    }

    this.ticks.forEach((tick) => {
      const tickPage = Number(tick.dataset.speedPage);
      tick.classList.toggle("is-lit", tickPage <= nextPage);
      tick.classList.toggle("is-active", tickPage === nextPage);
      tick.setAttribute("aria-current", tickPage === nextPage ? "page" : "false");
    });

    this.playRelease(activeTick);
    this.revealCopy(activeTick);

    if (options.emit) {
      this.root.dispatchEvent(
        new CustomEvent("nexaPageChange", {
          bubbles: true,
          detail: { page: nextPage },
        })
      );
    }
  }

  playRelease(tick) {
    if (!this.release || !tick) {
      return;
    }

    this.release.style.setProperty("--release-x", tick.style.getPropertyValue("--tick-x"));
    this.release.style.setProperty("--release-y", tick.style.getPropertyValue("--tick-y"));
    this.release.classList.remove("is-releasing");

    window.requestAnimationFrame(() => {
      this.release.classList.add("is-releasing");
    });
  }

  revealCopy(tick) {
    if (!tick || !this.title || !this.copy) {
      return;
    }

    this.title.textContent = tick.dataset.label || `Pagina ${this.currentPage}`;
    this.copy.textContent = tick.dataset.copy || "";

    [this.title, this.copy].forEach((element, index) => {
      element.classList.remove("is-revealing");
      element.style.animationDelay = `${index * 90}ms`;

      window.requestAnimationFrame(() => {
        element.classList.add("is-revealing");
      });
    });
  }

  handleTickClick(event) {
    const page = Number(event.currentTarget.dataset.speedPage);
    this.setPage(page);
    this.startAutoplay();
  }

  handleKeydown(event) {
    if (event.key !== "ArrowRight" && event.key !== "ArrowLeft") {
      return;
    }

    event.preventDefault();
    const direction = event.key === "ArrowRight" ? 1 : -1;
    const nextPage = this.currentPage + direction;
    this.setPage(nextPage);
    this.getTickByPage(this.currentPage)?.focus();
    this.startAutoplay();
  }

  startAutoplay() {
    window.clearInterval(this.autoplayId);
    this.autoplayId = window.setInterval(() => {
      this.setPage(this.currentPage === this.totalPages ? 1 : this.currentPage + 1);
    }, 3200);
  }
}

class NexaMagneticCursor {
  constructor(cursor) {
    this.cursor = cursor;
    this.pointer = { x: window.innerWidth / 2, y: window.innerHeight / 2 };
    this.position = { ...this.pointer };
    this.magnet = null;
    this.rafId = 0;

    this.handleMouseMove = this.handleMouseMove.bind(this);
    this.render = this.render.bind(this);
  }

  init() {
    if (!this.cursor || window.matchMedia("(pointer: coarse)").matches) {
      return;
    }

    window.addEventListener("mousemove", this.handleMouseMove, { passive: true });
    document.querySelectorAll(".speedometer-tick").forEach((target) => {
      target.addEventListener("mouseenter", () => {
        this.magnet = target;
        this.cursor.classList.add("is-magnetic");
      });
      target.addEventListener("mouseleave", () => {
        this.magnet = null;
        this.cursor.classList.remove("is-magnetic");
      });
    });

    this.render();
  }

  handleMouseMove(event) {
    this.pointer.x = event.clientX;
    this.pointer.y = event.clientY;
    this.cursor.classList.add("is-visible");
  }

  getTargetPosition() {
    if (!this.magnet) {
      return this.pointer;
    }

    const rect = this.magnet.getBoundingClientRect();
    return {
      x: this.pointer.x * 0.55 + (rect.left + rect.width / 2) * 0.45,
      y: this.pointer.y * 0.55 + (rect.top + rect.height / 2) * 0.45,
    };
  }

  render() {
    const target = this.getTargetPosition();
    this.position.x += (target.x - this.position.x) * 0.18;
    this.position.y += (target.y - this.position.y) * 0.18;

    this.cursor.style.transform = `translate3d(${this.position.x}px, ${this.position.y}px, 0) translate3d(-50%, -50%, 0)`;
    this.rafId = window.requestAnimationFrame(this.render);
  }
}

document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("[data-speedometer]").forEach((root) => {
    new NexaSpeedometerPagination(root).init();
  });

  new NexaMagneticCursor(document.querySelector(".nexa-magnetic-cursor")).init();
});
