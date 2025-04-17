//
//  Created by Artem Novichkov on 17.04.2025.
//

import MCP
import Foundation

let server = Server(
    name: "Swift Version Server",
    version: "1.0.0",
    capabilities: .init(tools: .init(listChanged: false))
)

let transport = StdioTransport()
try await server.start(transport: transport)

let tool = Tool(name: "swift-version",
                description: "Returns the current Swift version")

await server.withMethodHandler(ListTools.self) { params in
    ListTools.Result(tools: [tool])
}

await server.withMethodHandler(CallTool.self) { params in
    guard params.name == tool.name else {
        throw MCPError.invalidParams("Wrong tool name")
    }
    return CallTool.Result(content: [.text(swiftVersion() ?? "No version")])
}

func swiftVersion() -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["swift", "--version"]

    let outputPipe = Pipe()
    process.standardOutput = outputPipe

    do {
        try process.run()
        process.waitUntilExit()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    } catch {
        return "Error running swift-version: \(error)"
    }
}

await server.waitUntilCompleted()
