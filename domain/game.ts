export type Phase = "lobby" | "describing" | "questioning" | "voting" | "revealed";
export type Role = "civilian" | "spy";
export type Controller = "human" | "rule";
export type EventKind = "system" | "describe" | "question" | "answer" | "vote";

export type Player = { id: string; displayName: string; controller: Controller; role: Role };
export type Event = { id: number; kind: EventKind; actorId?: string; text: string };
export type Game = {
  id: string; version: number; seed: number; phase: Phase; players: Player[];
  civilianWord: string; spyWord: string; category: string; events: Event[];
  descriptionIndex: number; questionIndex: number; votes: Record<string, string>;
  outcome?: { winner: Role; eliminatedId?: string; reason: string };
};

const pairs = [
  ["咖啡", "茶", "饮品"], ["图书馆", "书店", "地点"], ["吉他", "小提琴", "乐器"],
  ["自行车", "摩托车", "交通"], ["电影", "电视剧", "娱乐"], ["猫", "狗", "动物"]
] as const;
const names = ["你", "阿澄（规则机器人）", "小墨（规则机器人）", "北北（规则机器人）"];
const next = (seed: number) => (Math.imul(seed, 1664525) + 1013904223) >>> 0;
const add = (game: Game, kind: EventKind, text: string, actorId?: string) => ({ ...game, events: [...game.events, { id: game.events.length + 1, kind, text, actorId }] });
export const wordFor = (game: Game, player: Player) => player.role === "spy" ? game.spyWord : game.civilianWord;

export function createGame(seed = 1, id = `game-${seed}`): Game {
  const pair = pairs[seed % pairs.length];
  const spyIndex = next(seed) % 4;
  const players = names.map((displayName, index) => ({ id: `p${index + 1}`, displayName, controller: index === 0 ? "human" as const : "rule" as const, role: index === spyIndex ? "spy" as const : "civilian" as const }));
  return { id, version: 0, seed, phase: "lobby", players, civilianWord: pair[0], spyWord: pair[1], category: pair[2], events: [], descriptionIndex: 0, questionIndex: 0, votes: {} };
}

