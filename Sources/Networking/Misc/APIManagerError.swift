import Foundation

/// An error in APIManager configuration..
enum APIManagerError: Error {
    /// An indication that the urlSession has been invalidated but not recreated.
    case invalidUrlSession
}
