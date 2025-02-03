import Foundation

/// Adds capability for `URLSession` to be invalidated and recreated.
public protocol URLSessionInvalidatable {
    /// Returns `true` if session has been invalidate and is no longer suitable for usage.
    /// Any other usage of this urlSession will lead to runtime error.
    var urlSessionIsInvalidated: Bool { get }

    /// Replaces the urlSession instance used by APIManager.
    func setUrlSession(_ urlSession: URLSession)

    /// Invalidates the current urlSession.
    /// Warning: urlSession must be recreated before further usage
    /// otherwise runtime error is encountered as accessing invalidated session is illegal.
    func invalidateUrlSession() async
}
