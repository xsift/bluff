# Review — Issue #7 · round 1（完整关闭包）

> 基线副本。同内容已发 Issue 评论（见 issue #7 评论区）。
> 复审（round 2）只输出 DELTA，禁止全文克隆。

- 审核对象：`feat/issue-7-close-playable-mvp-p2-and-deferred-runtime-gaps` @ 005b662
- 验证：`pnpm test` 11 passed；`pnpm build` 通过；`pnpm e2e` 2 passed（桌面整局 + 手机壳，重跑 5/5 稳定）；同毫秒 POST 探针：id 不同但内容相同；recent 探针：完成后重载列表含该局
- 已核对 PRD/DESIGN/WBS/STATUS/testing/strategy.md 与 issue #1 round1 关闭包；未修改生产代码

## Finding 列表

[P1] **SEED-UNREPLACED** — P2-1 只关了一半：`app/api/games/route.ts` 仍 `newGame(Date.now() >>> 0)`，种子生成未替换；`identitySource.nextSeed()`（randomInt）在生产路径是死代码（route 恒传显式 seed）。同毫秒两局 id 已不同（覆盖问题已解），但内容仍完全相同（词对/分类/卧底位）。
标尺：`grep -n "Date.now() >>> 0" app/` 无命中，route 改调 `newGame()`；`pnpm test` 绿。证据缺口：新增单测注入的是生产不用的 identity source，不覆盖 route 路径。fixer=same

[P1] **MOBILE-COVERAGE-NOT-CLOSED** — P2-4 的移动端项未关：测试仅改名为 "renders the playable game shell at phone width"，显式声明只测壳，未在 390×844 跑完整局；testing/strategy.md 要求「手机宽度完整跑一局」。
标尺：手机宽度 e2e 按桌面整局步骤跑通至「获胜」heading（或测试名保持 shell 且同步修改 strategy 声明——按 issue 语义应做前者）。证据缺口：现有测试只断言「你的私密信息」可见。fixer=same

[P2] **TEST-CASES-PARTIAL** — 新增非法迁移用例覆盖 describe@lobby、vote@describing，但原 gap 列出的 describe@questioning、answer@questionIndex=0（未提问先回答）仍无覆盖；p2 视角 view 隔离也无显式断言（现有仅 p1 view）。
标尺：表驱动补齐上述用例。fixer=same

[P2] **E2E-INPUT-RACE** — 探针复现空文本提交（「请输入 1 到 120 个字符」）：React 受控 textarea 在命令成功后 `setText("")`，fill→click 过快的自动化步骤会发出空 text；真实 e2e 7/7 通过，属潜在 flake，CI 压力下可能误报。
标尺：e2e 连续 10 次全绿，或提交按钮在必填 text 为空时禁用。证据缺口：2/2 探针复现（与真实 e2e 仅中间等待不同）。fixer=same

[P2] **RECENT-E2E-ASSERTION-WEAK** — e2e 重载后只断言「最近十局」heading 可见（空列表也渲染该 heading），未断言该局出现在列表中；探针手工验证功能正常，但验收测试未守护。
标尺：e2e 重载后断言 `.recent li` 数量 ≥1 且含「获胜」文案。fixer=same

[DEFER] SQLite 持久化、幂等键上界+鉴权、p1 硬编码泛化 —— 均未在本 MR 触碰，符合 issue 语义，维持 backlog。

## Scope summary

| 级别 | 数量 | 本轮是否实施 |
|---|---|---|
| P0 | 0 | 是 |
| P1 | 2 | 是 |
| P2 | 3 | 否（记录） |
| DEFER | 3 | 否（backlog） |

## Verdict

**NEED-FIX** — 未关 P1：SEED-UNREPLACED、MOBILE-COVERAGE-NOT-CLOSED。不关闭 Issue、不建议合并。
