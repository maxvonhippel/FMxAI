# Editing the conference site

The conference homepage is built from these markdown files. Edit them with any text editor (or directly on GitHub) and the site updates — no code changes required.

| File | What it controls |
|------|------------------|
| `hero.md` | Title, date line, and venue line at the top of the page |
| `logistics.md` | Logistics section (venue, dress, weather, security, parking, etc.) |
| `agenda.md` | Full conference agenda (three days) |
| `community.md` | "The FMxAI community" section near the bottom |

## Markdown tips

- **Bold text:** wrap in double asterisks — `**like this**`
- *Italics:* single asterisks — `*like this*`
- Headings start with `#` (one `#` = top-level, `##` = section, `###` = subsection)
- Tables use pipes (`|`) — see `agenda.md` for the format
- A blank line starts a new paragraph
- Two trailing spaces at the end of a line force a line break without a paragraph

## Class hints (advanced)

Lines ending with `{.classname}` get extra styling. Already-used classes:

- `{.eyebrow}` — small green tagline
- `{.dates}` — italic conference dates
- `{.venue}` — muted venue line
- `{.notice}` — red attention text (e.g. the ID-required reminder)
- `{.agenda-note}` — small italic footnote under the agenda
- `{.map-callout-link}` — turns a link into the styled "open the map" callout

You usually won't need to touch these — they're already in place. If you add a new section that needs styling, ask the developer.
