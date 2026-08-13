# WBS — Bot or Bluff

## M1：可玩文字闭环

- Next.js/TypeScript 工程与一键开发命令
- 领域状态机、身份分配、词对、合法动作与胜负
- 规则机器人与独立席位上下文
- 竞技场 UI：创建、描述、质疑、投票、揭晓
- SQLite 最近十局
- 单元、集成和移动端 E2E

验收：无 API Key 从首页完整玩完一局；非法迁移/越权信息均被拒绝。

## M2：Sift 样板体验

- 精简上下文工程文档
- GitHub Template Repository
- `scripts/bootstrap.sh` 检查 gh、认证和仓库归属
- 幂等创建 labels 与 `.github/sift-tasks/` seed Issues
- README：Use this template→bootstrap→sift init→运行任务

验收：新仓库可按 README 在十分钟内开始首个 Sift Issue。

## M3：可选真实模型

- OpenAI-compatible adapter
- 超时、预算、重试和规则降级
- 配置页和调用诊断

## M4：语音模式

- STT 输入 adapter
- TTS 角色声音和字幕
- 打断、静音、失败回退与无障碍
- 评估多人实时房间
