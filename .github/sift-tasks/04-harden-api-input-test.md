---
title: "[Sift seed] Add an API test for oversized player text"
labels: sift:run,sift:seed,priority:p1
---

Add a focused test for the existing input boundary: an oversized player submission must be rejected without changing game state. Do not weaken validation or introduce a network service.

Acceptance criteria:
- The test asserts the rejection and unchanged version.
- It runs with the repository's existing test command.
- No external API or paid model is needed.
