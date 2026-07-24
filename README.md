# הכלכלן של הבית — iOS

אפליקציית ה-iOS הנייטיבית: מעטפת WebView לטאב תיעוד ההוצאות + פעולת
"רישום הוצאה" (AppIntent) לאוטומציית הארנק + התראות מקומיות ממותגות.
תאומה של אפליקציית האנדרואיד (`mipuy-expense-tracker`).

- **אין Mac בצוות** — ה-`.xcodeproj` נוצר ב-CI מ-`project.yml` (XcodeGen).
  לעולם לא לערוך קובצי xcodeproj ידנית.
- **בנייה:** כל push ל-`main` → GitHub Actions (macOS) → חתימה (fastlane match) →
  TestFlight + GitHub Release. ראו `.github/workflows/release.yml`.
- **סודות נדרשים** (Repo secrets): `ASC_KEY_ID`, `ASC_ISSUER_ID`,
  `ASC_KEY_P8` (base64 של ה-.p8), `APPLE_TEAM_ID`, `MATCH_PASSWORD`,
  `MATCH_GIT_TOKEN` (PAT עם גישה ל-`mipuy-ios-certs` הפרטי).
- **חוזי שרת** (אין לשנות בלי תיאום עם הריפו הראשי):
  - `POST /api/transaction` `{token, merchant}` → `{ok, category, notify{title,body,text,warn}}`
  - דיפ-לינק `mipuytracker://token/<t>` מעמוד `/connect?native=1`
  - `GET /connect/expenses#token=<t>` — כניסה מלאה בתוך ה-WebView

תוכנית מלאה: ראו את תוכנית הפרויקט בריפו הראשי (docs/work-plan + זיכרון הסשן).
