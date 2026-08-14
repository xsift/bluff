# Bluff / Bot or Bluff

> **Talk. Lie. Vote.** 和一桌明确标识的虚构 AI 角色聊天、撒谎、推理。

Bluff 是一个零配置文字间谍猜词游戏，也是 [Sift](https://github.com/xsift/sift) 的安全入门样板：程序负责身份、流程和胜负；规则机器人不需要 API Key，模型不是必需的运行时依赖。

## 从模板到试玩

1. 在 [`xsift/bluff`](https://github.com/xsift/bluff) 点击 **Use this template**，创建属于自己的仓库。
2. clone 新仓库（不要 Fork，也不要在 `xsift/bluff` 上游运行脚本）：

   ```sh
   git clone https://github.com/YOUR-OWNER/YOUR-REPO.git
   cd YOUR-REPO
   ```

3. 安装并登录 GitHub CLI，然后运行一次安全、幂等的 bootstrap：

   ```sh
   gh auth status             # 未认证：gh auth login
   ./scripts/bootstrap.sh
   ```

   它会验证 `origin`、拒绝 `xsift/bluff`、确认当前账号对仓库有写权限，创建 `sift:run`/seed/priority labels，并从 `.github/sift-tasks/` 创建 seed Issues。中途失败后直接重跑即可；已完成的 labels/Issues 会被复用。
4. 本地试玩无需 Sift 或模型：

   ```sh
   pnpm install
   pnpm dev
   # 打开 http://localhost:3000，点击“开始一局”
   ```

## 接入 Sift

运行前先确认信任边界：

- 每个 Run 都应在独立 worktree 中工作，不要让 Agent 直接改共享 checkout。
- 每个仓库、每个触发标签同一时间只运行一个主动 Coordinator，避免并发重复摄入或互相覆盖。

Sift 当前 main 的 CLI 没有名为 `trigger`、`observe` 或 `approve` 的独立子命令，因此本样板不虚构这些命令：

```sh
sift init
sift doctor --offline
sift service install
sift service status
sift doctor
```

**触发**：给 seed Issue 添加 `sift:run` 标签（GitHub 上可用 `gh issue edit <number> --add-label sift:run`），由 Sift 摄入。**观察**：用 `sift ps`、`sift timeline`、`sift logs <run-id>`、`sift worktree <run-id>`、`sift status` 查看状态。**审批**：Sift 在 Issue/PR/MR 评论中给出带 Run ID 和一次性 nonce 的完整命令；只复制那条完整命令回复，不要手写或声称 `/sift approve` 是当前 CLI 命令。默认 `auto_merge: false`，Gate 通过也不等于自动合并。

当前 main 的命令面：

- 初始化/维护：`init`、`project add|list|remove`、`agent add|list|remove`、`daemon`、`doctor`、`install`、`update`、`service install|uninstall|start|stop|restart|reload|status`、`hooks-bootstrap`
- 查询：`ps`、`logs <run-id>`、`timeline`、`metrics`、`worktree <run-id>`、`attach <run-id>`、`status`
- 控制/内部：`kill <run-id>`、`retry <run-id>`、`rm <run-id>`、`report <kind>`（Agent 内部通道）
- 其他：`help`、`version`、`completion`

真实 Agent 全链路、人工门禁和 Forge 行为必须在你自己的仓库中小范围试跑并人工检查；本模板未声称已经完成这条真实链路。

失败恢复与清理：bootstrap 报错时先修复认证、远端或权限后重跑，它不会删除已创建的对象；若只想清理试跑，删除对应 seed Issues/labels，并停止服务或移除本机 Sift 项目（不要删除别人的仓库）。Sift 运行失败时使用 `sift ps`/`sift logs <run-id>`，检查后再 `sift kill <run-id>`，并按 Forge 权限手动处理已推送的分支/PR。

## Policy 对照 Sift main

`.sift/policy.yaml` 是 Sift main 的 v1 closed schema，只使用这些字段：

| 字段 | 作用/约束 |
|---|---|
| `version` | 必须为 `1` |
| `protected_paths.hard` | 项目追加的 hard path；每项为仓库相对 pattern |
| `protected_paths.soft` | 命中后进入 review 的 path |
| `protected_paths.soft_exceptions` | 仅取消 soft 命中，不能取消 hard |
| `review_policy` | `always`、`risky-only` 或 `never` |
| `risky_review_threshold` | `0..100` 的整数 |
| `auto_merge` | 请求自动合并；仍受认证和 Forge CAS 资格收窄，模板设为 `false` |
| `checks_pending_timeout` | `1m..24h` 的 Go duration，例如 `1h` |
| `flaky_retry_limit` | `0..10` 的整数 |

未知字段、`null`、错误类型、非法 pattern 和非法 duration 都应 fail closed。模板显式启用 `always` review、`auto_merge: false`，并将应用/领域代码列为 soft review 路径。

## Seed task inventory

这些是真实的 `.github/sift-tasks/*.md` 文件。priority 表示处理优先级，difficulty 表示实施难度；每项都可用现有测试、文档或规则机器人完成，不依赖付费 runtime model：

| Seed task | Priority | Difficulty |
|---|---:|---|
| `01-add-visible-mode-badge.md` | P2 | beginner |
| `02-cover-reset-flow.md` | P1 | intermediate |
| `03-document-game-actions.md` | P3 | beginner |
| `04-harden-api-input-test.md` | P1 | advanced |
| `05-improve-mobile-copy.md` | P2 | intermediate |
| `06-review-state-machine-docs.md` | P0 | advanced |

## Development

```sh
pnpm install
pnpm test
pnpm test:bootstrap
pnpm build
pnpm e2e
# 或：pnpm dev
```

`pnpm e2e` 需要可用的 Playwright 浏览器；测试不会访问真实模型或网络服务。对局记录保存在 `.bluff-data/games.json`。

更多边界见 `docs/PRD.md`、`docs/DESIGN.md`、`docs/WBS.md` 和 `AGENTS.md`。
