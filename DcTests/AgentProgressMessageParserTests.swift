import Testing
@testable import deltachat_ios

struct AgentProgressMessageParserTests {
    @Test func parsesRunningProgressAndUsesCurrentRunningCall() {
        let message =
        """
        Agent progress (v1, run=R42): running web.search
        Calls:
        1. ok fs.read_file - read input file
        2. run web.search - search docs
        """

        let parsed = AgentProgressMessage.parse(from: message)
        #expect(parsed != nil)
        #expect(parsed?.version == 1)
        #expect(parsed?.runId == "R42")
        #expect(parsed?.state == .running)
        #expect(parsed?.calls.count == 2)
        #expect(parsed?.collapsedText == "web.search - search docs")
    }

    @Test func parsesDoneProgressAndUsesLastCall() {
        let message =
        """
        Agent progress (v1): done web.search
        Calls:
        1. ok fs.read_file
        2. ok web.search - search docs
        """

        let parsed = AgentProgressMessage.parse(from: message)
        #expect(parsed != nil)
        #expect(parsed?.state == .done)
        #expect(parsed?.collapsedText == "web.search - search docs")
    }

    @Test func fallsBackToCurrentToolWhenNoCallsExist() {
        let parsed = AgentProgressMessage.parse(from: "Agent progress (v1): thinking planner")
        #expect(parsed != nil)
        #expect(parsed?.collapsedText == "planner")
    }

    @Test func usesCurrentToolWhenRunningHasNoRunCall() {
        let message =
        """
        Agent progress (v1): running web.search
        Calls:
        1. ok fs.read_file
        2. ok planner.prepare
        """

        let parsed = AgentProgressMessage.parse(from: message)
        #expect(parsed != nil)
        #expect(parsed?.collapsedText == "web.search")
    }

    @Test func rejectsUnsupportedVersion() {
        let parsed = AgentProgressMessage.parse(from: "Agent progress (v2): running planner")
        #expect(parsed == nil)
    }

    @Test func rejectsUnexpectedNonEmptyLines() {
        let message =
        """
        Agent progress (v1): running web.search
        Calls:
        1. run web.search
        unexpected trailing line
        """

        let parsed = AgentProgressMessage.parse(from: message)
        #expect(parsed == nil)
    }

    @Test func rejectsUnsupportedCallStatus() {
        let message =
        """
        Agent progress (v1): running web.search
        Calls:
        1. maybe web.search
        """

        let parsed = AgentProgressMessage.parse(from: message)
        #expect(parsed == nil)
    }
}
