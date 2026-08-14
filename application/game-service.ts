import { randomInt, randomUUID } from "node:crypto";
import { z } from "zod";
import { answer, botAction, createGame, describe, Game, question, reveal, start, viewFor, vote } from "../domain/game";
import { JsonGameRepository } from "../adapters/storage/game-repository";

const commandSchema = z.object({ key: z.string().min(1).max(100), version: z.number().int().nonnegative(), action: z.enum(["describe", "question", "answer", "vote"]), text: z.string().optional(), targetId: z.string().optional() });
type Command = z.infer<typeof commandSchema>;
type Stored = { game: Game; keys: Record<string, ReturnType<typeof viewFor>> };
const games = new JsonGameRepository();
export type GameIdentitySource = { nextId: () => string; nextSeed: () => number };
const defaultIdentitySource: GameIdentitySource = { nextId: randomUUID, nextSeed: () => randomInt(0, 0x1_0000_0000) };
let identitySource = defaultIdentitySource;
const botDescription = ["它常见，但不同场景会有不同感受。", "我会从用途和出现的地方来判断它。", "它很适合和熟悉的人分享体验。"];
function botId(index: number) { return `p${index + 2}`; }
function autoDescribe(game: Game) { while (game.phase === "describing" && game.descriptionIndex > 0 && game.descriptionIndex < 4) { const id = game.players[game.descriptionIndex].id; game = botAction(game, { kind: "describe", actorId: id, text: botDescription[game.descriptionIndex - 1] }); } return game; }
function botQuestion(game: Game, index: number) { return botAction(game, { kind: "question", actorId: botId(index), text: "你会在日常生活中主动接触它吗？" }); }
function botVoteTarget(game: Game, actorId: string) {
  const publicTarget = game.votes.p1;
  if (publicTarget && publicTarget !== actorId) return publicTarget;
  return game.players.find(p => p.id !== actorId)?.id ?? "p1";
}

export function newGame(seed?: number, id?: string): ReturnType<typeof viewFor> {
  const resolvedSeed = seed ?? identitySource.nextSeed();
  const resolvedId = id ?? identitySource.nextId();
  let game = start(createGame(resolvedSeed, resolvedId));
  games.save({ game, keys: {} });
  return viewFor(game, "p1");
}
export function getGame(id: string) { const stored = games.get(id); if (!stored) throw new Error("对局不存在"); return viewFor(stored.game, "p1"); }
export function submit(id: string, raw: unknown) {
  const command = commandSchema.parse(raw); const stored = games.get(id); if (!stored) throw new Error("对局不存在");
  if (stored.keys[command.key]) return stored.keys[command.key];
  if (command.version !== stored.game.version) throw new Error("对局已更新，请重试");
  let game = stored.game;
  if (command.action === "describe") game = autoDescribe(describe(game, "p1", command.text ?? ""));
  if (command.action === "question") {
    game = question(game, "p1", command.targetId ?? "", command.text ?? "");
    game = botAction(game, { kind: "answer", actorId: command.targetId!, text: "我会从它的使用方式来描述，不想说得太明显。" });
    game = botQuestion(game, 0);
  }
  if (command.action === "answer") {
    game = answer(game, "p1", command.text ?? "");
    if (game.phase === "questioning") game = botQuestion(game, 1);
  }
  if (command.action === "vote") {
    game = vote(game, "p1", command.targetId ?? "");
    for (const p of game.players.filter(p => p.controller === "rule")) game = botAction(game, { kind: "vote", actorId: p.id, targetId: botVoteTarget(game, p.id) });
    game = reveal(game);
  }
  stored.game = game; const result = viewFor(game, "p1"); stored.keys[command.key] = result; games.save(stored);
  return result;
}
export function recentGames() { return games.recent().map(game => ({ id: game.id, winner: game.outcome?.winner, reason: game.outcome?.reason })); }
export function setGameIdentitySourceForTests(source: GameIdentitySource) { identitySource = source; }
export function resetForTests() { games.clear(); identitySource = defaultIdentitySource; }
