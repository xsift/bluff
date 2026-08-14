import { afterEach, expect, it } from "vitest";
import { createGame } from "../domain/game";
import { newGame, resetForTests, setGameIdentitySourceForTests, submit } from "./game-service";
afterEach(resetForTests);
it("uses distinct strong identities for same-millisecond creations", () => {
  let id = 0;
  setGameIdentitySourceForTests({ nextId: () => `test-id-${++id}`, nextSeed: () => 123 });
  const first = newGame();
  const second = newGame();
  expect(first.id).not.toBe(second.id);
  expect(first.category).toBe(second.category);
});

it("returns the same result for a duplicate command key", () => { const game = newGame(8); const command = { key: "same", version: game.version, action: "describe" as const, text: "它有独特的使用场景" }; expect(submit(game.id, command)).toEqual(submit(game.id, command)); });
it("rejects stale versions", () => { const game = newGame(9); submit(game.id, { key: "first", version: game.version, action: "describe", text: "这是一个提示" }); expect(() => submit(game.id, { key: "later", version: game.version, action: "describe", text: "第二次" })).toThrow("已更新"); });

function reachVoting(seed: number) {
  let game = newGame(seed);
  game = submit(game.id, { key: `${seed}-describe`, version: game.version, action: "describe", text: "这是一个公开提示" });
  game = submit(game.id, { key: `${seed}-question`, version: game.version, action: "question", targetId: "p2", text: "你会在日常生活中接触它吗？" });
  game = submit(game.id, { key: `${seed}-answer1`, version: game.version, action: "answer", text: "我会偶尔接触它" });
  return submit(game.id, { key: `${seed}-answer2`, version: game.version, action: "answer", text: "它很常见" });
}

it("lets a human vote change the result for every spy seat", () => {
  const seedsBySpy = new Map<number, number>();
  for (let seed = 1; seedsBySpy.size < 3; seed += 1) {
    const spyIndex = createGame(seed).players.findIndex(p => p.role === "spy");
    if (spyIndex > 0) seedsBySpy.set(spyIndex, seed);
  }
  for (const seed of seedsBySpy.values()) {
    const spyId = createGame(seed).players.find(p => p.role === "spy")!.id;
    const civilian = reachVoting(seed);
    const won = submit(civilian.id, { key: `${seed}-spy`, version: civilian.version, action: "vote", targetId: spyId });
    expect(won.outcome?.winner).toBe("civilian");
    resetForTests();
    const nonSpyId = createGame(seed).players.find(p => p.id !== "p1" && p.id !== spyId)!.id;
    const civilianVote = reachVoting(seed);
    const lost = submit(civilianVote.id, { key: `${seed}-civilian`, version: civilianVote.version, action: "vote", targetId: nonSpyId });
    expect(lost.outcome?.winner).toBe("spy");
    resetForTests();
  }
});
