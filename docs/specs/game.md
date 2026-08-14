# Game 规格

## 领域对象

- `Game`：id、version、seed、phase、round、players、events、createdAt
- `Player`：id、displayName、controller(`human|rule|model`)、role(`civilian|spy`)
- `WordPair`：civilianWord、spyWord、category
- `AgentAction`：`describe|question|answer|vote|pass` + 合法目标和公开文本

## 不变量

1. 一局恰有四席：一名真人、三个机器人；恰有一个卧底。
2. 席位只能读取自己的角色和秘密词。
3. 已提交动作不可修改；重复 commandKey 返回原结果。
4. 投票目标必须是其他活跃席位；最高票唯一时该席位出局，平票无人出局且卧底获胜；不由模型决定。
5. `revealed` 前 API 不返回答案、角色或随机种子。
6. 机器人输出必须通过 schema 和阶段合法性检查。
