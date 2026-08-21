# jekyll-llms-txt

A Jekyll generator plugin that automatically builds an `/llms.txt` file every time your site builds — keeping AI language models up to date with your latest content.

[![Gem Version](https://badge.fury.io/rb/jekyll-llms-txt.svg)](https://badge.fury.io/rb/jekyll-llms-txt)

## What is llms.txt?

[llms.txt](https://llmstxt.org/) is an emerging convention that lets website owners expose a structured plain-text summary of their site's content for AI models and LLM crawlers. It's like `robots.txt`, but instead of telling crawlers what to ignore it tells them what matters and where to find it.

## Installation

Add to your site's `Gemfile`:

```ruby
gem "jekyll-llms-txt", "~> 0.1"
```

Add to your `_config.yml` plugins list:

```yaml
plugins:
  - jekyll-llms-txt
```

Then run `bundle install`.

## Configuration

All configuration lives under the `llms_txt:` key in `_config.yml`.

```yaml
llms_txt:
  title: "Jason Chance"
  tagline: "Downtown revitalization, local government technology, and public finance."
  intro: |
    Jason Chance is a DDA director and web developer writing about public finance,
    local government technology, and downtown revitalization.
  link_tag: true       # inject <link rel="ai" href="/llms.txt"> into every HTML page (default: true)
  full: false          # also generate /llms-full.txt with full stripped-HTML content (default: false)
  sections:
    - title: "Blog Posts"
      collection: posts
      limit: 20          # optional: cap number of items
    - title: "Projects"
      collection: projects
    - title: "Pages"
      pages:
        - /about/
        - /contact/
```

### Options

| Key | Default | Description |
|-----|---------|-------------|
| `title` | site `title` | H1 heading at the top of `llms.txt` |
| `tagline` | site `description` | Blockquote line below the title |
| `intro` | _(none)_ | Optional paragraph after the tagline |
| `link_tag` | `true` | Inject `<link rel="ai" href="/llms.txt">` into HTML head |
| `full` | `false` | Also generate `/llms-full.txt` with full content |
| `sections` | `[]` | Array of section definitions (see below) |

### Section options

Each section must have a `title`. Specify one or both of `collection` and `pages`.

| Key | Description |
|-----|-------------|
| `collection` | Jekyll collection name (`posts`, `projects`, etc.) |
| `limit` | Max number of items from this collection |
| `pages` | Array of page URLs to include |

### Opt-out per document

Add `llms_txt: false` to any post or collection document's frontmatter to exclude it:

```yaml
---
title: "Internal Draft"
llms_txt: false
---
```

### Description used in llms.txt

The plugin looks for a description in this order:

1. `description:` frontmatter
2. `tagline:` frontmatter
3. Automatically generated excerpt (first paragraph)

## Output

**`/llms.txt`** — compact reference with title, tagline, intro, and a bulleted list of links per section.

**`/llms-full.txt`** — same structure but each item also includes the full plain-text content of the document (when `full: true`).

## Discovery

AI crawlers discover `llms.txt` by checking `<your-site>/llms.txt` directly, the same way they check `robots.txt` or `sitemap.xml`. The optional `<link rel="ai">` injection in the `<head>` of every page provides an additional signal.

You can also submit your site to the [llmstxt.org directory](https://directory.llmstxt.cloud/) for broader discovery.

## Compatibility

- Jekyll 3.7 – 4.x
- Ruby 2.7+
- Works with GitHub Pages via the `remote_theme` workflow (plugin must be listed in `plugins:`)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE.txt) © Jason Chance
