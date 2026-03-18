// Terminal emulator + app logic for the hdi demo site

(function () {
  var termEl = document.getElementById("terminal");
  var sidebarEl = document.getElementById("sidebar");
  var hintsEl = document.getElementById("hints");

  var currentProject = PROJECTS[0];
  var currentPicker = null;
  var inputBuffer = "";
  var promptActive = false;
  var autoPlayed = false;

  // ── Sidebar ──────────────────────────────────────────────────────────────

  function buildSidebar() {
    sidebarEl.innerHTML = "";
    PROJECTS.forEach(function (p) {
      var item = document.createElement("div");
      item.className = "sidebar-item" + (p === currentProject ? " active" : "");
      item.innerHTML =
        '<span class="sidebar-badge lang-' + p.lang + '">' + p.lang + "</span>" +
        '<div class="sidebar-info">' +
        '<div class="sidebar-name">' + esc(p.name) + "</div>" +
        '<div class="sidebar-desc">' + esc(p.description) + "</div>" +
        "</div>";
      item.addEventListener("click", function (e) {
        e.stopPropagation();
        selectProject(p);
      });
      sidebarEl.appendChild(item);
    });
  }

  function selectProject(p) {
    if (currentPicker) {
      currentPicker.destroy();
      currentPicker = null;
    }
    currentProject = p;
    buildSidebar();
    termEl.innerHTML = "";
    appendLine("t-dim", "cd " + p.name);
    appendLine("", "");
    showPrompt();
    termEl.focus();
  }

  // ── Terminal output ──────────────────────────────────────────────────────

  function appendLine(className, html) {
    var div = document.createElement("div");
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
    var line = document.createElement("div");
    line.className = "t-line t-prompt";
    line.id = "prompt-line";
    line.innerHTML = '$ <span class="t-input" id="prompt-input"></span><span class="t-cursor"></span>';
    termEl.appendChild(line);
    scrollToBottom();
    setHints("default");
  }

  function updatePromptDisplay() {
    var el = document.getElementById("prompt-input");
    if (el) el.textContent = inputBuffer;
    scrollToBottom();
  }

  function freezePrompt() {
    promptActive = false;
    var line = document.getElementById("prompt-line");
    if (line) {
      line.removeAttribute("id");
      line.innerHTML = "$ " + '<span class="t-input">' + esc(inputBuffer) + "</span>";
    }
    var input = document.getElementById("prompt-input");
    if (input) input.removeAttribute("id");
  }

  // ── Hints ────────────────────────────────────────────────────────────────

  function setHints(mode) {
    if (mode === "picker") {
      hintsEl.innerHTML = "\u2191\u2193 navigate  \u23ce execute  <code>c</code> copy  <code>q</code> quit";
    } else {
      hintsEl.innerHTML =
        "Try: <code>hdi</code> <code>hdi install</code> <code>hdi run</code> " +
        "<code>hdi test</code> <code>hdi all</code> <code>hdi --full</code> <code>hdi --raw</code>";
    }
  }

  // ── Command parsing ──────────────────────────────────────────────────────

  function parseCommand(input) {
    var parts = input.trim().split(/\s+/);
    if (parts[0] === "clear") return { clear: true };
    if (parts[0] !== "hdi") return { error: 'Command not found: ' + parts[0] + '. Try "hdi" to get started.' };

    var mode = "default";
    var full = false;
    var raw = false;
    var help = false;
    var version = false;

    for (var i = 1; i < parts.length; i++) {
      var arg = parts[i];
      switch (arg) {
        case "install": case "setup": case "i": mode = "install"; break;
        case "run": case "start": case "r": mode = "run"; break;
        case "test": case "t": mode = "test"; break;
        case "all": case "a": mode = "all"; break;
        case "--full": case "-f": full = true; break;
        case "--raw": raw = true; break;
        case "--help": case "-h": help = true; break;
        case "--version": case "-v": version = true; break;
        case "--no-interactive": case "--ni": break;
        default: return { error: "Unknown argument: " + arg };
      }
    }

    if (help) return { help: true };
    if (version) return { version: true };
    return { mode: mode, full: full, raw: raw };
  }

  function modeLabel(mode) {
    if (mode === "default") return "";
    return mode;
  }

  // ── Execute command ──────────────────────────────────────────────────────

  function execute(input) {
    if (!input.trim()) {
      showPrompt();
      return;
    }

    var parsed = parseCommand(input);

    if (parsed.clear) {
      termEl.innerHTML = "";
      showPrompt();
      return;
    }

    if (parsed.error) {
      appendLine("t-yellow", esc(parsed.error));
      appendLine("", "");
      showPrompt();
      return;
    }

    if (parsed.help) {
      HELP_TEXT.split("\n").forEach(function (line) {
        appendLine("", esc(line));
      });
      appendLine("", "");
      showPrompt();
      return;
    }

    if (parsed.version) {
      appendLine("", "hdi " + VERSION);
      appendLine("", "");
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

    var items = currentProject.modes[parsed.mode];
    if (!items || items.length === 0) {
      appendLine("t-yellow", "No matching sections found");
      appendLine("t-dim", "Try: hdi all --full");
      appendLine("", "");
      showPrompt();
      return;
    }

    setHints("picker");
    currentPicker = Picker(items, currentProject.name, modeLabel(parsed.mode), {
      showPrompt: function () {
        currentPicker = null;
        setHints("default");
        showPrompt();
      },
    });
    currentPicker.mount(termEl);
    scrollToBottom();
  }

  // ── Raw renderer ─────────────────────────────────────────────────────────

  function renderRaw(mode) {
    var items = currentProject.modes[mode];
    if (!items || items.length === 0) {
      appendLine("t-yellow", "No matching sections found");
      appendLine("t-dim", "Try: hdi all --full");
      appendLine("", "");
      return;
    }

    appendLine("", "");
    items.forEach(function (item) {
      if (item.type === "header") {
        appendLine("", "\n## " + esc(item.text));
      } else if (item.type === "subheader") {
        appendLine("", "\n### " + esc(item.text));
      } else if (item.type === "command") {
        appendLine("", esc(item.text));
      } else if (item.type === "empty" && item.text) {
        appendLine("", "  " + esc(item.text));
      }
    });
    appendLine("", "");
  }

  // ── Full-prose renderer ──────────────────────────────────────────────────

  function renderFull(mode) {
    var items = currentProject.fullProse[mode];
    if (!items || items.length === 0) {
      appendLine("t-yellow", "No matching sections found");
      appendLine("t-dim", "Try: hdi all --full");
      appendLine("", "");
      return;
    }

    var label = modeLabel(mode);
    var labelStr = label ? "  [" + label + "]" : "";
    appendLine("t-title-line", "[hdi] " + esc(currentProject.name) + '<span class="t-dim">' + esc(labelStr) + "</span>");

    items.forEach(function (item) {
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

  // ── Keyboard handling ────────────────────────────────────────────────────

  function onKeyDown(e) {
    if (currentPicker && currentPicker.isActive()) return;
    if (!promptActive) return;

    if (e.key === "Enter") {
      e.preventDefault();
      var cmd = inputBuffer;
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
    } else if (e.key === "l" && e.ctrlKey) {
      // Ctrl+L to clear
      e.preventDefault();
      termEl.innerHTML = "";
      showPrompt();
    }
  }

  termEl.addEventListener("keydown", onKeyDown);

  // Handle paste into prompt
  termEl.addEventListener("paste", function (e) {
    if (!promptActive) return;
    if (currentPicker && currentPicker.isActive()) return;
    e.preventDefault();
    var text = (e.clipboardData || window.clipboardData).getData("text");
    if (text) {
      // Take only the first line
      var firstLine = text.split("\n")[0].trim();
      inputBuffer += firstLine;
      updatePromptDisplay();
    }
  });

  termEl.addEventListener("click", function () {
    if (!currentPicker || !currentPicker.isActive()) {
      termEl.focus();
    }
  });

  // ── Init ─────────────────────────────────────────────────────────────────

  buildSidebar();
  appendLine("t-dim", "cd " + currentProject.name);
  appendLine("", "");
  appendLine("t-dim", 'Type "hdi" to get started.');
  appendLine("", "");
  showPrompt();
  termEl.focus();
})();
