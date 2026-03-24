// Interactive picker simulation for the hdi
// Renders a navigable command list inside the terminal

function Picker(items, projectName, modeLabel, terminal) {
  var cmdIndices = [];
  for (var i = 0; i < items.length; i++) {
    if (items[i].type === "command") cmdIndices.push(i);
  }

  var sectionFirstCmd = [];
  for (var i = 0; i < items.length; i++) {
    if (items[i].type === "header") {
      for (var j = i + 1; j < items.length; j++) {
        if (items[j].type === "command") {
          sectionFirstCmd.push(cmdIndices.indexOf(j));
          break;
        }
      }
    }
  }

  var cursor = 0;
  var flashMsg = "";
  var flashClass = "";
  var flashTimer = null;
  var copied = false;
  var copiedTimer = null;
  var wrap = null;
  var active = false;

  function render() {
    if (!wrap) return;
    wrap.innerHTML = "";

    var titleLine = document.createElement("div");
    titleLine.className = "picker-row";
    var label = modeLabel ? "  [" + modeLabel + "]" : "";
    titleLine.innerHTML =
      '<span class="t-bold">[hdi]</span> ' +
      '<span class="t-bold">' +
      esc(projectName) +
      "</span>" +
      '<span class="t-dim">' +
      esc(label) +
      "</span>";
    wrap.appendChild(titleLine);

    var selectedIdx = cmdIndices[cursor];

    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var row = document.createElement("div");
      row.className = "picker-row";

      if (item.type === "header") {
        row.innerHTML =
          "\n" + '<span class="t-header"> \u25b8 ' + esc(item.text) + "</span>";
      } else if (item.type === "subheader") {
        row.innerHTML =
          '\n  <span class="t-subheader">' + esc(item.text) + "</span>";
      } else if (item.type === "command") {
        var isSelected = i === selectedIdx;
        if (isSelected) {
          row.classList.add("selected");
          var icon = copied ? "\u2714" : "\u25b6";
          row.innerHTML =
            '  <span class="arrow">' +
            icon +
            '</span> <span class="t-command">' +
            esc(item.text) +
            "</span>";
        } else {
          row.innerHTML =
            '    <span class="t-command">' + esc(item.text) + "</span>";
        }
      } else if (item.type === "empty") {
        if (item.text) {
          row.innerHTML = '  <span class="t-dim">' + esc(item.text) + "</span>";
        }
      }

      wrap.appendChild(row);
    }

    var footer = document.createElement("div");
    footer.className = "picker-footer";
    if (flashMsg) {
      footer.innerHTML =
        "\n  " +
        '<span class="flash-msg' +
        (flashClass ? " " + flashClass : "") +
        '">' +
        esc(flashMsg) +
        "</span>";
    } else {
      footer.innerHTML =
        "\n  \u2191\u2193 navigate  \u21e5 sections  \u23ce execute  c copy  q quit";
    }
    wrap.appendChild(footer);
  }

  function moveCursor(delta) {
    var next = cursor + delta;
    if (next >= 0 && next < cmdIndices.length) {
      cursor = next;
      copied = false;
      render();
    }
  }

  function moveSection(delta) {
    if (sectionFirstCmd.length === 0) return;
    var i;
    if (delta > 0) {
      for (i = 0; i < sectionFirstCmd.length; i++) {
        if (sectionFirstCmd[i] > cursor) {
          cursor = sectionFirstCmd[i];
          copied = false;
          render();
          return;
        }
      }
    } else {
      for (i = sectionFirstCmd.length - 1; i >= 0; i--) {
        if (sectionFirstCmd[i] < cursor) {
          cursor = sectionFirstCmd[i];
          copied = false;
          render();
          return;
        }
      }
    }
  }

  function flash(msg, duration, cls) {
    flashMsg = msg;
    flashClass = cls || "";
    render();
    if (flashTimer) clearTimeout(flashTimer);
    flashTimer = setTimeout(function () {
      flashMsg = "";
      flashClass = "";
      render();
    }, duration || 1500);
  }

  function clipCopy(cmd) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(cmd);
    }
    return Promise.reject();
  }

  function copyCmd() {
    if (cmdIndices.length === 0) return;
    var cmd = items[cmdIndices[cursor]].text;
    clipCopy(cmd).then(
      function () {
        copied = true;
        flash("\u2714 Copied: " + cmd);
        if (copiedTimer) clearTimeout(copiedTimer);
        copiedTimer = setTimeout(function () {
          copied = false;
          render();
        }, 1500);
      },
      function () {
        flash("Could not copy to clipboard");
      },
    );
  }

  function executeCmd() {
    if (cmdIndices.length === 0) return;
    var cmd = items[cmdIndices[cursor]].text;
    flash(
      "$ " + cmd + " \u2014 would execute in a real terminal",
      2500,
      "flash-execute",
    );
  }

  function handleKey(e) {
    if (!active) return;

    var demoView = document.getElementById("demo-view");
    if (!demoView || demoView.classList.contains("hidden")) return;

    var key = e.key;
    if (key === "ArrowUp" || key === "k") {
      e.preventDefault();
      moveCursor(-1);
    } else if (key === "ArrowDown" || key === "j") {
      e.preventDefault();
      moveCursor(1);
    } else if (key === "c") {
      e.preventDefault();
      copyCmd();
    } else if (key === "Enter") {
      e.preventDefault();
      executeCmd();
    } else if (key === "Tab") {
      e.preventDefault();
      moveSection(e.shiftKey ? -1 : 1);
    } else if (key === "ArrowRight") {
      e.preventDefault();
      moveSection(1);
    } else if (key === "ArrowLeft") {
      e.preventDefault();
      moveSection(-1);
    } else if (key === "q" || key === "Escape") {
      e.preventDefault();
      destroy();
      terminal.showPrompt();
    }
  }

  function mount(container) {
    wrap = document.createElement("div");
    wrap.className = "picker-wrap";
    container.appendChild(wrap);
    active = true;
    document.addEventListener("keydown", handleKey);
    render();
    scrollTerminal();
  }

  function destroy() {
    active = false;
    if (flashTimer) clearTimeout(flashTimer);
    document.removeEventListener("keydown", handleKey);
    if (wrap && wrap.parentNode) {
      wrap.parentNode.removeChild(wrap);
    }
  }

  function scrollTerminal() {
    var term = document.getElementById("terminal");
    if (term) term.scrollTop = term.scrollHeight;
  }

  return {
    mount: mount,
    destroy: destroy,
    isActive: function () {
      return active;
    },
  };
}

function esc(text) {
  var d = document.createElement("div");
  d.textContent = text;
  return d.innerHTML;
}
