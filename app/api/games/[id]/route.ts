import { getGame, submit } from "../../../../application/game-service";
export const runtime = "nodejs";
export async function GET(_: Request, { params }: { params: Promise<{ id: string }> }) { try { return Response.json(getGame((await params).id)); } catch (error) { return Response.json({ error: (error as Error).message }, { status: 404 }); } }
export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) { try { return Response.json(submit((await params).id, await request.json())); } catch (error) { return Response.json({ error: (error as Error).message }, { status: 400 }); } }
