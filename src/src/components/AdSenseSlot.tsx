"use client";

import { useEffect, useRef, useState } from "react";
import Script from "next/script";

declare global {
  interface Window {
    adsbygoogle?: Array<Record<string, unknown>>;
  }
}

export default function AdSenseSlot() {
  const clientId = process.env.NEXT_PUBLIC_ADSENSE_CLIENT_ID;
  const slotId = process.env.NEXT_PUBLIC_ADSENSE_GUIDES_SLOT_ID;
  const [scriptLoaded, setScriptLoaded] = useState(false);
  const pushed = useRef(false);

  useEffect(() => {
    if (!clientId || !slotId || !scriptLoaded || pushed.current) return;
    try {
      window.adsbygoogle = window.adsbygoogle || [];
      window.adsbygoogle.push({});
      pushed.current = true;
    } catch {
      // Ad blockers or network restrictions can prevent ad initialization.
    }
  }, [clientId, slotId, scriptLoaded]);

  if (!clientId || !slotId) return null;

  return (
    <div className="public-ad-wrap" aria-label="مساحة إعلانية">
      <span className="public-ad-label">إعلان</span>
      <ins
        className="adsbygoogle public-ad-unit"
        style={{ display: "block", minHeight: 90 }}
        data-ad-client={clientId}
        data-ad-slot={slotId}
        data-ad-format="auto"
        data-full-width-responsive="true"
      />
      <Script
        id="bevo-adsense-loader"
        async
        strategy="afterInteractive"
        src={`https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${clientId}`}
        crossOrigin="anonymous"
        onLoad={() => setScriptLoaded(true)}
      />
    </div>
  );
}
