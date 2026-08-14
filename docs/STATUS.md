# STATUS

- 当前阶段：M1 已实现，M2 初始化
- 已完成：无 API Key 规则机器人文字对局、服务端状态机与持久化、领域/API/E2E 测试；仓库已启用 GitHub Template Repository 属性
- 下一步：完成 #2 bootstrap 脚本和 seed Issues
- 未开始：真实模型适配、语音模式

## Backlog（DEFER，本地单人启动流程不阻塞）

来源：issue #7 review round1 记录，持续有效（issue #13 未实施）：

- **SQLite 持久化**：将 JSON 文件持久化替换为仓库端口后的 SQLite，供部署使用
- **幂等键上界 + 鉴权**：限制幂等 key 增长，公开/多人暴露前补充鉴权
- **p1 泛化**：移除硬编码 `p1` 假设，支持泛化席位/多人
