# Review — Issue #2 · round 1（完整关闭包）

> 基线副本。同内容已发 Issue 评论。复审（round 2）只输出 DELTA，禁止全文克隆。

- 审核对象：`feat/issue-2-make-bluff-a-safe-sift-template-with-seed-tasks` @ bdc696a（origin tip）
- 独立取证：`gh issue view 2` + issue comments；`xsift/sift`（public）`docs/specs/policy.md` 与 `cmd/sift/commands.go` 交叉核对；`scripts/bootstrap.test.sh` 通过（mock）；awk 与模拟真实 422 的 mock 复现 P0；未修改生产代码（diff 仅 scripts/ .sift/ README/ package.json/ .github/sift-tasks/）
- 已核对 PASS：policy.yaml 八字段全部符合 Sift v1 closed schema（旧 `gate.require_tests`/`require_human_approval` 已移除）；README 关于「CLI 无 trigger/observe/approve 子命令」经 commands.go 核实为真，未虚构命令面；seed 任务 6 个（≥5）、无付费模型依赖；bootstrap 五场景测试齐备

## Finding 列表

[P0] **LABEL-PARSE** — `scripts/bootstrap.sh` 用 `awk -F': *' '/^labels:/{print $2}'` 解析 task frontmatter，`labels: sift:run,sift:seed,priority:p2` 被截成 `sift`，真实 `gh issue create --label sift` 因未知 label 返回 422，seed Issue 一个都建不成；仓库自带 mock 不校验 `--label` 所以测试假绿。
标尺：真实/校验 mock 下 `bash scripts/bootstrap.sh` 在全新模板仓库必须成功创建带 `sift:run`/`priority:pX` 标签的 seed Issue（当前在第一个 task 报 `422 unknown label 'sift'`，EXIT=1）。
证据缺口：bootstrap.test.sh 的 mock gh 忽略 label 参数；无真实 GitHub 运行记录。
fixer=same

[P2] **SAFETY-POINTS-MISSING** — Issue 范围要求 README 明确「隔离 worktree」「一个仓库一个主动 Sift Coordinator」，全库 grep（README/docs）无任何一处出现。
标尺：`grep -n "Coordinator" README.md` 命中且含「隔离 worktree」表述。
fixer=same

[P2] **DIFFICULTY-TIERS** — Issue 要求 seed 任务「分入门/中等/高级」，实现仅按 priority label（P0–P3）分组，priority≠难度，README 无难度分级。
标尺：README 或 tasks 中显式出现入门/中等/高级三档。
fixer=same

[P2] **SCRIPT-ALIAS** — package.json 新增 `tests`/`playwright` 别名重复现有 `test`/`e2e`；README 写 `pnpm tests` 而 seed task 02 验收写 `pnpm test`，命令名不一致。
标尺：README 与 seed tasks 统一为 `pnpm test`（或删除别名）。
fixer=same

[P2] **CLI-INVENTORY-RM** — README「当前 main 的命令面」遗漏顶层命令 `rm <run-id>`（xsift/sift `cmd/sift/commands.go` 存在 rm）。
标尺：README 命令清单与 commands.go 顶层命令集合一致。
fixer=same

[P2] **BOOTSTRAP-TEST-NOT-WIRED** — bootstrap.test.sh 未挂入 package.json/CI（仓库无 CI，尚可接受但易腐烂）；且 mock 不校验 label 存在性（P0 掩盖面）。
标尺：`grep -n "bootstrap.test" package.json` 命中或 CI 显式运行该脚本；mock 增加 `--label` 校验。
fixer=same

[P2] **DEDUPE-SEARCH** — seed Issue 去重依赖 GitHub issue 搜索（`in:title` + `[Sift seed]` 方括号标题），搜索索引最终一致、特殊字符行为未验证，快速重跑可能重复创建。
标尺：真实模板仓库连续两次 `bootstrap.sh` 不产生重复 Issue。
fixer=same

[DEFER] **REAL-FULL-CHAIN** — Issue 验收「发布版 Sift init→摄入 seed Issue→真实 Agent→PR→人工审批」无实跑证据；实现已明确不声称，属人工门禁项，需真实环境小范围试跑。

## Scope summary

| 级别 | 数量 | 本轮是否实施 |
|---|---|---|
| P0 | 1 | 是 |
| P1 | 0 | 是 |
| P2 | 6 | 否（记录） |
| DEFER | 1 | 否（backlog） |

## Verdict

**NEED-FIX** — 未关 P0：LABEL-PARSE（seed Issue 创建在真实 GitHub 必败）。不关闭 Issue、不建议合并。