export function start(game: Game): Game { return add({ ...game, phase: "describing", version: game.version + 1 }, "system", "对局开始：先依次描述，再进行三次质疑与投票。"); }
function player(game: Game, id: string) { const found = game.players.find(p => p.id === id); if (!found) throw new Error("未知席位"); return found; }
function assertText(text: string) { if (!text.trim() || text.length > 120) throw new Error("请输入 1 到 120 个字符"); }
function assertCurrent(game: Game, actorId: string) { if (game.players[game.descriptionIndex]?.id !== actorId) throw new Error("现在不是该席位的描述回合"); }
export function describe(game: Game, actorId: string, text: string): Game {
  if (game.phase !== "describing") throw new Error("当前不是描述阶段"); assertCurrent(game, actorId); assertText(text);
  if (text.toLocaleLowerCase().includes(wordFor(game, player(game, actorId)).toLocaleLowerCase())) throw new Error("描述不能直接说出秘密词");
  const descriptionIndex = game.descriptionIndex + 1;
  let result = add({ ...game, descriptionIndex, version: game.version + 1 }, "describe", text, actorId);
  if (descriptionIndex === 4) result = add({ ...result, phase: "questioning", version: result.version + 1 }, "system", "描述结束：完成三次质疑后进入投票。");
  return result;
}
export function question(game: Game, actorId: string, targetId: string, text: string): Game {
  if (game.phase !== "questioning" || game.questionIndex !== 0 || actorId !== "p1") throw new Error("现在不能提问");
  if (targetId === actorId || !game.players.some(p => p.id === targetId)) throw new Error("请选择其他席位"); assertText(text);
  return add({ ...game, version: game.version + 1 }, "question", text, actorId);
}
export function answer(game: Game, actorId: string, text: string): Game {
  if (game.phase !== "questioning" || game.questionIndex < 1 || actorId !== "p1") throw new Error("现在不能回答"); assertText(text);
  const questionIndex = game.questionIndex + 1;
  let result = add({ ...game, questionIndex, version: game.version + 1 }, "answer", text, actorId);
  if (questionIndex === 3) result = add({ ...result, phase: "voting", version: result.version + 1 }, "system", "质疑结束：请选择你认为的卧底。");
  return result;
}
export function vote(game: Game, actorId: string, targetId: string): Game {
  if (game.phase !== "voting") throw new Error("当前不是投票阶段"); if (actorId === targetId || !game.players.some(p => p.id === targetId)) throw new Error("投票目标必须是其他席位");
  if (game.votes[actorId]) throw new Error("该席位已投票");
  return add({ ...game, votes: { ...game.votes, [actorId]: targetId }, version: game.version + 1 }, "vote", `${player(game, actorId).displayName} 已投票。`, actorId);
}
export function reveal(game: Game): Game {
  if (game.phase !== "voting" || Object.keys(game.votes).length !== 4) throw new Error("尚未收齐投票");
  const totals: Record<string, number> = {}; Object.values(game.votes).forEach(id => { totals[id] = (totals[id] ?? 0) + 1; });
  const max = Math.max(...Object.values(totals)); const leaders = Object.keys(totals).filter(id => totals[id] === max);
  const eliminatedId = leaders.length === 1 ? leaders[0] : undefined;
  const winner: Role = eliminatedId && player(game, eliminatedId).role === "spy" ? "civilian" : "spy";
  const reason = eliminatedId ? `${player(game, eliminatedId).displayName} 被票出` : "投票平局，无人出局";
  return add({ ...game, phase: "revealed", version: game.version + 1, outcome: { winner, eliminatedId, reason } }, "system", `${reason}。${winner === "civilian" ? "平民阵营获胜！" : "卧底获胜！"}`);
}

export type BotAction =
  | { kind: "describe"; actorId: string; text: string }
  | { kind: "question"; actorId: string; text: string }
  | { kind: "answer"; actorId: string; text: string }
  | { kind: "vote"; actorId: string; targetId: string };

function assertBot(game: Game, actorId: string) {
  if (player(game, actorId).controller !== "rule") throw new Error("只有规则机器人可以执行该动作");
}

export function botAction(game: Game, action: BotAction): Game {
  assertBot(game, action.actorId);
  if (action.kind === "describe") return describe(game, action.actorId, action.text);
  if (action.kind === "question") {
    if (game.phase !== "questioning" || game.questionIndex < 1 || game.questionIndex > 2) throw new Error("当前不能提问");
    assertText(action.text);
    return add({ ...game, version: game.version + 1 }, "question", action.text, action.actorId);
  }
  if (action.kind === "answer") {
    if (game.phase !== "questioning" || game.questionIndex !== 0 || game.events.at(-1)?.kind !== "question") throw new Error("当前不能回答");
    assertText(action.text);
    return add({ ...game, questionIndex: 1, version: game.version + 1 }, "answer", action.text, action.actorId);
  }
  return vote(game, action.actorId, action.targetId);
}

export type PlayerView = { id: string; version: number; phase: Phase; category: string; players: Pick<Player, "id" | "displayName" | "controller">[]; events: Event[]; secret?: { role: Role; word: string }; outcome?: Game["outcome"]; revealedPlayers?: Pick<Player, "id" | "displayName" | "role">[] };
export function viewFor(game: Game, viewerId: string): PlayerView {
  const viewer = player(game, viewerId);
  return { id: game.id, version: game.version, phase: game.phase, category: game.category, players: game.players.map(({ id, displayName, controller }) => ({ id, displayName, controller })), events: game.events, ...(game.phase === "revealed" ? { outcome: game.outcome, revealedPlayers: game.players.map(({ id, displayName, role }) => ({ id, displayName, role })) } : { secret: { role: viewer.role, word: wordFor(game, viewer) } }) };
}
