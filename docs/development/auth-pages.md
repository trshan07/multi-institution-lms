# Authentication page designs

Four Next.js routes share the Aster auth layout and scoped styles:

| Route | Screen |
| --- | --- |
| `/login` | Email/password sign-in, password visibility, registration/recovery links |
| `/register` | Name, institution, email, new password and confirmation |
| `/forgot-password` | Email recovery request form and reset-page preview link |
| `/reset-password` | New password, confirmation and password guidance |

The split-screen design pairs a forest-green illustration panel with ivory forms. It adapts to a compact header and full-width fields on mobile. Fields have visible labels, autocomplete hints, associated errors, focus indicators, keyboard controls and inline feedback. New passwords require at least 12 characters in this frontend preview; the final identity provider will enforce the production policy.

These are **presentation-only forms**. Submissions validate the entered fields and explain that authentication/email delivery is not connected. No sign-in session, registration, password reset, email, or credential storage occurs. The reset route does not validate a real reset token. The demo workspace remains at `/` and is not protected by these pages.

Future integration must establish tenant-aware identity, server-side validation, rate limiting, secure sessions, generic recovery responses, and expiring single-use reset tokens. An institution name entered on registration must never itself grant membership or administrative access.

Verified: production build for all routes; Chrome desktop/mobile layouts at 320, 390, 768 and 1440px; empty-field and mismatch errors; password visibility; cross-page links; preview outcomes; no credential local/session storage or form POST requests. Test scripts/screenshots are development-only artifacts under ignored `.local/`.
