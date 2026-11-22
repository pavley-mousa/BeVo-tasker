export function GET() {
  const publisherId = process.env.ADSENSE_PUBLISHER_ID?.trim();

  if (!publisherId || !/^pub-\\d{16}$/.test(publisherId)) {
    return new Response("AdSense publisher ID is not configured.\\n", {
      status: 404,
      headers: { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store" },
    });
  }

  return new Response(`google.com, ${publisherId}, DIRECT, f08c47fec0942fa0\\n`, {
    status: 200,
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "public, max-age=3600, s-maxage=3600",
    },
  });
}
