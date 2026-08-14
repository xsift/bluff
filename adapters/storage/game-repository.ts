import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { Game, PlayerView } from "../../domain/game";

export type StoredGame = { game: Game; keys: Record<string, PlayerView> };
export interface GameRepository { get(id: string): StoredGame | undefined; save(record: StoredGame): void; recent(): Game[]; clear(): void; }
const file = join(process.cwd(), ".bluff-data", "games.json");
export class JsonGameRepository implements GameRepository {
  private records = new Map<string, StoredGame>();
  constructor() { try { for (const value of JSON.parse(readFileSync(file, "utf8")) as StoredGame[]) this.records.set(value.game.id, value); } catch { /* First run has no data file. */ } }
  get(id: string) { return this.records.get(id); }
  save(record: StoredGame) { this.records.set(record.game.id, record); mkdirSync(join(process.cwd(), ".bluff-data"), { recursive: true }); writeFileSync(file, JSON.stringify([...this.records.values()])); }
  recent() { return [...this.records.values()].map(x => x.game).filter(x => x.phase === "revealed").slice(-10).reverse(); }
  clear() { this.records.clear(); }
}
