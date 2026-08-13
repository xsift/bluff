# 文档地图

文档同时服务人类和 AI 编码代理，遵循“单一事实来源、链接而不复制”。

| 文档 | 权威内容 |
|---|---|
| `PRD.md` | 用户场景、MVP、非目标、成功标准 |
| `DESIGN.md` | 架构、状态机、信任边界、语音演进 |
| `WBS.md` | 里程碑、任务切片、验收标准 |
| `STATUS.md` | 当前实施状态和下一步 |
| `specs/game.md` | 游戏规则和领域字段 |
| `testing/strategy.md` | 测试策略 |

## 默认上下文集

- 产品/UX：PRD + STATUS
- 实现：PRD + DESIGN + 对应 spec + WBS 当前切片
- 评审：上述实现集 + diff；先验证核心不变量
- 语音：DESIGN“语音演进” + game spec；不得改写核心规则
