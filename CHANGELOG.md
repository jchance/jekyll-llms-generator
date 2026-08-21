# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2025-07-08

### Added
- Initial release
- `Jekyll::Generator` that builds `/llms.txt` automatically on each build
- Support for posts, named collections, and explicit page URLs per section
- Per-document opt-out via `llms_txt: false` frontmatter
- Optional `/llms-full.txt` with stripped-HTML content (config: `full: true`)
- Optional `<link rel="ai" href="/llms.txt">` injection into HTML `<head>`
- Limit control per section (`limit:`)
- Geocoding-style configuration with `title`, `tagline`, `intro`, and `sections`
