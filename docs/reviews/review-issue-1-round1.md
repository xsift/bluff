# Review — Issue #1 · round 1（完整关闭包）

> 基线副本。同内容已发 Issue 评论（https://github.com/xsift/bluff/issues/1#issuecomment-5289682540）。
> 复审（round 2）只输出 DELTA，禁止全文克隆。

- 审核对象：`feat/issue-1-deliver-playable-text-mvp-for-bot-or-bluff` @ 772f2a3（origin tip）
- 验证：`pnpm test` 7 passed；`pnpm build` 通过；`pnpm exec playwright test` 2 passed；`pnpm dev` 正常
- 已核对 PRD/DESIGN/WBS/STATUS/specs/game.md/testing/strategy.md；未修改生产代码

## Finding 列表

[P1] **BOT-VOTE-BIAS** — 规则机器人投票固定（p2→p3、p3→p2、p4→p2）且从不投 p1：spy∈{p3,p4} 平民必败、spy=p1 卧底永不被抓，3/4 种子下人类无法以平民获胜，胜负由 seed 预定。
标尺：`node /tmp/sim2.mjs` 中 `spy=p3`/`spy=p4` 行 `civilian-can-win` 必须为 true，且 `botVoteTarget` 不得硬编码排除 p1。证据缺口：无胜负公平性断言。fixer=switch:agent::gpt-5.6-terra

[P1] **BOT-EVENT-VALIDATION** — 违反 specs/game.md 不变量 #6 与 DESIGN §2：机器人输出经 `publicBotEvent`/手动 `{...game, questionIndex:1, version+1}` 突变直接入事件流，未过 schema/阶段校验。
标尺：`grep -rn "publicBotEvent" application/ domain/` 为空或机器人动作改经 domain 校验入口；新增错误阶段注入被拒单测。证据缺口：当前为静态可信字符串，风险潜伏至 M3。fixer=switch:agent::gpt-5.6-terra

[P2] **SEED-COLLISION** — `app/api/games/route.ts` 用 `Date.now() >>> 0` 作 seed：同毫秒两次 POST 或 2^32ms 回绕后 id 相同，静默覆盖。标尺：同毫秒两次 POST 返回不同 id。fixer=same

[P2] **NO-RECENT-GAMES-UI** — 最近十局只有 `GET /api/games` 端点，页面无历史列表/对局入口；README「重新加载后仍可取回对局」与 UI 事实不符。标尺：重载后可见历史战绩并可查看。fixer=same

[P2] **GITIGNORE-ENV-REGRESSION** — 新 .gitignore 删除 `.env*`（及 dist/coverage/*.db）忽略，模板仓库密钥提交风险回归。标尺：`git check-ignore .env.local` 命中。fixer=same

[P2] **TEST-GAPS** — 非法阶段（describe@questioning、answer@questionIndex=0、vote 提前）、p2 视角 view 隔离、手机宽度完整一局均无覆盖。标尺：新增表驱动用例通过 + 手机 e2e 完成整局。fixer=same

[DEFER] SQLite 迁移与 M3 模型适配器（JSON repo 为 issue 允许的 M1 替代）；`stored.keys` 无界增长与鉴权；domain `question`/`answer` 硬编码 p1（M1 单真人成立）。

## Scope summary

| 级别 | 数量 | 本轮是否实施 |
|---|---|---|
| P0 | 0 | 是 |
| P1 | 2 | 是 |
| P2 | 4 | 否（记录） |
| DEFER | 3 | 否（backlog） |

## Verdict

**NEED-FIX** — 未关 P1：BOT-VOTE-BIAS、BOT-EVENT-VALIDATION。不关闭 Issue、不建议合并。
