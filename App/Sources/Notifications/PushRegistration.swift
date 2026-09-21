import Foundation
import UIKit
import UserNotifications

/// רישום המכשיר להתראות מרחוק, מול `/api/push-token`.
///
/// עד היום השרת ידע להגיע לדפדפן ולמייל בלבד. שתי אפליקציות החנות הן WebView
/// ואין בהן את מנגנון ההתראות של הדפדפן, כך שדווקא מי שהתקין את האפליקציה היה
/// היחיד שאי אפשר להתריע לו. אנדרואיד נרשם דרך FCM; כאן דרך APNs ישירות.
///
/// אותה צורה בדיוק כמו `PushRegistrar.kt` בצד אנדרואיד: בקשת HTTP חשופה, טוקן
/// המכשיר בגוף ה-JSON (אין בכל האפליקציה כותרת אימות), והכול שקט. רישום הוא
/// בונוס, הוא לעולם לא מפיל את פתיחת האפליקציה ולא את הקליטה.
enum PushRegistration {

    // MARK: - Asking iOS for a token

    /**
     מבקש מ-iOS טוקן APNs, אבל רק אם יש למי לשייך אותו ורק אם ההרשאה כבר ניתנה.

     🔴 נקרא בכל פתיחה של האפליקציה, ולא רק פעם אחת אחרי מסך ההרשאה. שתי סיבות,
     ושתיהן אירעו במערכת הזאת:

     1. `didAskNotifications` דביק ב-`UserDefaults`. כל מי שהתקין את האפליקציה
        לפני העדכון הזה כבר עבר את מסך ההרשאה ולעולם לא יראה אותו שוב, ולכן
        רישום שתלוי באותו מסך בלבד לא יגיע לאף משתמש קיים.
     2. טוקן APNs מתחלף מעצמו: התקנה מחדש, שחזור גיבוי, העברה למכשיר חדש.
        רישום שנשלח פעם אחת בלבד הופך בשקט למכשיר שלא מקבל כלום.

     ההרשאה נבדקת ולא נדרשת: `registerForRemoteNotifications` בלי הרשאה מחזיר
     טוקן שאפל לעולם לא תמסור עליו הודעה גלויה, כלומר רישום שנראה תקין ושותק.
     */
    static func registerIfPermitted() {
        guard hasDeviceToken else { return }   // עוד לא מחובר, אין למי לשייך
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            default:
                break
            }
        }
    }

    // MARK: - Handing the token to our server

    /**
     נקרא מה-AppDelegate כש-iOS מוסר את הטוקן.

     אפל מוסרת אותו כ-`Data` גולמי, והשרת מצפה למחרוזת הקסדצימלית. זו ההמרה
     שה-SDK של FCM עושה מאחורי הקלעים, וכאן היא מפורשת.
     */
    static func send(apnsToken: Data) {
        let hex = apnsToken.map { String(format: "%02x", $0) }.joined()
        guard !hex.isEmpty, let device = deviceToken else { return }
        post(method: "POST", body: ["token": device, "pushToken": hex, "platform": "ios"])
    }

    /**
     🔴 הסרה ביציאה מהחשבון, וזאת לא נקודה משנית.

     טוקן שנשאר רשום פירושו שהאדם הבא שישתמש במכשיר הזה יקבל את התראות התקציב
     של הקודם. דליפה מהסוג הזה כבר קרתה כאן פעמיים.

     🔴 חייב לרוץ **לפני** מחיקת הטוקן מה-Keychain, כי הבקשה עצמה מזדהה באותו
     טוקן. אחרי המחיקה אין במה להזדהות והבקשה תידחה ב-401, כלומר הרישום יישאר
     על השרת בשקט. לכן `AppState.disconnect()` קורא לכאן בשורה הראשונה.

     בלי לציין טוקן APNs: השרת מסיר את כל הרישומים של המשתמש. זה מכוון. בזמן
     יציאה ייתכן שאין בידינו טוקן תקף, ורישום שנשאר גרוע בהרבה מרישום שנמחק
     פעם אחת יותר מדי.
     */
    static func unregister() {
        guard let device = deviceToken else { return }
        post(method: "DELETE", body: ["token": device])
        UIApplication.shared.unregisterForRemoteNotifications()
    }

    // MARK: - Plumbing

    private static var deviceToken: String? {
        guard let t = KeychainStore.loadToken()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !t.isEmpty else { return nil }
        return t
    }

    private static var hasDeviceToken: Bool { deviceToken != nil }

    private static func post(method: String, body: [String: String]) {
        guard let payload = try? JSONSerialization.data(withJSONObject: body) else { return }
        var request = URLRequest(url: Config.pushTokenEndpoint)
        request.httpMethod = method
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload
        request.timeoutInterval = 15
        // שקט בכוונה, בדיוק כמו בצד אנדרואיד: הרישום משני לקליטה ולפתיחה.
        URLSession.shared.dataTask(with: request).resume()
    }
}
