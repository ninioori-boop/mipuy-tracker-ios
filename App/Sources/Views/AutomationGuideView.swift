import SwiftUI

// Step-by-step Hebrew guide for the one thing Apple forces every user to do
// by hand: creating the Wallet automation that runs our capture action.
struct AutomationGuideView: View {
    private let steps: [(String, String)] = [
        ("1", "פתחו את אפליקציית «קיצורי דרך» (Shortcuts) — מותקנת בכל אייפון"),
        ("2", "בסרגל התחתון בחרו בלשונית «פעולות אוטומטיות» (האמצעית) והקישו על ＋"),
        ("3", "גללו ובחרו «ארנק» (בגרסאות ישנות: «עסקה»)"),
        ("4", "בחרו «כאשר אני מקיש», סמנו את הכרטיסים שלכם, ובחרו «הפעל מיד»"),
        ("5", "במסך בחירת הפעולה חפשו «רישום הוצאה» של הכלכלן של הבית ובחרו אותה"),
        ("6", "אם מופיע שדה «פרטי העסקה» ריק, הקישו עליו ובחרו את «קלט של קיצור»"),
        ("7", "סיום! מהתשלום הבא כל הוצאה תירשם לבד עם התראה"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("הגדרה חד-פעמית של כ-2 דקות. אפל מחייבת שכל משתמש יגדיר את זה בעצמו במכשיר.")
                    .foregroundStyle(Brand.mutedText)

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
                    Text("פתח את קיצורי דרך")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Brand.gold)
                        .foregroundStyle(Brand.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Brand.surface)
        .navigationTitle("קליטה אוטומטית")
        .navigationBarTitleDisplayMode(.inline)
    }
}
