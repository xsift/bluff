---
title: "[Sift seed] Document the legal game actions"
labels: sift:run,sift:seed,priority:p3
---

Improve the game specification with a concise table of legal actions, phases, and rejection cases. Link to the implementation instead of duplicating source code.

Acceptance criteria:
- The table covers describe, question, answer, and vote.
- It states that the server is the only裁判 and that input is untrusted.
- This is documentation-only and uses no runtime model.
