import Testing
@testable import Contracts

struct ContractsSourceTests {
    @Test("Contracts names the backend generator that owns them")
    func generatorIsTheBackendCommand() {
        #expect(ContractsSource.generator == "pnpm gen:swift")
    }
}
