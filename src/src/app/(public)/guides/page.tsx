import type { Metadata } from "next";
import Link from "next/link";
import AdSenseSlot from "@/components/AdSenseSlot";

export const metadata: Metadata = {
  title: "الأدلة الدراسية",
  description: "أدلة عملية أصلية لتنظيم الفصل الدراسي والمهام وحماية الحسابات الرقمية للطلاب.",
};

const guides = [
  {
    href: "/guides/organizing-semester",
    number: "01",
    title: "كيف تبني خطة دراسية واقعية للفصل؟",
    description: "حوّل المواد والمحاضرات والتكليفات إلى خطة أسبوعية قابلة للتنفيذ والمراجعة.",
    read: "6 دقائق",
  },
  {
    href: "/guides/task-prioritization",
    number: "02",
    title: "طريقة عملية لترتيب المهام قبل موعد التسليم",
    description: "قسّم التكليفات الكبيرة وحدد الأولويات وتجنب تراكم العمل في آخر أسبوع.",
    read: "5 دقائق",
  },
  {
    href: "/guides/digital-security",
    number: "03",
    title: "حماية حسابك الجامعي وبياناتك الرقمية",
    description: "إرشادات لتأمين كلمات المرور ورموز التحقق وروابط تسجيل الدخول.",
    read: "5 دقائق",
  },
];

export default function GuidesPage() {
  return (
    <div className="public-page">
      <section className="public-hero">
        <span className="public-eyebrow">مكتبة BeVo المفتوحة</span>
        <h1>أدلة تساعدك تذاكر وتنظم دراستك بوعي</h1>
        <p>محتوى عملي للطلاب عن التخطيط الدراسي وإدارة المهام والأمان الرقمي. الأدلة متاحة للجميع دون تسجيل دخول.</p>
      </section>
      <div className="public-guide-grid">
        {guides.map((guide) => (
          <article className="public-guide-card" key={guide.href}>
            <span className="public-guide-number">{guide.number}</span>
            <h2><Link href={guide.href}>{guide.title}</Link></h2>
            <p>{guide.description}</p>
            <span className="public-muted">وقت القراءة: {guide.read}</span>
            <Link className="public-text-link" href={guide.href}>اقرأ الدليل ←</Link>
          </article>
        ))}
      </div>
      <AdSenseSlot />
      <section className="public-note">
        هذه الأدلة لأغراض تعليمية عامة. قد تحتاج إلى تعديل أسلوب التخطيط وفق نظام كليتك
        ومتطلبات مقرراتك ومواعيدك الرسمية.
      </section>
    </div>
  );
}
