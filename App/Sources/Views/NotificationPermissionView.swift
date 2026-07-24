import SwiftUI

// Shown once, right after login succeeds — a native explainer BEFORE the iOS
// permission dialog (asking cold at first launch tanks accept rates, and the
// background intent can never prompt).
struct NotificationPermissionView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🔔")
                .font(.system(size: 56))

            Text("התראה על כל הוצאה")
                .font(.title.bold())
                .foregroundStyle(Brand.text)

            Text("כדי שתראה אישור על כל תשלום שנקלט,\nכולל כמה נשאר לך בתקציב,\nנבקש עכשיו אישור להתראות.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.mutedText)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                Task {
                    await Notifier.requestPermission()
                    appState.markAskedNotifications()
                }
            } label: {
                Text("הפעל התראות")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Brand.gold)
                    .foregroundStyle(Brand.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)

            Button("לא עכשיו") {
                appState.markAskedNotifications()
            }
            .font(.footnote)
            .foregroundStyle(Brand.mutedText)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.surface)
    }
}
