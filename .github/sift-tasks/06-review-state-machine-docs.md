---
id: review-state-machine-docs
title: "[Sift seed] Add a state-machine transition table"
labels: sift:run,sift:seed,priority:p0
difficulty: advanced
---

Add a small, implementation-backed transition table to the game specification and test one invalid transition. Keep the program as the sole authority for phase, identity, and outcome.

Acceptance criteria:
- The table names lobby, describing, questioning, voting, and revealed.
- An invalid transition is covered by a deterministic test.
- No model, credential, or network dependency is introduced.
