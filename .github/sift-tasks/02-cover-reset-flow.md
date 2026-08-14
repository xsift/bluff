---
title: "[Sift seed] Add a regression test for starting a second game"
labels: sift:run,sift:seed,priority:p1
---

Add a deterministic application test proving that starting a new game does not expose events or private words from an earlier game. Use the existing in-memory test helpers; do not add a database or model dependency.

Acceptance criteria:
- The test is deterministic.
- Private seat context remains isolated.
- `pnpm test` passes.
