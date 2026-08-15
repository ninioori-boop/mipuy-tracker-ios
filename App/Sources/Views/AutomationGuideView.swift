import SwiftUI

// The one thing Apple forces every user to do by hand, cut down to the shortest
// path that actually works on a device.
//
// The long version — build a Text action, set the Shortcut Input's type to
// «עסקה», pick «כמות», add a space, add a second variable, pick «בית עסק», then
// add our action underneath in that order — is real, was verified on a real
// charge, and is completely unreasonable to ask a client to perform. Those
// properties are only offered while editing inside an automation, so there is
// no way to shorten it by instruction alone.
//
// Importing the finished shortcut removes all of it. What is left is: get the
// shortcut, point an automation at it.
struct AutomationGuideView: View {
    private let steps: [(String, String)] = [
        ("1", "הקישו על הכפתור למטה והוסיפו את הקיצור «תיעוד הוצאה». זה מוסיף אותו למכשיר, אין מה לערוך בו"),
        ("2", "פתחו את «קיצורי דרך» (Shortcuts) — מותקנת בכל אייפון"),
        ("3", "בסרגל התחתון בחרו בלשונית «פעולות אוטומטיות» (האמצעית) והקישו על ＋"),
        ("4", "גללו ובחרו «ארנק» (Wallet), סמנו את הכרטיסים שלכם, ובחרו «הפעל מיד»"),
        ("5", "ברשימת הפעולות בחרו את «תיעוד הוצאה» — זה הקיצור שהוספתם בשלב 1"),
        ("6", "סיום! מהתשלום הבא כל הוצאה תירשם לבד עם התראה"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("הגדרה חד-פעמית של כדקה. אפל מחייבת שכל משתמש יגדיר את זה בעצמו במכשיר.")
                    .foregroundStyle(Brand.mutedText)

                Text("בלי הצעד הזה האפליקציה לא תרשום שום תשלום.")
                    .font(.footnote)
                    .foregroundStyle(Brand.gold)

                Button {
                    UIApplication.shared.open(Config.captureShortcutURL)
                } label: {
                    Text("① הוסף את הקיצור")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Brand.gold)
                        .foregroundStyle(Brand.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                ForEach(steps, id: \.0) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Text(step.0)
                            .font(.headline)
                            .foregroundStyle(Brand.surface)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Brand.gold))
                        Text(step.1)
                            .foregroundStyle(Brand.text)
                    }
                }

                Button {
                    if let url = URL(string: "shortcuts://") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("② פתח את קיצורי דרך")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Brand.surface2)
                        .foregroundStyle(Brand.text)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Brand.gold.opacity(0.4)))
                }
                .padding(.top, 8)

                Text("בקיצור עצמו אין מה לשנות. אם הוא נראה לכם ריק או מוזר בעריכה — זה תקין, "
                     + "הוא מתמלא ברגע התשלום.")
                    .font(.footnote)
                    .foregroundStyle(Brand.mutedText)
            }
            .padding(20)
        }
        .background(Brand.surface)
        .navigationTitle("קליטה אוטומטית")
        .navigationBarTitleDisplayMode(.inline)
    }
}
