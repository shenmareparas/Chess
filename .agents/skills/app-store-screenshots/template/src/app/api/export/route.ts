import { promises as fs } from "node:fs";
import path from "node:path";
import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "Invalid JSON" }, { status: 400 });
  }

  const { images } = body as { images: Array<{ name: string; dataUrl: string }> };
  if (!images || !Array.isArray(images)) {
    return NextResponse.json({ ok: false, error: "Missing or invalid images list" }, { status: 400 });
  }

  try {
    const outputDir = path.join(process.cwd(), "../screenshots");
    await fs.mkdir(outputDir, { recursive: true });

    for (const img of images) {
      // Decode Base64 dataUrl
      const base64Data = img.dataUrl.replace(/^data:image\/\w+;base64,/, "");
      const buffer = Buffer.from(base64Data, "base64");
      const destPath = path.join(outputDir, img.name);
      await fs.writeFile(destPath, buffer);
    }

    return NextResponse.json({ ok: true, count: images.length });
  } catch (e) {
    return NextResponse.json(
      { ok: false, error: e instanceof Error ? e.message : String(e) },
      { status: 500 },
    );
  }
}
