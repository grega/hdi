// Interactive picker — navigable command list rendered inside the terminal.
// Pure module: no globals, no Astro coupling.

export function esc(text: string): string {
  const d = document.createElement("div");
  d.textContent = text;
  return d.innerHTML;
}

export interface PickerItem {
  type: string;
  text: string;
}

export interface PickerTerminal {
  showPrompt: () => void;
}

export interface PickerInstance {
  mount: (container: HTMLElement) => void;
  destroy: () => void;
  isActive: () => boolean;
}

export function Picker(
  items: PickerItem[],
  projectName: string,
  modeLabel: string,
  terminal: PickerTerminal,
): PickerInstance {
  // Pre-compute indices of command items and the first command in each section
  const cmdIndices: number[] = [];
  for (let i = 0; i < items.length; i++) {
    if (items[i].type === "command") cmdIndices.push(i);
  }

  const sectionFirstCmd: number[] = [];
  for (let i = 0; i < items.length; i++) {
    if (items[i].type === "header") {
      for (let j = i + 1; j < items.length; j++) {
        if (items[j].type === "command") {
          sectionFirstCmd.push(cmdIndices.indexOf(j));
          break;
        }
      }
    }
  }

  let cursor = 0;
  let flashMsg = "";
  let flashClass = "";
  let flashTimer: ReturnType<typeof setTimeout> | null = null;
  let copied = false;
  let copiedTimer: ReturnType<typeof setTimeout> | null = null;
  let wrap: HTMLElement | null = null;
  let active = false;

  // ── Rendering ────────────────────────────────────────────────────────────

  function render() {
    if (!wrap) return;
    wrap.innerHTML = "";

    const label = modeLabel ? `  [${modeLabel}]` : "";
    const titleLine = document.createElement("div");
    titleLine.className = "picker-row";
    titleLine.innerHTML =
      `<span class="t-bold">[hdi]</span> ` +
      `<span class="t-bold">${esc(projectName)}</span>` +
      `<span class="t-dim">${esc(label)}</span>`;
    wrap.appendChild(titleLine);

    const selectedIdx = cmdIndices[cursor];

    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const row = document.createElement("div");
      row.className = "picker-row";

      if (item.type === "header") {
        row.innerHTML = `\n<span class="t-header"> \u25b8 ${esc(item.text)}</span>`;
      } else if (item.type === "subheader") {
        row.innerHTML = `\n  <span class="t-subheader">${esc(item.text)}</span>`;
      } else if (item.type === "command") {
        if (i === selectedIdx) {
          row.classList.add("selected");
          const icon = copied ? "\u2714" : "\u25b6";
          row.innerHTML = `  <span class="arrow">${icon}</span> <span class="t-command">${esc(item.text)}</span>`;
        } else {
          row.innerHTML = `    <span class="t-command">${esc(item.text)}</span>`;
        }
      } else if (item.type === "empty" && item.text) {
        row.innerHTML = `  <span class="t-dim">${esc(item.text)}</span>`;
      }

      wrap.appendChild(row);
    }

    const footer = document.createElement("div");
    footer.className = "picker-footer";
    footer.innerHTML = flashMsg
      ? `\n  <span class="flash-msg${flashClass ? " " + flashClass : ""}">${esc(flashMsg)}</span>`
      : "\n  \u2191\u2193 navigate  \u21e5 sections  \u23ce execute  c copy  q quit";
    wrap.appendChild(footer);
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  function moveCursor(delta: number) {
    const next = cursor + delta;
    if (next >= 0 && next < cmdIndices.length) {
      cursor = next;
      copied = false;
      render();
    }
  }

  function moveSection(delta: number) {
    if (sectionFirstCmd.length === 0) return;
    if (delta > 0) {
      for (let i = 0; i < sectionFirstCmd.length; i++) {
        if (sectionFirstCmd[i] > cursor) {
          cursor = sectionFirstCmd[i];
          copied = false;
          render();
          return;
        }
      }
    } else {
      for (let i = sectionFirstCmd.length - 1; i >= 0; i--) {
        if (sectionFirstCmd[i] < cursor) {
          cursor = sectionFirstCmd[i];
          copied = false;
          render();
          return;
        }
      }
    }
  }

  // ── Flash messages ───────────────────────────────────────────────────────

  function flash(msg: string, duration = 1500, cls = "") {
    flashMsg = msg;
    flashClass = cls;
    render();
    if (flashTimer) clearTimeout(flashTimer);
    flashTimer = setTimeout(() => {
      flashMsg = "";
      flashClass = "";
      render();
    }, duration);
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  function copyCmd() {
    if (cmdIndices.length === 0) return;
    const cmd = items[cmdIndices[cursor]].text;
    if (navigator.clipboard?.writeText) {
      navigator.clipboard.writeText(cmd).then(
        () => {
          copied = true;
          flash(`\u2714 Copied: ${cmd}`);
          if (copiedTimer) clearTimeout(copiedTimer);
          copiedTimer = setTimeout(() => {
            copied = false;
            render();
          }, 1500);
        },
        () => flash("Could not copy to clipboard"),
      );
    } else {
      flash("Could not copy to clipboard");
    }
  }

  function executeCmd() {
    if (cmdIndices.length === 0) return;
    const cmd = items[cmdIndices[cursor]].text;
    flash(
      `$ ${cmd} \u2014 would execute in a real terminal`,
      2500,
      "flash-execute",
    );
  }

  // ── Keyboard ─────────────────────────────────────────────────────────────

  function handleKey(e: KeyboardEvent) {
    if (!active) return;
    const demoView = document.getElementById("demo-view");
    if (!demoView || demoView.classList.contains("hidden")) return;

    switch (e.key) {
      case "ArrowUp":
      case "k":
        e.preventDefault();
        moveCursor(-1);
        break;
      case "ArrowDown":
      case "j":
        e.preventDefault();
        moveCursor(1);
        break;
      case "c":
        e.preventDefault();
        copyCmd();
        break;
      case "Enter":
        e.preventDefault();
        executeCmd();
        break;
      case "Tab":
        e.preventDefault();
        moveSection(e.shiftKey ? -1 : 1);
        break;
      case "ArrowRight":
        e.preventDefault();
        moveSection(1);
        break;
      case "ArrowLeft":
        e.preventDefault();
        moveSection(-1);
        break;
      case "q":
      case "Escape":
        e.preventDefault();
        destroy();
        terminal.showPrompt();
        break;
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  function mount(container: HTMLElement) {
    wrap = document.createElement("div");
    wrap.className = "picker-wrap";
    container.appendChild(wrap);
    active = true;
    document.addEventListener("keydown", handleKey);
    render();
    container.scrollTop = container.scrollHeight;
  }

  function destroy() {
    active = false;
    if (flashTimer) clearTimeout(flashTimer);
    if (copiedTimer) clearTimeout(copiedTimer);
    document.removeEventListener("keydown", handleKey);
    wrap?.parentNode?.removeChild(wrap);
  }

  return {
    mount,
    destroy,
    isActive: () => active,
  };
}
