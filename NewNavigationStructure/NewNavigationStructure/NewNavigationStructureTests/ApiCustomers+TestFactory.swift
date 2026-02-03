// Create a debug-only factory to construct ApiCustomers for tests.
// Place this file in the main target so tests can import it via @testable.

#if DEBUG
import Foundation

// If ApiCustomers already exists in the main target, this extension will compile.
// We only rely on an initializer that accepts an id, or we provide a minimal shim
// guarded by conditional compilation to avoid affecting production builds.

#if canImport(NewNavigationStructure)
import NewNavigationStructure
#endif

extension ApiCustomers {
    // Adjust the body if your real type requires more fields.
    // This method is test-only and hidden behind DEBUG.
    public static func testMake(id: String) -> ApiCustomers {
        // Try common initializers; if your type differs, update accordingly.
        // The following line assumes an initializer `init(id: String)` exists.
        return ApiCustomers(id: id)
    }
}
#endif
