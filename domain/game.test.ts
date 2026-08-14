import { botAction, describe as describeAction, createGame, question, reveal, start, viewFor, vote } from "./game";
import { describe, expect, it } from "vitest";

it("is deterministic for a seed", () => { expect(createGame(42)).toMatchObject(createGame(42)); });
it("does not disclose other private information before reveal", () => { const game = start(createGame(2)); const view = viewFor(game, "p1"); expect(view).toHaveProperty("secret"); expect(JSON.stringify(view)).not.toContain("spyWord"); expect(JSON.stringify(view)).not.toContain("seed"); expect(view.players[1]).not.toHaveProperty("role"); });
it("rejects actions from illegal phases", () => {
  const game = createGame(1);
  expect(() => describeAction(game, "p1", "提示")).toThrow("描述阶段");
  expect(() => vote({ ...game, phase: "describing" }, "p1", "p2")).toThrow("投票阶段");
});

it("rejects direct-word descriptions and out-of-turn commands", () => { const game = start(createGame(1)); expect(() => describeAction(game, "p2", "提示")).toThrow("不是"); expect(() => describeAction(game, "p1", game.players[0].role === "spy" ? game.spyWord : game.civilianWord)).toThrow("秘密词"); });
it("requires another target and resolves a tied vote for the spy", () => { let game = start(createGame(1)); game = { ...game, phase: "voting" }; expect(() => vote(game, "p1", "p1")).toThrow("其他席位"); game = vote(game, "p1", "p2"); game = vote(game, "p2", "p1"); game = vote(game, "p3", "p2"); game = vote(game, "p4", "p1"); const result = reveal(game); expect(result.outcome).toMatchObject({ winner: "spy", reason: "投票平局，无人出局" }); });
it("only permits the human to open questioning", () => { const game = { ...start(createGame(1)), phase: "questioning" as const }; expect(() => question(game, "p2", "p1", "问题")).toThrow("不能提问"); });
it("rejects bot actions in the wrong phase", () => {
  const game = start(createGame(1));
  expect(() => botAction(game, { kind: "question", actorId: "p2", text: "问题" })).toThrow("当前不能提问");
  expect(() => botAction({ ...game, phase: "voting" }, { kind: "answer", actorId: "p2", text: "回答" })).toThrow("当前不能回答");
});
