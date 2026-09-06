# Distro Hopping: A Penguin's Guide to Commitment Issues

Internal tech talk, 2026. Source of truth is `slides.adoc`.

The original PowerPoint is kept as `distro-hopping.pptx`.

## Why Asciidoctor + Reveal.js

This is a 13-slide talk with jokes, terminal snippets, and card grids. A textual format means the deck lives in git, diffs are readable, and you present from a browser.

**Asciidoctor + Reveal.js** is the stack here because:

- AsciiDoc is structured (attributes, includes, roles) without becoming a JS app
- Reveal.js is the usual HTML slide engine: presenter view (`S`), overview (`O`), PDF (`?print-pdf`)
- The source stays one file (`slides.adoc`) plus a theme (`css/theme.css`)

The HTML is compiled with the **Ruby** `asciidoctor-revealjs` gem (Bundler), which is the primary converter. Open `index.html` in a browser to present.

Closest alternatives, if you want to switch later:

| Format | When it's better |
| --- | --- |
| **Slidev** | You want Vue components, live code, and a heavier npm app |
| **Marp** | You want the simplest possible Markdown and don't need card layouts |
| **presenterm** | You want to present *in* the terminal (on-brand, weaker on a projector) |

## Present

Open `index.html` in a browser. Arrow keys, fullscreen (`F`), overview (`O`), and speaker notes (`S`) all work from the file.

## Live reload

Live reload needs a local URL so the browser can be told to refresh. It does not work from `file://`.

```bash
bundle exec ruby watch.rb
```

Then open http://127.0.0.1:4173 — saving `slides.adoc` or `css/theme.css` rebuilds and reloads, and Reveal.js keeps the current slide via the URL hash.

## Rebuild once

```bash
bundle config set --local path .bundle/gems
bundle install
bundle exec ruby build.rb
```

Then refresh `index.html`.

## Edit

- Talk copy: `slides.adoc` — one `==` heading per slide
- Colors, cards, terminal chrome: `css/theme.css`
- Rebuild is `bundle exec ruby build.rb` → `index.html`

Keep layout-heavy bits (card grids, terminal windows) as `++++` HTML passthroughs in the AsciiDoc. The surrounding structure stays AsciiDoc so titles, order, and speaker flow stay easy to edit.
