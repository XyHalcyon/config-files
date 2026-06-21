# Obsidian Dashboard Patterns (DataviewJS + Excalidraw + CSS)

Build feature-rich Obsidian home dashboards using only installed plugins — no extra
plugin installs required. Uses DataviewJS for dynamic queries, Excalidraw for
hand-drawn banner art, and CSS snippets for custom styling.

## Core Principle

Prefer DataviewJS (`dataviewjs` code blocks) over raw Dataview DQL for dashboards.
DQL is declarative and limited; DataviewJS gives full programmatic control over
DOM elements via `dv.el()` and `dv.container`.

## Plugin Stack (minimum)

| Plugin | Role |
|--------|------|
| **Dataview** | Dynamic queries, `dataviewjs` blocks |
| **Excalidraw** | Hand-drawn SVG banners/headers |
| **homepage** | Auto-open Home.md on startup |
| **Templater** | Dynamic dates in templates (optional) |

## Pattern 1: Stat Cards Grid

Four gradient-colored stat cards showing vault metrics. Pure dataviewjs.

```dataviewjs
const allPages = dv.pages('""').where(p => p.file.folder != "Templates");
const totalNotes = allPages.length;
const folders = new Set(allPages.map(p => p.file.folder)).size;
const tasks = allPages.file.tasks;
const completed = tasks.where(t => t.completed).length;
const weekAgo = dv.date("now").minus({days: 7});
const recent = allPages.where(p => p.file.mtime >= weekAgo).length;

const cards = [
  { icon: "📄", num: totalNotes, label: "笔记总数", cls: "stat-card-blue" },
  { icon: "📁", num: folders, label: "知识领域", cls: "stat-card-green" },
  { icon: "✅", num: completed + "/" + tasks.length, label: "已完成", cls: "stat-card-orange" },
  { icon: "🔥", num: recent, label: "本周活跃", cls: "stat-card-cyan" }
];

const grid = dv.el("div", "", { cls: "stat-cards" });
for (const c of cards) {
  const card = grid.createEl("div", { cls: "stat-card " + c.cls });
  card.createEl("div", { text: c.icon, cls: "stat-icon" });
  card.createEl("div", { text: String(c.num), cls: "stat-number" });
  card.createEl("div", { text: c.label, cls: "stat-label" });
}
dv.container.appendChild(grid);
```

Requires CSS for `.stat-cards`, `.stat-card`, `.stat-card-blue` etc.
(See CSS Snippet Workflow below.)

## Pattern 2: Folder Navigation Grid

Grid of clickable cards, one per vault folder, each showing note count and
last-modified time. All driven by dataviewjs.

```dataviewjs
const folderIcons = { "AI": "🤖", "Python": "🐍", "Java": "☕", /* ... */ };
const pages = dv.pages('""').where(p => p.file.folder != "Templates");

// Group by folder
const folderMap = new Map();
for (const p of pages) {
  const f = p.file.folder || "📌 根目录";
  if (!folderMap.has(f)) folderMap.set(f, []);
  folderMap.get(f).push(p);
}

const grid = dv.el("div", "", { cls: "folder-grid" });
for (const [folder, items] of [...folderMap.entries()].sort()) {
  const icon = folderIcons[folder] || "📁";
  const latest = items.reduce((max, p) => p.file.mtime > max ? p.file.mtime : max, dv.date("2000-01-01"));
  const days = dv.date("now").diff(latest, "days").days;

  const card = grid.createEl("a", {
    cls: "folder-card internal-link",
    attr: { "data-href": folder }  // Obsidian internal link
  });
  card.createEl("div", { text: icon, cls: "folder-icon" });
  card.createEl("div", { text: folder, cls: "folder-name" });
  card.createEl("div", {
    text: items.length + " 篇 · " + (days <= 0 ? "今天" : days + "天前"),
    cls: "folder-count"
  });
}
dv.container.appendChild(grid);
```

## Pattern 3: Progress Bar + Task Dashboard

Top-level progress bar with color-coded high/low priority task sections.

