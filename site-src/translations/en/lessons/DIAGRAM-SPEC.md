# Diagram conventions for the course

This file defines how the SVG figures in the lesson Markdown are drawn, so the 32 lessons look like
one set. Read it before adding a figure, and copy the existing
`lessons/01_hello-cobol/assets/fixed-format-columns.svg` as the reference.

## When a figure earns its place

Only draw when the **picture can replace a paragraph**. Typical valid cases:

- byte layout, field offsets, several views over the same storage;
- data moving between stages (read → validate → match → write);
- two streams advancing in parallel, merging, or branching to different destinations;
- state machines and lifecycles (open / fetch / close);
- contrasts between abstract ideas (sequential scan vs binary search, the three parameter-passing
  modes).

Do not draw:

- a figure that merely redraws a list or table from the text;
- syntax demonstrations (the code block already does that);
- pure decoration (icons, colour blocks, an arrow loop that returns where it started).

## Location and reference

- Put each figure in that lesson's `lessons/<lesson>/assets/`, with a short lowercase
  hyphenated English filename such as `record-layout.svg` or `file-match-flow.svg`.
- Reference it from Markdown with a relative path: `![description](assets/record-layout.svg)`.
- Draw the figure **once** and share it across all three languages, so labels are always English
  (matching COBOL keywords and field names) and never full sentences. Put explanation in the
  caption or the surrounding prose instead.

## Canvas and size

- One `viewBox`; no fixed `width`/`height`, so the figure scales with its container.
- Fit the reading column: `viewBox` width 760–980, height as needed but not above 620.
- It must stay readable at 350px wide (phones): body text no smaller than 11px, and never squeeze
  labels into 20px of space.

## Colours (match the site)

| Purpose | Value |
| --- | --- |
| Card background | `#fcfbf7` |
| Card border | `#d8d2c3` |
| Primary text | `#3f3b3b` |
| Secondary text | `#5f5b52` |
| Accent / link | `#76319f` |

Area colours (fill at 0.16 opacity plus a solid stroke):

| Meaning | Value |
| --- | --- |
| Neutral / input and output | `#64748b` |
| Caution / indicator area | `#d97706` |
| Data / success | `#0d9488` |
| Main flow | `#2563eb` |
| Error / rejection | `#b91c1c` |

## Drawing rules

- Every SVG carries its own pale rounded card background (`rect` with `rx="10"`), so it reads as one
  figure in both light and dark themes instead of black-on-black.
- Font: `font-family="'DM Sans','Noto Sans SC','Noto Sans JP',system-ui,sans-serif"`; use a monospace
  stack for code and field names: `'DM Mono',ui-monospace,monospace`.
- Stroke width 1.5px; corner radius 2–4px; no gradients, shadows, glow or glassmorphism.
- Draw arrows with a `marker` or a plain triangle, and always set `fill` so they do not disappear in
  some renderers.
- Keep text off the border: at least 20px of inner padding on every side.
- No Chinese inside the figure (see "draw once" above), so the three languages never need separate
  copies.
