export function GET() {
  const publisherId = process.env.ADSENSE_PUBLISHER_ID?.trim();
  const isValidPublisherId =
    typeof publisherId === "string" &&
    publisherId.startsWith("pub-") &&
    publisherId.length === 20 &&
    /^[0-9]+$/.test(publisherId.slice(4));

  if (!isValidPublisherId) {
    return new Response("AdSense publisher ID is not configured.\n", {
      status: 404,
      headers: { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store" },
    });
  }

  return new Response(`google.com, ${publisherId}, DIRECT, f08c47fec0942fa0\n`, {
    status: 200,
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "public, max-age=3600, s-maxage=3600",
    },
  });
}
