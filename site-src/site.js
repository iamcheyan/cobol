const themeToggle = document.querySelector('.theme-toggle');
if (themeToggle) {
  const root = document.documentElement;
  const preference = window.matchMedia('(prefers-color-scheme: dark)');
  const savedTheme = () => {
    try { return localStorage.getItem('cobol-theme'); } catch { return null; }
  };
  const syncTheme = () => {
    const dark = root.dataset.theme === 'dark';
    const label = dark ? themeToggle.dataset.lightLabel : themeToggle.dataset.darkLabel;
    themeToggle.setAttribute('aria-pressed', String(dark));
    themeToggle.setAttribute('aria-label', label);
    themeToggle.setAttribute('title', label);
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', dark ? '#161c22' : '#f5f5ed');
  };
  syncTheme();
  themeToggle.addEventListener('click', () => {
    root.dataset.theme = root.dataset.theme === 'dark' ? 'light' : 'dark';
    try { localStorage.setItem('cobol-theme', root.dataset.theme); } catch { /* Private mode can block storage. */ }
    syncTheme();
  });
  preference.addEventListener?.('change', event => {
    if (savedTheme() === 'light' || savedTheme() === 'dark') return;
    root.dataset.theme = event.matches ? 'dark' : 'light';
    syncTheme();
  });
}


// Reference sheet: filter the cheat-sheet sections in place.
const refInput = document.querySelector('#ref-search');
if (refInput) {
  const body = document.querySelector('#ref-body');
  const empty = document.querySelector('#ref-empty');
  // Every filterable unit is one heading plus everything up to the next heading.
  const units = [];
  let current = null;
  for (const node of [...body.children]) {
    if (/^H[23]$/.test(node.tagName)) {
      current = { nodes: [node], text: node.textContent };
      units.push(current);
    } else if (current) {
      current.nodes.push(node);
      current.text += ' ' + node.textContent;
    } else {
      units.push({ nodes: [node], text: node.textContent });
    }
  }
  for (const unit of units) {
    unit.haystack = unit.text.toLocaleLowerCase();
    // Tables are filtered row by row so a single matching row stays visible.
    unit.tables = unit.nodes
      .filter(n => n.classList.contains('table-wrap'))
      .map(wrap => ({ wrap, rows: [...wrap.querySelectorAll('tbody tr')] }));
  }
  const applyFilter = () => {
    const query = refInput.value.trim().toLocaleLowerCase();
    let anyVisible = false;
    for (const unit of units) {
      const headingHit = !query || unit.haystack.includes(query);
      let unitVisible = false;
      for (const { wrap, rows } of unit.tables) {
        let rowHit = false;
        for (const row of rows) {
          const show = headingHit || row.textContent.toLocaleLowerCase().includes(query);
          row.hidden = !show;
          if (show) rowHit = true;
        }
        wrap.hidden = !rowHit;
        if (rowHit) unitVisible = true;
      }
      const nonTable = unit.nodes.filter(n => !n.classList.contains('table-wrap'));
      const showNonTable = headingHit;
      for (const node of nonTable) node.hidden = !showNonTable;
      if (showNonTable || unitVisible) {
        unitVisible = true;
      }
      // Keep the heading visible whenever any row under it is shown.
      if (unitVisible && !showNonTable) {
        for (const node of nonTable) node.hidden = false;
      }
      if (unitVisible) anyVisible = true;
    }
    if (empty) empty.hidden = anyVisible;
  };
  refInput.addEventListener('input', applyFilter);
}

const search = document.querySelector('#course-search');
if (search) {
  const links = [...document.querySelectorAll('#lesson-list a')];
  search.addEventListener('input', () => {
    const query = search.value.trim().toLocaleLowerCase();
    for (const link of links) {
      const matches = link.textContent.toLocaleLowerCase().includes(query)
        || (link.getAttribute('title') || '').toLocaleLowerCase().includes(query);
      link.hidden = !matches;
    }
  });
}

const navToggle = document.querySelector('.nav-toggle');
const siteNav = document.querySelector('#site-nav');
if (navToggle && siteNav) {
  navToggle.addEventListener('click', () => {
    const open = siteNav.classList.toggle('open');
    navToggle.setAttribute('aria-expanded', String(open));
  });
}

