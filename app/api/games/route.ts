import { newGame, recentGames } from "../../../application/game-service";
export const runtime = "nodejs";
export async function POST() { return Response.json(newGame()); }
export async function GET() { return Response.json(recentGames()); }
