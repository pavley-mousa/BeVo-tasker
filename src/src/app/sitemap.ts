import type { MetadataRoute } from "next";

const rawSiteUrl = process.env.NEXT_PUBLIC_SITE_URL || "https://bevo-tasker.vercel.app";
const siteUrl = rawSiteUrl.endsWith("/") ? rawSiteUrl.slice(0, -1) : rawSiteUrl;

export default function sitemap(): MetadataRoute.Sitemap {
  const paths = [
    "",
    "/about",
    "/privacy",
    "/terms",
    "/contact",
    "/guides",
    "/guides/organizing-semester",
    "/guides/task-prioritization",
    "/guides/digital-security",
  ];

  return paths.map((path) => ({
    url: `${siteUrl}${path}`,
    lastModified: new Date("2026-11-22"),
    changeFrequency: path === "" ? "weekly" : "monthly",
    priority: path === "" ? 1 : path.startsWith("/guides") ? 0.8 : 0.5,
  }));
}
