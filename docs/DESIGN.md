# DESIGN — Bluff

## 1. 技术栈

Next.js + React + TypeScript；轻量 CSS；Zod；Vitest；Playwright。初期轮询或 SSE，只有多人/语音阶段再引入 WebSocket。对局持久化经 server-side repository port；M1 使用 JSON 文件实现，后续可替换为 Drizzle + SQLite。

## 2. 分层

- `domain/`：纯游戏状态机、规则、判分；不依赖 React、数据库或模型 SDK
- `application/`：命令处理、机器人调度、超时与降级
- `adapters/solvers/`：规则机器人和可选模型适配器
- `adapters/storage/`：SQLite 存储
- `app/`：Next.js 页面与 Route Handlers

程序生成并持有身份与答案。模型仅接收自己可见的上下文，并返回结构化动作；服务端以 Zod 验证合法性后才写入事件流。

## 3. 状态机

`lobby → describing → questioning → voting → revealed`

- `describing`：每个席位一次描述，禁止直接说出秘密词
- `questioning`：有限轮次的提问/回答/跳过
- `voting`：每个席位提交一个合法目标
- `revealed`：服务端计算结果并揭示角色

所有迁移由 `(gameVersion, commandKey)` 做乐观并发和幂等保护。

## 4. AI 边界

- 每个席位独立上下文，绝不共享其他人的私有身份/词
- 玩家文本作为引用数据放入 prompt，不视作系统指令
- 模型无工具、网络和数据库访问权
- 超时/无效输出使用规则机器人降级
- 只保存简短公开理由，不保存私有思维链

## 5. 默认机器人

规则机器人根据词条分类、人物风格和公开聊天生成模板化动作。它不假装是真模型；UI 标记“规则机器人模式”。其目的为零配置跑通玩法与测试。

## 6. 模型端口

`SolverAdapter.decide(view, signal) -> AgentAction`。模型供应商细节不得进入 domain。每次调用有超时、输出上限、token 预算和显式降级结果。

## 7. 语音演进

核心只识别标准动作和文本事件：

- `PlayerInputAdapter.capture(): Promise<TextSubmission>`
- `NarrationAdapter.render(event): Promise<void>`

STT 把语音转成现有文本命令；TTS 消费现有公开事件。失败时退回文字，不影响游戏状态。实时语音传输、回声消除和打断播放属于后续 adapter，不进入 domain。

## 8. 可测试性

状态机使用注入时钟、确定性随机种子和纯函数。端到端测试固定 seed；模型适配器用契约 fake，CI 不访问外部模型。
