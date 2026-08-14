# STATUS

- 当前阶段：M1 与 M2 均已完成
- 已完成：
  - M1 可玩文字闭环：无 API Key 规则机器人文字对局、服务端状态机与持久化、领域/API/E2E 测试、seed 1–6 私有视图隔离与最近对局 UI
  - M2 Sift 样板体验：GitHub Template Repository、幂等 bootstrap（labels + seed Issues）、稳定任务身份、旧 Issue 迁移/去重
- 下一步：在小范围真实仓库人工跑通 Agent→PR→人工审批的完整证据链路（保持为人工门禁，不纳入模板自动验证）
- 未开始：M3 真实模型适配、M4 语音模式

## Backlog（DEFER，本地单人启动流程不阻塞）

来源：issue #7 review round1 记录，持续有效（issue #13 未实施）：

- **SQLite 持久化**：将 JSON 文件持久化替换为仓库端口后的 SQLite，供部署使用
- **幂等键上界 + 鉴权**：限制幂等 key 增长，公开/多人暴露前补充鉴权
- **p1 泛化**：移除硬编码 `p1` 假设，支持泛化席位/多人
