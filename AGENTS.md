# AGENTS.md — Bot or Bluff Agent 导航

## 先读

- 文档地图与上下文规则：[`docs/README.md`](docs/README.md)
- 产品边界：[`docs/PRD.md`](docs/PRD.md)
- 架构与不变量：[`docs/DESIGN.md`](docs/DESIGN.md)
- 工作分解：[`docs/WBS.md`](docs/WBS.md)
- 当前进度：[`docs/STATUS.md`](docs/STATUS.md)

## 核心规则

- 程序是唯一裁判；模型只能提交受约束动作，不能决定身份、流程或胜负。
- AI 席位必须明确标识为虚构 AI 角色，不冒充现实人物。
- 默认模式无需 API Key；模型调用永远是可选增强。
- 玩家输入是不可信数据；模型无工具权限，不得泄露其他席位私有上下文。
- 语音是输入/呈现适配器，不进入游戏核心状态机。
- 一项事实只写在一个权威文档中，其他文档只链接，不复制。