```dataviewjs
const tasks = dv.pages('""').file.tasks;
const total = tasks.length;
const completed = tasks.where(t => t.completed).length;
const pct = total > 0 ? Math.round(completed / total * 100) : 0;
const barColor = pct < 30 ? "#f5576c" : pct < 70 ? "#e9b44c" : "#38ef7d";

// Progress bar
const wrapper = dv.el("div", "", { cls: "progress-wrapper" });
const header = wrapper.createEl("div", { cls: "progress-header" });
header.createEl("span", { text: `已完成 ${completed} / ${total}` });
header.createEl("span", { text: `${pct}%`, attr: { style: "color:" + barColor } });
const outer = wrapper.createEl("div", { cls: "progress-bar-outer" });
outer.createEl("div", { cls: "progress-bar-inner", attr: { style: `width:${pct}%;background:${barColor}` } });
dv.container.appendChild(wrapper);

// Split into high/low sections
const sections = dv.el("div", "", { cls: "task-sections" });
const highDiv = sections.createEl("div", { cls: "task-section task-section-high" });
highDiv.createEl("h3", { text: "🔴 高优先级" });
const lowDiv = sections.createEl("div", { cls: "task-section task-section-low" });
lowDiv.createEl("h3", { text: "🟢 低优先级" });

for (const t of tasks.where(t => !t.completed)) {
  const target = t.text.includes("🔴") ? highDiv : lowDiv;
  const row = target.createEl("div");
  row.createEl("span", { text: "☐ " });
  row.createEl("span", { text: t.text });
}
dv.container.appendChild(sections);
```

## Pattern 4: Recent Activity Timeline

Vertical timeline with relative timestamps and folder badges.

```dataviewjs
function relTime(mtime) {
  const diff = dv.date("now").diff(mtime, "minutes").minutes;
  if (diff < 1) return "刚刚";
  if (diff < 60) return Math.floor(diff) + " 分钟前";
  if (diff < 1440) return Math.floor(diff/60) + " 小时前";
  if (diff < 10080) return Math.floor(diff/1440) + " 天前";
  return mtime.toFormat("yyyy-MM-dd");
}

const pages = dv.pages('""')
  .where(p => p.file.folder != "Templates")
  .sort(p => p.file.mtime, "desc").limit(10);

const timeline = dv.el("div", "", { cls: "timeline" });
for (const p of pages) {
  const item = timeline.createEl("div", { cls: "timeline-item" });
  item.createEl("a", { text: p.file.name, cls: "tl-name internal-link", attr: { "data-href": p.file.path } });
  item.createEl("span", { text: relTime(p.file.mtime), cls: "tl-time" });
  item.createEl("span", { text: p.file.folder || "📌", cls: "tl-folder" });
}
dv.container.appendChild(timeline);
```

## Pattern 5: Excalidraw Hand-Drawn Banner

Create a hand-drawn banner as an `.excalidraw` JSON file, then embed it in
the dashboard with standard Obsidian embed syntax:

```markdown
![[HomeBanner.excalidraw]]
```

Excalidraw JSON structure for a simple banner (800×160 canvas):

- **Title**: `text` element, large font (fontSize 44, fontFamily 4), centered
- **Subtitle**: `text` element, smaller font (fontSize 22, fontFamily 2), gray
- **Decorative underline**: `line` element, wavy points, roughness 2
- **Accent dots**: `ellipse` elements, small (10-16px), warm colors, roughness 2
- **Bottom separator**: `line` element, low opacity, gentle wave

Key JSON keys per element type:

| Element | Required keys |
|---------|--------------|
| `text` | `text`, `fontSize`, `fontFamily` (1=Virgil, 2=Helvetica, 4=Cascadia), `textAlign`, `originalText`, `autoResize: true` |
| `line` | `points: [[x1,y1], [x2,y2], ...]`, `strokeWidth`, `roughness`, `roundness: {type:2}` |
| `ellipse` | `x`, `y`, `width`, `height`, `strokeColor`, `backgroundColor`, `roughness` |

