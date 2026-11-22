# BeVo — AdSense Readiness Checklist

This document describes the configuration required before requesting Google AdSense review.
It does not imply that Google has approved BeVo or that ads are currently being served.

## Current implementation

- Public pages: `/about`, `/privacy`, `/terms`, `/contact`, and `/guides`.
- Original public study guides are available without signing in.
- Public links are included in the sign-in screen and initial HTML boot shell.
- Search discovery files: `/robots.txt` and `/sitemap.xml`.
- AdSense ad slots are rendered only on public guide pages.
- No AdSense script or ad slot is loaded until both public ad environment variables are configured.
- The authenticated student workspace, tasks, registration and administration screens have no ad slots.
- `/ads.txt` is generated from the server-side `ADSENSE_PUBLISHER_ID` environment variable. It returns 404 until a valid ID is configured.

## Required before applying

1. **Use a domain you own.** The current `bevo-tasker.vercel.app` hostname is a Vercel subdomain. Google’s URL guidance asks for a standard domain for ordinary sites and only allows subdomains for certain host-partner services. Attach a custom domain to the existing Vercel project and use it as the canonical URL.
2. **Set a real support address.** Configure `NEXT_PUBLIC_SUPPORT_EMAIL` to an inbox that is actively monitored. The Contact page currently warns visitors that the address has not yet been configured.
3. **Review the legal pages.** The privacy policy and terms are practical drafts, not legal advice. Confirm the actual data-controller/operator identity, contact channel, retention practices, user-rights process, applicable legal jurisdiction and any third-party tools before publishing them as final policies.
4. **Review public content.** Keep the public guides accurate, useful and original. Add further editorial content only when it provides real value; do not create thin or repetitive pages merely to increase page count.
5. **Check site quality.** Test the public routes on desktop and mobile, confirm navigation is clear, fix broken links, and ensure public pages do not require login.
6. **Confirm eligibility.** The AdSense account holder must be at least 18. If the owner is under 18, a parent or guardian must own the AdSense account and receive its payments.
7. **Avoid invalid traffic.** Never click your own live ads, ask others to click, buy traffic or use automated impressions/clicks. Do not position ads close to navigation, task controls, downloads or buttons.
8. **Plan consent.** If serving personalized ads to users in the EEA, UK or Switzerland, use a Google-certified CMP integrated with the IAB TCF as required by Google's publisher consent policy. Review the applicable privacy laws for all countries where BeVo has users.

## Create the AdSense account

1. Sign in to the Google Account that should own the publisher account.
2. Open https://adsense.google.com/start/.
3. Select **Get started**.
4. Enter the custom domain (not a page URL or a Vercel preview URL).
5. Select Egypt as the payment country only if it is the country where the account holder lives and can receive the AdSense PIN by mail. The payment country cannot be changed later.
6. Enter the account and payment details exactly as required by Google and the payment provider.
7. Accept the AdSense terms and complete the account setup steps.
8. Add the custom domain under **Sites**, choose the meta-tag verification method (the app will publish the required `google-adsense-account` meta tag after the client ID is configured), and follow the remaining review instructions displayed by AdSense.

Google site review may take a few days and in some cases 2–4 weeks. Approval is not guaranteed.

## Configure Vercel environment variables after AdSense provides IDs

Set these in the existing Vercel project for Production (and Preview only if you want to test the integration):

| Variable | Value |
|---|---|
| `NEXT_PUBLIC_SITE_URL` | Your verified custom domain, e.g. `https://your-domain.com` |
| `NEXT_PUBLIC_SUPPORT_EMAIL` | The official monitored BeVo support address |
| `NEXT_PUBLIC_ADSENSE_CLIENT_ID` | The exact `ca-pub-...` client ID from AdSense |
| `NEXT_PUBLIC_ADSENSE_GUIDES_SLOT_ID` | The ad unit slot ID created for public guides |
| `ADSENSE_PUBLISHER_ID` | The publisher ID portion in `pub-...` format, without `ca-` |

Do not invent or reuse another publisher's IDs. Do not place bank details, passwords or Google OAuth secrets in `NEXT_PUBLIC_*` variables.

After setting the IDs, redeploy. The `NEXT_PUBLIC_ADSENSE_CLIENT_ID` also creates the `google-adsense-account` meta tag in the document head, which can be used as the site's AdSense ownership verification method. Verify:

- The ad script appears only on public guide pages.
- No ad slots appear in login, student workspace, task, course registration or admin screens.
- `https://your-domain.com/ads.txt` returns exactly:
  `google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0`
  with your own publisher ID substituted.
- The AdSense Sites page recognizes the file and displays the expected status.
- Request review from AdSense after completing the account and site connection steps.

## Do not do these things

- Do not click your own ads or test by clicking live ads.
- Do not tell students to click ads to support BeVo.
- Do not place ads near buttons, navigation menus, downloads or task controls.
- Do not expose student IDs, academic selections, grades or account data to advertisers.
- Do not use a fake contact email, fake domain ownership details or placeholder publisher ID when applying.

## Official Google references

- Create an account: https://support.google.com/adsense/answer/7402253
- Eligibility: https://support.google.com/adsense/answer/9724
- Site readiness: https://support.google.com/adsense/answer/7299563
- Site ownership: https://support.google.com/adsense/answer/91205
- Connect and review a site: https://support.google.com/adsense/answer/7584263
- Required privacy disclosures: https://support.google.com/adsense/answer/1348695
- ads.txt: https://support.google.com/adsense/answer/12171612
- Invalid traffic: https://support.google.com/adsense/answer/16737
- EEA/UK/Switzerland consent requirements: https://support.google.com/adsense/answer/13554116
