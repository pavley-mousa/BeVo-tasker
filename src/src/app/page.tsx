"use client";

import { useEffect, useState } from "react";
import BeVoApp from "@/components/BeVoApp";

export default function HomePage() {
  const [ready, setReady] = useState(false);

  useEffect(() => setReady(true), []);

  if (!ready) {
    return (
      <main className="boot-screen" dir="rtl" lang="ar">
        <div className="boot-mark">B</div>
        <div className="boot-spinner" />
        <strong>جاري تجهيز BeVo…</strong>
        <span>المنصة الأكاديمية</span>
        <nav className="boot-public-links" aria-label="روابط BeVo العامة">
          <a href="/guides">الأدلة الدراسية</a>
          <a href="/about">عن BeVo</a>
          <a href="/privacy">الخصوصية</a>
          <a href="/terms">الشروط</a>
          <a href="/contact">تواصل معنا</a>
        </nav>
      </main>
    );
  }

  return <BeVoApp />;
}
