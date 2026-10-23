import Testing
@testable import Data

struct BackendEnvironmentTests {
    @Test("Only the local dev stack and the hosted backend are known environments")
    func knownEnvironments() {
        #expect(BackendEnvironment.allCases == [.local, .hosted])
    }
}
