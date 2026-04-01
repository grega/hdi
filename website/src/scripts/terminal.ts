// Terminal emulator logic for the hdi demo site.
// Pure module: takes DOM refs and data as arguments, no globals.

import { Picker, esc, type PickerItem, type PickerInstance } from "./picker";

export interface CheckItem {
  tool: string;
  installed: boolean;
  version?: string;
}

export interface Project {
  name: string;
  description: string;
  lang: string;
  readme: string;
  modes: Record<string, PickerItem[]>;
  fullProse: Record<string, PickerItem[]>;
  check: CheckItem[];
}

export interface TerminalConfig {
  termEl: HTMLElement;
  hiddenInput: HTMLInputElement;
  projects: Project[];
  version: string;
  helpText: string;
}

export interface TerminalInstance {
  selectProject: (p: Project) => void;
  /** Type a command into the prompt (as if the user clicked a hint). */
  typeHint: (cmd: string) => void;
}

export function initTerminal(config: TerminalConfig): TerminalInstance {
  const { termEl, hiddenInput, projects, version, helpText } = config;

  let currentProject = projects[0];
  let currentPicker: PickerInstance | null = null;
  let inputBuffer = "";
  let promptActive = false;

  // ── Focus ────────────────────────────────────────────────────────────────

  function focusTerminal() {
    hiddenInput.focus({ preventScroll: true });
  }

  // ── Terminal output ──────────────────────────────────────────────────────

  function clearTerminal() {
    termEl.innerHTML = "";
    termEl.appendChild(hiddenInput);
  }

  function appendLine(className: string, html: string) {
    const div = document.createElement("div");
    div.className = "t-line" + (className ? " " + className : "");
    div.innerHTML = html;
    termEl.appendChild(div);
  }

  function scrollToBottom() {
    termEl.scrollTop = termEl.scrollHeight;
  }

  // ── Prompt ───────────────────────────────────────────────────────────────

  function showPrompt() {
    promptActive = true;
    inputBuffer = "";
    const line = document.createElement("div");
    line.className = "t-line t-prompt";
    line.id = "prompt-line";
    line.innerHTML =
      '$ <span class="t-input" id="prompt-input"></span><span class="t-cursor"></span>';
    termEl.appendChild(line);
    scrollToBottom();
  }

  function updatePromptDisplay() {
    const el = document.getElementById("prompt-input");
    if (el) el.textContent = inputBuffer;
    scrollToBottom();
  }

  function freezePrompt() {
    promptActive = false;
    const line = document.getElementById("prompt-line");
    if (line) {
      line.removeAttribute("id");
      line.innerHTML =
        "$ " + `<span class="t-input">${esc(inputBuffer)}</span>`;
    }
    document.getElementById("prompt-input")?.removeAttribute("id");
  }

  // ── Hint input (called externally via custom event) ────────────────────

  function typeHint(cmd: string) {
    if (!promptActive) return;
    inputBuffer = cmd;
    updatePromptDisplay();
    focusTerminal();
  }

  // ── Project selection ────────────────────────────────────────────────────

  function resetTerminal() {
    clearTerminal();
    appendLine("t-dim", "cd " + currentProject.name);
    appendLine("", "");
    appendLine(
      "t-dim",
      'Type "hdi" to get started, "hdi --help" for more options, or "cat README.md" to see the full project README',
    );
    appendLine(
      "t-dim",
      'Use "hdi" with the "i" (install), "r" (run), "t" (test), or "d" (deploy) subcommands to see specific sections',
    );
    appendLine("t-dim", 'eg. "hdi r"');
    appendLine("", "");
    showPrompt();
    focusTerminal();
  }

  function selectProject(p: Project) {
    if (currentPicker) {
      currentPicker.destroy();
      currentPicker = null;
    }
    currentProject = p;
    resetTerminal();
  }

  // ── Command parsing ──────────────────────────────────────────────────────

  type ParsedCommand =
    | { clear: true }
    | { cat: true }
    | { error: string }
    | { help: true }
    | { version: true }
    | { mode: string; full: boolean; raw: boolean };

  function parseCommand(input: string): ParsedCommand {
    const parts = input.trim().split(/\s+/);
    if (parts[0] === "clear") return { clear: true };
    if (parts[0] === "cat" && /readme\.md$/i.test(parts[1] ?? ""))
      return { cat: true };
    if (parts[0] !== "hdi")
      return {
        error: `Command not found: ${parts[0]}. Try "hdi" to get started.`,
      };

    let mode = "default";
    let full = false;
    let raw = false;
    let help = false;
    let ver = false;

    for (let i = 1; i < parts.length; i++) {
      switch (parts[i]) {
        case "install":
        case "setup":
        case "i":
          mode = "install";
          break;
        case "run":
        case "start":
        case "r":
          mode = "run";
          break;
        case "test":
        case "t":
          mode = "test";
          break;
        case "deploy":
        case "d":
          mode = "deploy";
          break;
        case "all":
        case "a":
          mode = "all";
          break;
        case "check":
        case "c":
          mode = "check";
          break;
        case "--full":
        case "-f":
          full = true;
          break;
        case "--raw":
          raw = true;
          break;
        case "--help":
        case "-h":
          help = true;
          break;
        case "--version":
        case "-v":
          ver = true;
          break;
        case "--no-interactive":
        case "--ni":
          break;
        default:
          return { error: `Unknown argument: ${parts[i]}` };
      }
    }

    if (help) return { help: true };
    if (ver) return { version: true };
    return { mode, full, raw };
  }

  function modeLabel(mode: string): string {
    return mode === "default" ? "" : mode;
  }

  // ── Execute command ──────────────────────────────────────────────────────

  function execute(input: string) {
    if (!input.trim()) {
      showPrompt();
      return;
    }

    const parsed = parseCommand(input);

    if ("clear" in parsed) {
      resetTerminal();
      return;
    }

    if ("cat" in parsed) {
      currentProject.readme
        .split("\n")
        .forEach((line) => appendLine("", esc(line)));
      appendLine("", "");
      showPrompt();
      return;
    }

    if ("error" in parsed) {
      appendLine("t-yellow", esc(parsed.error));
      appendLine("", "");
      showPrompt();
      return;
    }

    if ("help" in parsed) {
      helpText.split("\n").forEach((line) => appendLine("", esc(line)));
      appendLine("", "");
      showPrompt();
      return;
    }

    if ("version" in parsed) {
      appendLine("", "hdi " + version);
      appendLine("", "");
      showPrompt();
      return;
    }

    if (parsed.mode === "check") {
      renderCheck();
      showPrompt();
      return;
    }
    if (parsed.raw) {
      renderRaw(parsed.mode);
      showPrompt();
      return;
    }
    if (parsed.full) {
      renderFull(parsed.mode);
      showPrompt();
      return;
    }

    const items = currentProject.modes[parsed.mode];
    if (!items || items.length === 0) {
      appendLine("t-yellow", "No matching sections found");
      appendLine("t-dim", "Try: hdi all --full");
      appendLine("", "");
      showPrompt();
      return;
    }

    currentPicker = Picker(items, currentProject.name, modeLabel(parsed.mode), {
      showPrompt() {
        currentPicker = null;
        showPrompt();
      },
    });
    currentPicker.mount(termEl);
    scrollToBottom();
  }

  // ── Raw renderer ─────────────────────────────────────────────────────────

  function renderRaw(mode: string) {
    const items = currentProject.modes[mode];
    if (!items || items.length === 0) {
      appendLine("t-yellow", "No matching sections found");
      appendLine("t-dim", "Try: hdi all --full");
      appendLine("", "");
      return;
    }
    appendLine("", "");
    items.forEach((item) => {
      if (item.type === "header") appendLine("", "\n## " + esc(item.text));
      else if (item.type === "subheader")
        appendLine("", "\n### " + esc(item.text));
      else if (item.type === "command") appendLine("", esc(item.text));
      else if (item.type === "empty" && item.text)
        appendLine("", "  " + esc(item.text));
    });
    appendLine("", "");
  }

  // ── Full-prose renderer ──────────────────────────────────────────────────

  function renderFull(mode: string) {
    const items = currentProject.fullProse[mode];
    if (!items || items.length === 0) {
      appendLine("t-yellow", "No matching sections found");
      appendLine("t-dim", "Try: hdi all --full");
      appendLine("", "");
      return;
    }
    const label = modeLabel(mode);
    const labelStr = label ? `  [${label}]` : "";
    appendLine(
      "t-title-line",
      "[hdi] " +
        esc(currentProject.name) +
        `<span class="t-dim">${esc(labelStr)}</span>`,
    );
    items.forEach((item) => {
      if (item.type === "header") {
        appendLine("", "");
        appendLine("t-header", " \u25b8 " + esc(item.text));
      } else if (item.type === "subheader") {
        appendLine("", "");
        appendLine("t-subheader", "  " + esc(item.text));
      } else if (item.type === "command") {
        appendLine("t-command", "  " + esc(item.text));
      } else if (item.type === "prose") {
        appendLine("t-dim", "  " + esc(item.text));
      } else if (item.type === "empty") {
        appendLine("", "");
      }
    });
    appendLine("", "");
  }

  // ── Check renderer ───────────────────────────────────────────────────────

  function renderCheck() {
    const items = currentProject.check;
    if (!items || items.length === 0) {
      appendLine("t-yellow", "No tool references found in commands.");
      appendLine("", "");
      return;
    }
    appendLine("", "");
    appendLine(
      "t-title-line",
      "[hdi] " +
        esc(currentProject.name) +
        '<span class="t-dim">  check</span>',
    );
    appendLine("", "");

    let found = 0;
    let missing = 0;

    items.forEach((item) => {
      let name = item.tool;
      while (name.length < 14) name += " ";
      if (item.installed) {
        const ver = item.version
          ? ` <span class="t-dim">(${esc(item.version)})</span>`
          : "";
        appendLine(
          "",
          `  <span class="t-green">\u2713</span> ${esc(name)}${ver}`,
        );
        found++;
      } else {
        appendLine(
          "",
          `  <span class="t-yellow">\u2717</span> ${esc(name)} <span class="t-dim">not found</span>`,
        );
        missing++;
      }
    });

    appendLine("", "");
    if (missing === 0) {
      appendLine("t-dim", `  \u2713 All ${found} tools found`);
    } else {
      appendLine(
        "",
        `  <span class="t-dim">${found} found, </span><span class="t-yellow">${missing} not found</span>`,
      );
    }
    appendLine("", "");
  }

  // ── Keyboard handling ────────────────────────────────────────────────────

  function onKeyDown(e: KeyboardEvent) {
    if (currentPicker?.isActive()) return;
    if (!promptActive) return;

    if (e.key === "Enter") {
      e.preventDefault();
      e.stopPropagation();
      const cmd = inputBuffer;
      freezePrompt();
      execute(cmd);
    } else if (e.key === "Backspace") {
      e.preventDefault();
      inputBuffer = inputBuffer.slice(0, -1);
      updatePromptDisplay();
    } else if (e.key.length === 1 && !e.ctrlKey && !e.metaKey) {
      e.preventDefault();
      inputBuffer += e.key;
      updatePromptDisplay();
    } else if (e.key === "Tab") {
      e.preventDefault();
    } else if (e.key === "l" && e.ctrlKey) {
      e.preventDefault();
      clearTerminal();
      showPrompt();
    }
  }

  hiddenInput.addEventListener("keydown", onKeyDown);

  // Mobile: proxy hidden input value into inputBuffer
  hiddenInput.addEventListener("input", () => {
    if (!promptActive || currentPicker?.isActive()) return;
    const val = hiddenInput.value;
    if (val) {
      inputBuffer += val;
      hiddenInput.value = "";
      updatePromptDisplay();
    }
  });

  // Paste handling on both terminal and hidden input
  function onPaste(e: ClipboardEvent) {
    if (!promptActive || currentPicker?.isActive()) return;
    e.preventDefault();
    const text = e.clipboardData?.getData("text") ?? "";
    if (text) {
      inputBuffer += text.split("\n")[0].trim();
      updatePromptDisplay();
    }
  }
  termEl.addEventListener("paste", onPaste);
  hiddenInput.addEventListener("paste", onPaste);

  termEl.addEventListener("click", () => {
    if (!currentPicker?.isActive()) focusTerminal();
  });

  // ── Init ─────────────────────────────────────────────────────────────────

  selectProject(currentProject);

  return { selectProject, typeHint };
}
