// Interactive picker simulation for the hdi
// Renders a navigable command list inside the terminal

function Picker(items, projectName, modeLabel, terminal) {
  var cmdIndices = [];
  for (var i = 0; i < items.length; i++) {
    if (items[i].type === "command") cmdIndices.push(i);
  }

  var cursor = 0;
  var flashMsg = "";
  var flashTimer = null;
  var wrap = null;
  var active = false;

  function render() {
    if (!wrap) return;
    wrap.innerHTML = "";

    var titleLine = document.createElement("div");
    titleLine.className = "picker-row";
    var label = modeLabel ? "  [" + modeLabel + "]" : "";
    titleLine.innerHTML = '<span class="t-bold">[hdi]</span> ' +
      '<span class="t-bold">' + esc(projectName) + '</span>' +
      '<span class="t-dim">' + esc(label) + '</span>';
    wrap.appendChild(titleLine);

    var selectedIdx = cmdIndices[cursor];

    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var row = document.createElement("div");
      row.className = "picker-row";

      if (item.type === "header") {
        row.innerHTML = "\n" + '<span class="t-header"> \u25b8 ' + esc(item.text) + '</span>';
      } else if (item.type === "subheader") {
        row.innerHTML = '\n  <span class="t-subheader">' + esc(item.text) + '</span>';
      } else if (item.type === "command") {
        var isSelected = (i === selectedIdx);
        if (isSelected) {
          row.classList.add("selected");
          row.innerHTML = '  <span class="arrow">\u25b6</span> <span class="t-command">' + esc(item.text) + '</span>';
        } else {
          row.innerHTML = '    <span class="t-command">' + esc(item.text) + '</span>';
        }
      } else if (item.type === "empty") {
        if (item.text) {
          row.innerHTML = '  <span class="t-dim">' + esc(item.text) + '</span>';
        }
      }

      wrap.appendChild(row);
    }

    var footer = document.createElement("div");
    footer.className = "picker-footer";
    if (flashMsg) {
      footer.innerHTML = "\n  " + '<span class="flash-msg">' + esc(flashMsg) + '</span>';
    } else {
      footer.innerHTML = "\n  \u2191\u2193 navigate  \u23ce execute  c copy  q quit";
    }
    wrap.appendChild(footer);
  }

  function moveCursor(delta) {
    var next = cursor + delta;
    if (next >= 0 && next < cmdIndices.length) {
      cursor = next;
      render();
    }
  }

  function flash(msg, duration) {
    flashMsg = msg;
    render();
    if (flashTimer) clearTimeout(flashTimer);
    flashTimer = setTimeout(function () {
      flashMsg = "";
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
    clipCopy(cmd).then(function () {
      flash("\u2714 Copied: " + cmd);
    }, function () {
      flash("Could not copy to clipboard");
    });
  }

  function executeCmd() {
    if (cmdIndices.length === 0) return;
    var cmd = items[cmdIndices[cursor]].text;
    flash("$ " + cmd + "  \u2014 would execute in a real terminal", 2500);
  }

  function handleKey(e) {
    if (!active) return;

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
  }

  function scrollTerminal() {
    var term = document.getElementById("terminal");
    if (term) term.scrollTop = term.scrollHeight;
  }

  return {
    mount: mount,
    destroy: destroy,
    isActive: function () { return active; },
  };
}

function esc(text) {
  var d = document.createElement("div");
  d.textContent = text;
  return d.innerHTML;
}
