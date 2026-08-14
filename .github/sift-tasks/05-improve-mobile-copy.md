---
id: improve-mobile-copy
title: "[Sift seed] Clarify the mobile voting instructions"
labels: sift:run,sift:seed,priority:p2
difficulty: intermediate
---

Make the voting instruction understandable at narrow viewport widths. Preserve the existing server-side action contract and add or update a Playwright assertion if the copy is user-visible.

Acceptance criteria:
- A player can tell what to select and submit on a phone-sized viewport.
- AI seats remain explicitly fictional AI roles.
- The change does not require an API key or runtime model.
