import type { MetadataRoute } from "next";

const rawSiteUrl = process.env.NEXT_PUBLIC_SITE_URL || "https://bevo-tasker.vercel.app";
const siteUrl = rawSiteUrl.endsWith("/") ? rawSiteUrl.slice(0, -1) : rawSiteUrl;

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/reset-password"],
    },
    sitemap: `${siteUrl}/sitemap.xml`,
    host: siteUrl,
  };
}