All elements need: `id`, `type`, `x`, `y`, `strokeColor`, `fillStyle`, `strokeWidth`,
`roughness`, `opacity`, `seed`, `version: 1`, `isDeleted: false`.

AppState: `{"gridSize": 20, "viewBackgroundColor": "transparent"}`

## CSS Snippet Workflow

### 1. Create the snippet

Place a `.css` file in `.obsidian/snippets/`:

```
.obsidian/snippets/dashboard.css
```

Style classes used by the patterns above:
- `.stat-cards`, `.stat-card`, `.stat-card-blue/green/orange/cyan`, `.stat-icon`, `.stat-number`, `.stat-label`
- `.folder-grid`, `.folder-card`, `.folder-icon`, `.folder-name`, `.folder-count`
- `.progress-wrapper`, `.progress-header`, `.progress-bar-outer`, `.progress-bar-inner`
- `.task-sections`, `.task-section`, `.task-section-high`, `.task-section-low`
- `.timeline`, `.timeline-item`, `.tl-time`, `.tl-name`, `.tl-folder`
- `.dashboard-section-header`, `.section-icon`
- `.quick-actions`, `.quick-action`
- `.excalidraw-banner`

Design guidelines:
- Use `var(--background-primary-alt)` and `var(--background-modifier-border)` to
  respect Obsidian's theme (works for both dark and light modes)
- Gradient backgrounds for stat cards create visual punch
- `transition: transform 0.2s ease, box-shadow 0.2s ease` on hover
- `@media` queries for responsive layout (2-col at 1000px, 1-col at 600px)
- Shimmer animation on progress bar gives a "live" feel

### 2. Enable the snippet

Update `.obsidian/appearance.json` to include the snippet name:

```json
{
  "enabledCssSnippets": ["dashboard", "other-snippet"]
}
```

Or toggle manually: Settings → Appearance → CSS snippets → toggle on.

## Workflow: Plan-First for Obsidian Modifications

When the user asks to modify their Obsidian vault (especially Home page or
dashboard):

1. **Survey first**: check which plugins are installed, read the current file,
   check existing CSS snippets
2. **Design a plan**: present a clear ASCII layout sketch of what the result
   will look like, list every file to create/modify, and name which plugin
   powers each feature
3. **Get approval**: user reviews and adjusts before any file is touched
4. **Implement**: create files, enable snippets, verify paths
5. **Never install new plugins** unless the user explicitly asks for one

## Path Handling on Windows + WSL

When the Obsidian vault is on a Windows drive (e.g. `E:\code\obsidian-repo\`):

| Tool | Path format | Notes |
|------|------------|-------|
| `terminal` (WSL) | `/mnt/e/code/obsidian-repo/` | WSL-mounted paths work |
| `execute_code` (Windows Python) | `E:\code\obsidian-repo\` | Windows native paths |
| `read_file` | May fail on `/mnt/` paths | prefer `terminal cat` for WSL-side reads |
| `write_file` | May fail with special chars | prefer `terminal` with `python3 -c` or `execute_code` |

`execute_code` is preferred for creating CSS and MD files on Windows vaults because
it runs in the Windows Python environment and handles `E:\` paths natively.

## Common Pitfalls

- **DataviewJS `dv.date()` needs the "now" string**: `dv.date("now")` not `new Date()`
- **`dv.pages('""')` matches all pages**: empty string `""` wrapped in quotes
- **Internal links in dataviewjs**: use `attr: { "data-href": folder }` with `cls: "internal-link"` on the `<a>` element
- **CSS snippets must be enabled**: creating the `.css` file isn't enough; update `appearance.json` or toggle in Settings
- **Excalidraw text elements need `originalText`**: it's a required field for the plugin to render correctly
- **Excalidraw `textAlign`**: "center" | "left" | "right" (lowercase)
- **Dataview task query**: `dv.pages('""').file.tasks` returns ALL tasks across ALL notes
- **Relative time formatting**: `dv.date().diff()` returns an object with `.days`, `.hours`, `.minutes` properties
