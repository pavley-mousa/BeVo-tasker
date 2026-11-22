import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "تواصل مع BeVo",
  description: "قنوات التواصل والاستفسارات المتعلقة بمنصة BeVo الأكاديمية.",
};

export default function ContactPage() {
  const supportEmail = process.env.NEXT_PUBLIC_SUPPORT_EMAIL?.trim();

  return (
    <article className="public-article">
      <span className="public-eyebrow">نحن هنا للمساعدة</span>
      <h1>تواصل مع BeVo</h1>
      <p className="public-lead">
        للاستفسارات المتعلقة بالحساب أو البيانات الأكاديمية أو المشكلات التقنية،
        استخدم قناة التواصل الرسمية الموضحة أدناه.
      </p>
      {supportEmail ? (
        <section className="public-contact-card">
          <h2>بريد الدعم</h2>
          <a href={`mailto:${supportEmail}`}>{supportEmail}</a>
          <p>لا ترسل كلمة المرور أو رموز التحقق أو مستندات حساسة عبر البريد.</p>
        </section>
      ) : (
        <section className="public-note public-contact-card">
          <h2>بريد الدعم الرسمي لم يُحدد بعد</h2>
          <p>
            يجب ضبط المتغير NEXT_PUBLIC_SUPPORT_EMAIL في إعدادات النشر قبل تقديم
            BeVo إلى AdSense، حتى يجد الزائر وسيلة واضحة للتواصل مع مشغل المنصة.
          </p>
        </section>
      )}
      <h2>عند إرسال استفسار</h2>
      <ul>
        <li>اكتب نوع المشكلة والصفحة التي ظهرت فيها.</li>
        <li>أرفق وصفًا للخطوات التي أدت إلى المشكلة.</li>
        <li>لا ترسل كلمة المرور أو رمز OTP أو بيانات دخولك.</li>
      </ul>
    </article>
  );
}