const courseToggle = document.querySelector('.course-toggle');
const courseBody = document.querySelector('#course-body');
const courseNav = document.querySelector('.course-nav');
const readingLayout = document.querySelector('.reading-layout');
if (courseToggle && courseBody && courseNav && readingLayout) {
  const labels = {
    expand: courseToggle.dataset.expandLabel,
    collapse: courseToggle.dataset.collapseLabel,
  };
  const setOpen = open => {
    courseBody.classList.toggle('open', open);
    courseBody.hidden = !open;
    courseNav.classList.toggle('collapsed', !open);
    readingLayout.classList.toggle('sidebar-collapsed', !open);
    courseToggle.setAttribute('aria-expanded', String(open));
    courseToggle.setAttribute('aria-label', open ? labels.collapse : labels.expand);
    courseToggle.setAttribute('title', open ? labels.collapse : labels.expand);
    courseToggle.querySelector('.course-toggle-label').textContent = open
      ? courseToggle.dataset.openLabel : courseToggle.dataset.closedLabel;
    const count = courseToggle.querySelector('.course-count');
    if (count) count.hidden = !open;
  };
  const mobile = window.matchMedia('(max-width: 760px)');
  let open = !mobile.matches;
  setOpen(open);
  courseToggle.addEventListener('click', () => {
    open = courseNav.classList.contains('collapsed');
    setOpen(open);
  });
  mobile.addEventListener('change', event => {
    open = !event.matches;
    setOpen(open);
  });
}

// Fixed-format COBOL source viewer: preserve the source columns, add an ISPF-style
// ruler/sequence gutter, and tokenise locally without a third-party highlighter.
const cobolViews = document.querySelectorAll('[data-cobol-source="true"]');
if (cobolViews.length) {
  const keywords = new Set(`ACCEPT ADD ALL ALTER AND CALL CANCEL CLOSE COMPUTE CONTINUE COPY
    DATA DELETE DISPLAY DIVIDE DIVISION ELSE END-CALL END-COMPUTE END-IF END-PERFORM
    END-READ END-SEARCH END-START END-STRING END-UNSTRING END-WRITE ENTRY ENVIRONMENT
    EVALUATE EXIT FD FILE SECTION FROM GIVING GO GOBACK IF INITIALIZE INSPECT INTO IS
    LINKAGE MOVE MULTIPLY NOT OCCURS OPEN OR PERFORM PROCEDURE PROGRAM-ID READ REDEFINES
    REPLACING RETURN REWRITE SEARCH SECTION SELECT SET SORT START STOP STRING SUBTRACT
    THEN TO UNSTRING UNTIL VALUE WHEN WORKING-STORAGE WRITE`.trim().split(/\s+/));
  const escape = text => text.replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const tokenPattern = /("(?:""|[^"])*"|'(?:''|[^'])*'|\b(?:PIC|PICTURE)\b|\b(?:COMP-3|COMP|DISPLAY|BINARY|PACKED-DECIMAL|INDEXED|SEQUENTIAL|LINE\s+SEQUENTIAL)\b|\b(?:[0-9]{1,2})\b|[A-Z][A-Z0-9-]*(?=\s*\.)|[A-Z][A-Z0-9-]*|\d+(?:\.\d+)?|[.,;()])/gi;
  const highlight = text => {
    let out = '', last = 0;
    for (const m of text.matchAll(tokenPattern)) {
      const token = m[0], at = m.index;
      out += escape(text.slice(last, at));
      const upper = token.toUpperCase();
      let cls = '';
      if (/^["']/.test(token)) cls = ' cobol-string';
      else if (/^(PIC|PICTURE)$/i.test(token)) cls = ' cobol-picture-key';
      else if (/^(COMP-3|COMP|DISPLAY|BINARY|PACKED-DECIMAL|INDEXED|SEQUENTIAL)$/i.test(token)) cls = ' cobol-clause';
      else if (/^\d/.test(token)) cls = ' cobol-number';
      else if (keywords.has(upper)) cls = ' cobol-keyword';
      else if (/^[A-Z][A-Z0-9-]*$/i.test(token)) cls = ' cobol-identifier';
      else if (/^[.,;()]$/.test(token)) cls = ' cobol-punctuation';
      out += cls ? `<span class="${cls.trim()}">${escape(token)}</span>` : escape(token);
      last = at + token.length;
    }
    return out + escape(text.slice(last));
  };
  for (const view of cobolViews) {
    const code = view.querySelector('pre code');
    const pre = view.querySelector('pre');
    if (!code || !pre) continue;
    const source = code.textContent.replace(/\r\n?/g, '\n');
    const lines = source.split('\n');
    const ruler = document.createElement('div');
    ruler.className = 'cobol-ruler';
    ruler.setAttribute('aria-hidden', 'true');
    ruler.innerHTML = '<span class="ruler-segment ruler-sequence">1───6</span><span class="ruler-segment ruler-indicator">7</span><span class="ruler-segment ruler-area-a">8-11</span><span class="ruler-segment ruler-area-b"><span>12</span><span>72</span></span><span class="ruler-segment ruler-identification">73──80</span>';
    const mobileTools = document.createElement('div');
    mobileTools.className = 'cobol-mobile-tools';
    const fixedToggle = document.createElement('button');
    fixedToggle.className = 'cobol-fixed-toggle';
    fixedToggle.type = 'button';
    const labels = document.documentElement.lang === 'ja'
      ? {read: '読みやすく表示', fixed: '固定形式で表示', hint: '列位置を確認するときだけ固定形式に切り替えます'}
      : document.documentElement.lang === 'en'
        ? {read: 'Readable view', fixed: 'Fixed columns', hint: 'Switch to fixed columns only when checking source positions'}
        : {read: '易读模式', fixed: '固定列模式', hint: '需要核对列位置时再切换固定列模式'};
    fixedToggle.textContent = labels.fixed;
    fixedToggle.setAttribute('aria-pressed', 'false');
    const mobileHint = document.createElement('span');
    mobileHint.className = 'cobol-mobile-hint';
    mobileHint.textContent = labels.hint;
    mobileTools.append(mobileHint, fixedToggle);
    fixedToggle.addEventListener('click', () => {
      const fixed = pre.classList.toggle('mobile-fixed');
      pre.scrollLeft = 0;
      fixedToggle.textContent = fixed ? labels.read : labels.fixed;
      fixedToggle.setAttribute('aria-pressed', String(fixed));
    });
    const rows = document.createElement('div');
    rows.className = 'cobol-lines';
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const row = document.createElement('div');
      row.className = 'cobol-line';
      const number = document.createElement('span');
      number.className = 'cobol-line-number';
      number.textContent = String(i + 1).padStart(5, '0');
      number.setAttribute('aria-hidden', 'true');
      const text = document.createElement('span');
      text.className = 'cobol-line-text';
      // Keep a full-width desktop/fixed view and a mobile reading view that omits
      // the six sequence columns plus indicator, then wraps within the viewport.
      const desktopText = document.createElement('span');
      desktopText.className = 'cobol-desktop-text';
      const readingText = document.createElement('span');
      readingText.className = 'cobol-reading-text';
      const indicator = line.charAt(6);
      const comment = indicator === '*' || indicator === '/';
      desktopText.innerHTML = comment ? `<span class="cobol-comment">${escape(line)}</span>` : highlight(line);
      const bodyText = line.slice(7);
      readingText.innerHTML = comment ? `<span class="cobol-comment">${escape(bodyText)}</span>` : highlight(bodyText);
      text.append(desktopText, readingText);
      row.append(number, text);
      rows.append(row);
    }
    pre.classList.add('cobol-editor');
    pre.replaceChildren(mobileTools, ruler, rows);
    pre.setAttribute('aria-label', 'COBOL source with fixed-format column ruler');
  }
}

