# Review — Issue #9 · round 1（完整关闭包）

> 基线副本。同内容已发 Issue 评论。复审（round 2）只输出 DELTA，禁止全文克隆。

- 审核对象：`feat/issue-9-harden-template-onboarding-after-bootstrap-mvp` @ fd59a0c（origin tip，尚无 MR）
- 独立取证：`gh issue view 9`（6 项 + DEFER）；本地实跑 `pnpm install --frozen-lockfile`（lock 在同步）、`pnpm test`（9 pass）、`pnpm test:bootstrap`（pass）、`pnpm build`（pass）、`pnpm e2e`（2 pass）；`sift --help`（v0.5.4）交叉核对 CLI 命令面；`ci.yml` YAML 解析通过；未修改生产代码（diff 仅 `.github/` README/ package.json/ scripts/）
- 历史关闭包：无（Issue 无评论、`docs/reviews/` 无 issue-9 记录）→ 完整关闭包

## Issue 6 项验收对照

| # | 验收项 | 状态 | 证据 |
|---|---|---|---|
| 1 | README trust bullets（隔离 worktree / 单一 Coordinator） | PASS | README「接入 Sift」两条 bullet，语义与验收一致 |
| 2 | 难度三档 beginner/intermediate/advanced | PASS | 6 个 task frontmatter 均含 `difficulty:`；bootstrap.sh 校验取值；README 表格与文件一致 |
| 3 | 移除 `tests`/`playwright` 别名 | PASS | package.json 已删；全库 grep 无 `pnpm tests`/`pnpm playwright` 残留 |
| 4 | CLI 清单补 `sift rm <run-id>` | PASS | README 控制/内部含 `rm <run-id>`；sift 0.5.4 `--help` 实锤存在（归档语义一致） |
| 5 | bootstrap.test.sh 挂入 package scripts + CI | PASS | `test:bootstrap` + CI `pnpm test:bootstrap` 步骤；本地通过 |
| 6 | 稳定 marker/readback 去重 + 立即重跑测试 | PASS | body 首行 `<!-- bluff-sift-seed:NN-slug -->`；`gh api` 列表（非搜索）计数，>1 fail-closed；create 后 `gh issue view` readback 校验；测试含改名标题重跑零新增、失败恢复 |

DEFER（Issue 自带，如实记录不实施）：真实 Template→bootstrap→sift init→摄入→Agent→PR→人工审批全链路实跑并归档证据，禁止虚构。

## Finding 列表

[P2] **STATUS-STALE** — `docs/STATUS.md` 未随本轮更新：「M2 初始化」「下一步：完成 #2 bootstrap 脚本和 seed Issues」，与现状（#2 已合并、#9 硬化待合入）不符；STATUS 是状态唯一权威源。
标尺：`grep -n "M2" docs/STATUS.md` 不再出现「M2 初始化」且「下一步」指向 #9 之后的下一项。YES/NO
证据缺口：无（静态可证）。
fixer=same

[P2] **DEDUPE-LEGACY** — 去重只识别带 marker 的 Issue；旧版（#2 发布形态）bootstrap 创建的 seed Issues 无 marker，老 fork 升级模板重跑会重复创建（无 title 回退与 marker 迁移）。当前无真实模板用户（DEFER 亦证实无实跑），故非 P1。
标尺：对含旧版无 marker seed Issue 的仓库重跑 bootstrap 零新增；或实现 title 回退 + 迁移写回 marker（mock fixture 验证）。YES/NO
证据缺口：无旧版仓库可实跑，需构造 fixture。
fixer=same

[P2] **MARKER-FRAGILITY** — marker 由文件名派生（`${task##*/}` 去 .md）：重命名/重排 seed 文件即生成新 marker，旧 Issue 失去去重；任何 body 含该 marker 行（含引用粘贴）即判已存在（漏建方向，安全但可能跳过）。
标尺：README/脚本注释显式声明「勿重命名 seed 文件」，或改用独立稳定 frontmatter id；补重命名场景测试。YES/NO
证据缺口：无（静态可证）。
fixer=same

## Scope summary

| 级别 | 数量 | 本轮是否实施 |
|---|---|---|
| P0 | 0 | 是 |
| P1 | 0 | 是 |
| P2 | 3 | 否（记录） |
| DEFER | 1 | 否（backlog） |

## Verdict

**PASS** — P0/P1 全关（0/0）。可合并 `feat/issue-9-*` 并推进 Closes #9；DEFER 真实链路另开 Issue 跟踪。
