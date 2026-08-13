# Bluff

> **Talk. Lie. Vote.** 和一桌 AI 聊天、撒谎、推理。

**Bluff** 是一个 AI 原生社交推理游戏平台，也是 [Sift](https://github.com/miaoxiaoyong/sift) 的入门样板项目。首个游戏模式 **Bot or Bluff** 中，真人与三个虚构 AI 角色同桌，在三分钟的间谍猜词局里找出隐藏的卧底；程序负责规则与裁判，模型只负责发言、判断和投票。

当前处于 MVP 建设阶段。默认规则机器人无需 API Key；后续可接 OpenAI-compatible/Ollama 模型，并扩展语音输入与角色语音。

## 为什么这是 Sift 样板

仓库按人和 AI 共同可读的上下文工程组织：

- `docs/PRD.md`：产品需求与边界
- `docs/DESIGN.md`：系统设计与关键理由
- `docs/WBS.md`：工作分解与验收标准
- `docs/STATUS.md`：当前进度
- `AGENTS.md`：Agent 导航与上下文加载规则
- `.github/sift-tasks/`：可导入的入门任务

完成初始版本后，本仓库将设置为 GitHub Template Repository。使用者通过 **Use this template** 创建自己的独立仓库，再运行引导脚本创建任务并接入 Sift。
