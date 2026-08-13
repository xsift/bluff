import { afterEach, expect, it } from "vitest";
import { newGame, resetForTests, submit } from "./game-service";
afterEach(resetForTests);
it("returns the same result for a duplicate command key", () => { const game = newGame(8); const command = { key: "same", version: game.version, action: "describe" as const, text: "它有独特的使用场景" }; expect(submit(game.id, command)).toEqual(submit(game.id, command)); });
it("rejects stale versions", () => { const game = newGame(9); submit(game.id, { key: "first", version: game.version, action: "describe", text: "这是一个提示" }); expect(() => submit(game.id, { key: "later", version: game.version, action: "describe", text: "第二次" })).toThrow("已更新"); });
