import type { ReactNode } from "react";
import Link from "next/link";

export default function PublicLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <div className="public-site" dir="rtl" lang="ar">
      <header className="public-header">
        <Link href="/" className="public-brand" aria-label="BeVo الرئيسية">
          <span className="public-brand-mark">B</span>
          <span><strong>BeVo</strong><small>البوابة الأكاديمية</small></span>
        </Link>
        <nav className="public-nav" aria-label="التنقل الرئيسي">
          <Link href="/guides">الأدلة الدراسية</Link>
          <Link href="/about">عن BeVo</Link>
          <Link href="/contact">تواصل معنا</Link>
          <Link href="/" className="public-login-link">دخول المنصة</Link>
        </nav>
      </header>
      <main className="public-main">{children}</main>
      <footer className="public-footer">
        <div>
          <strong>BeVo</strong>
          <p>مساحة أكاديمية لتنظيم الدراسة والمواد والمهام في مكان واحد.</p>
        </div>
        <nav aria-label="روابط قانونية">
          <Link href="/about">عن المنصة</Link>
          <Link href="/privacy">سياسة الخصوصية</Link>
          <Link href="/terms">الشروط والأحكام</Link>
          <Link href="/contact">اتصل بنا</Link>
        </nav>
        <small>© {new Date().getFullYear()} BeVo. جميع الحقوق محفوظة.</small>
      </footer>
    </div>
  );
}
