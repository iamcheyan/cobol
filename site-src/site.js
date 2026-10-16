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
      link.hidden = !link.textContent.toLocaleLowerCase().includes(query);
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
if (courseToggle && courseBody) {
  courseToggle.addEventListener('click', () => {
    const open = courseBody.classList.toggle('open');
    courseToggle.setAttribute('aria-expanded', String(open));
  });
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
