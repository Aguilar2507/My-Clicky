import Foundation
import MyClickyCore

/// Checks for spec 010 (integrations).
enum IntegrationChecks {
    static var repo: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    static func run() {
        Check.group("Integration catalog") {
            let catalog = Integration.loadCatalog(from: try Data(contentsOf: repo.appendingPathComponent("Resources/integrations.json")))
            Check.equal(catalog.map(\.id), ["github", "notion", "linear", "atlassian", "asana", "sentry"])
            Check.expect(catalog.allSatisfy { $0.url?.hasPrefix("https://") == true }, "all remote, https")
            Check.equal(catalog[0].serverName, "myclicky-github")
            Check.equal(catalog[0].addArguments, ["mcp", "add", "--transport", "http", "-s", "user", "myclicky-github",
                                                  "https://api.githubcopilot.com/mcp/"])
            let local = Integration(id: "files", name: "Files", description: "", transport: .stdio, command: ["npx", "-y", "server"])
            Check.equal(local.addArguments, ["mcp", "add", "-s", "user", "myclicky-files", "--", "npx", "-y", "server"])
        }

        Check.group("claude mcp list parsing") {
            let text = try String(contentsOf: repo.appendingPathComponent("specs/010-integrations/samples/mcp-list.documented.txt"),
                                  encoding: .utf8)
            let entries = MCPListParser.parse(text)
            Check.equal(entries.count, 4, "header line ignored")
            Check.equal(entries[0], .init(name: "myclicky-github", target: "https://api.githubcopilot.com/mcp/ (HTTP)", status: .connected))
            Check.equal(entries[1].status, .needsAuth)
            Check.equal(entries[2].status, .failed("Failed to connect"))
            let split = MCPListParser.split(entries)
            Check.equal(split.ours["github"], .connected)
            Check.equal(split.ours["notion"], .needsAuth)
            Check.equal(split.others.map(\.name), ["filesystem"], "servers added outside MyClicky shown read-only")
        }

        Check.group("Integration search + custom connectors") {
            let catalog = Integration.loadCatalog(from: try Data(contentsOf: repo.appendingPathComponent("Resources/integrations.json")))
            Check.equal(IntegrationFilter.filter(catalog, query: "issues").map(\.id), ["github", "linear", "atlassian", "sentry"])
            Check.equal(IntegrationFilter.filter(catalog, query: "NOTION").map(\.id), ["notion"])
            if case .success(let c) = IntegrationFilter.custom(name: "My Tools", url: "https://tools.example.com/mcp", command: nil,
                                                               existing: catalog) {
                Check.equal(c.id, "my-tools")
                Check.equal(c.transport, .http)
                Check.expect(c.isCustom)
            } else { Check.expect(false, "valid URL connector") }
            Check.equal(IntegrationFilter.custom(name: "x", url: "http://insecure.com", command: nil, existing: []), .failure(.badURL))
            Check.equal(IntegrationFilter.custom(name: "GitHub", url: "https://a.com", command: nil, existing: catalog), .failure(.nameTaken))
            Check.equal(IntegrationFilter.custom(name: " ", url: "https://a.com", command: nil, existing: []), .failure(.emptyName))
            Check.equal(IntegrationFilter.custom(name: "Files", url: nil, command: "  ", existing: []), .failure(.emptyCommand))
        }
    }
}
