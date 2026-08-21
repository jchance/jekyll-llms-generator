# Changelog

All notable changes to this project will be documented in this file.

## [0.3.1] - 2026-08-20

### Changed
- Repository renamed to match gem name: github.com/jchance/jekyll-llms-generator

## [0.3.0] - 2026-08-20

### Added
- When `full: true`, `llms.txt` now includes a `[Full content version](/llms-full.txt)` link in the header section so LLM crawlers can discover the full content file from the compact index

## [0.2.0] - 2026-08-20

### Changed
- `llms.txt`: descriptions now use first complete sentence instead of hard 200-character truncation — cleaner, more natural output for LLMs
- `llms-full.txt`: entries now use `### [Title](url)` headings, `> description` blockquotes, and `---` separators between articles, making article boundaries unambiguous for LLM parsers

## [0.1.0] - 2026-08-20

### Added
- Initial release
- `Jekyll::Generator` that builds `/llms.txt` automatically on each build
- Support for posts, named collections, and explicit page URLs per section
- Per-document opt-out via `llms_txt: false` frontmatter
- Optional `/llms-full.txt` with stripped-HTML content (config: `full: true`)
- Optional `<link rel="ai" href="/llms.txt">` injection into HTML `<head>`
- Limit control per section (`limit:`)
- Geocoding-style configuration with `title`, `tagline`, `intro`, and `sections`
