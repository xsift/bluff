# 测试策略

- 领域表驱动测试：所有状态迁移、非法动作、平票、胜负和确定性 seed
- 信息隔离测试：每个席位 view 不含其他人的角色/词
- 适配器契约测试：规则与模型 adapter 返回可验证动作，超时会降级
- API 集成测试：幂等 commandKey、乐观版本、最近十局
- bootstrap 外壳测试：幂等创建、失败续跑、稳定 seed 身份（按 `id` 而非文件名去重）、旧无 marker Issue 的迁移/去重、重命名不重建 Issue、fail closed
- Playwright：桌面和手机宽度完整跑一局
- CI 不访问外部模型，不要求 API Key