const workspace = document.querySelector('.lesson-workspace');
if (workspace) {
  const tabs = [...workspace.querySelectorAll('.lesson-tab')];
  const panels = [...workspace.querySelectorAll('.lesson-panel')];
  const activateTab = (key, updateHash = true) => {
    const tab = tabs.find(item => item.dataset.tab === key);
    if (!tab) return;
    tabs.forEach(item => {
      const active = item === tab;
      item.classList.toggle('selected', active);
      item.setAttribute('aria-selected', String(active));
      item.tabIndex = active ? 0 : -1;
    });
    panels.forEach(panel => {
      const active = panel.dataset.panel === key;
      panel.classList.toggle('active', active);
      panel.hidden = !active;
    });
    if (updateHash) history.replaceState(null, '', `#tab-${key}`);
  };

  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => activateTab(tab.dataset.tab));
    tab.addEventListener('keydown', event => {
      if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
      event.preventDefault();
      const next = event.key === 'Home' ? 0 : event.key === 'End' ? tabs.length - 1
        : (index + (event.key === 'ArrowRight' ? 1 : tabs.length - 1)) % tabs.length;
      tabs[next].focus();
      activateTab(tabs[next].dataset.tab);
    });
  });

  const resourceChoices = [...workspace.querySelectorAll('.resource-choice')];
  const resourceViews = [...workspace.querySelectorAll('.resource-view')];
  const activateResource = index => {
    resourceChoices.forEach((button, i) => button.classList.toggle('selected', i === index));
    resourceViews.forEach((view, i) => { view.hidden = i !== index; });
  };
  resourceChoices.forEach((button, index) => button.addEventListener('click', () => activateResource(index)));
  if (resourceChoices.length) activateResource(0);

  const tabFromHash = () => location.hash.match(/^#tab-(guide|exercise|answer|resources)$/)?.[1];
  const initial = tabFromHash();
  if (initial) activateTab(initial, false);
  window.addEventListener('hashchange', () => {
    const key = tabFromHash();
    if (key) activateTab(key, false);
  });
}
