import Foundation

// Single source of truth for URLs and scheme constants.
// Mirrors the Android shell's NotificationListener companion constants.
enum Config {
    static let baseURL = URL(string: "https://app.orimipuy.com")!

    /// The in-WebView launcher page: exchanges the device token (in the URL
    /// fragment — never sent to the server) for a Firebase session and lands
    /// on the logged-in expenses tab.
    static func expensesURL(token: String) -> URL {
        URL(string: "\(baseURL)/connect/expenses#token=\(token.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? token)")!
    }

    /// Login page opened in system Safari. ?native=1 tells it to hand the
    /// device token back via the mipuytracker:// deep link (like Android)
    /// instead of the iOS copy-token flow.
    static let connectURL = URL(string: "https://app.orimipuy.com/connect?native=1")!

    static let transactionEndpoint = URL(string: "https://app.orimipuy.com/api/transaction")!

    /// Custom URL scheme shared with the Android app and the /connect page.
    static let scheme = "mipuytracker"
}
