# Bluff / Bot or Bluff

> **Talk. Lie. Vote.** 和一桌 AI 聊天、撒谎、推理。

零配置文字间谍猜词。你与三名明确标识的虚构规则机器人依次描述、质疑和投票。

**Bluff** 是一个 AI 原生社交推理游戏平台，也是 [Sift](https://github.com/xsift/sift) 的入门样板项目。首个游戏模式 **Bot or Bluff** 中，真人与三个虚构 AI 角色同桌，在三分钟的间谍猜词局里找出隐藏的卧底；程序负责规则与裁判，模型只负责发言、判断和投票。

```sh
pnpm install
pnpm dev
```

访问 `http://localhost:3000` 后点击“开始一局”。默认是规则机器人模式，不需要 API Key；程序在服务端裁决身份、轮次、合法动作和胜负。

```sh
pnpm test
pnpm build
pnpm exec playwright test
```

对局记录通过服务端 repository 持久保存在 `.bluff-data/games.json`，页面重新加载后仍可取回对局。该轻量实现是 M1 的 SQLite repository port 替代，避免要求本地原生 SQLite 编译环境。

## 为什么这是 Sift 样板

仓库按人和 AI 共同可读的上下文工程组织：

- `docs/PRD.md`：产品需求与边界
- `docs/DESIGN.md`：系统设计与关键理由
- `docs/WBS.md`：工作分解与验收标准
- `docs/STATUS.md`：当前进度
- `AGENTS.md`：Agent 导航与上下文加载规则

本仓库已设置为 GitHub Template Repository。#2 的 bootstrap 脚本和 seed Issues 尚未完成；在它们完成前，通过 **Use this template** 创建的仓库不能按完整 Sift 样板流程初始化。
