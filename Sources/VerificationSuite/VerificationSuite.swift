import Foundation
import ShellOut

func executableFromProjectBuild(xcodeproj: String, scheme: String, outputPath: String) -> String {
  
  let buildSettingsDict: [String:String] =
    xcodebuild(project: xcodeproj, scheme: scheme, outputBuildPath: outputPath)
      .components(separatedBy: "\n")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .reduce(into: [:]) { dict, settingLine in
        let pair = settingLine.components(separatedBy: " = ")
        guard pair.count == 2 else {
          return
        }
        dict[pair[0]] = pair[1]
  }
  
  guard let productsPathComponent = buildSettingsDict["BUILT_PRODUCTS_DIR"],
    let executablePathComponent = buildSettingsDict["EXECUTABLE_PATH"] else {
      print("Failed to extract executable path from built project")
      exit(0)
  }
  let executablePath = productsPathComponent + "/" + executablePathComponent
  
  return executablePath
}

func xcodebuild(project: String, scheme: String, outputBuildPath: String) -> String {
  // build project
  var arguments = [
    "-project", project,
    "-derivedDataPath", outputBuildPath,
    "-scheme", scheme,
    "-configuration", "Release",
    ]
  try! shellOut(to: "xcodebuild", arguments: arguments)
  
  // return build settings for the same build parameters
  arguments.append("-showBuildSettings")
  return try! shellOut(to: "xcodebuild", arguments: arguments)
}

func extractSymbolNames(executable: String) -> [String] {
  // TODO: for now, we expect the system to provide us with the nm tool available and globally linked
  // - consider adding nm tool path as script parameter
  let nmOutput = try! shellOut(to: "nm", arguments: [executable, "-format=posix"])
  let lines = nmOutput.components(separatedBy: "\n").filter { !$0.isEmpty }
  let symbolNames = lines.map { $0.components(separatedBy: " ").first! }
  return symbolNames
}

func demangle(symbols: [String]) -> String {
  // TODO: for now, we expect the system to provide us with the xcrun tool available and globally linked
  // - consider adding xcrun tool path as script parameter
  let demangleExec = try! shellOut(to: "xcrun", arguments: ["--find", "swift-demangle"])
  return try! shellOut(to: demangleExec, arguments: ["-compact"] + symbols)
}

func printToFile(string: String, filename: String) {
  try! shellOut(to: "echo", arguments: ["'\(string)'", ">", filename])
}

func diffFiles(before: String, after: String) -> String {
  do {
    let diff = try shellOut(to: "diff", arguments: [before, after])
    return diff
  } catch let error {
    print("Error while diffing files: \(error.localizedDescription)")
    return ""
  }
}

func removeDirectory(_ path: String) {
  try! shellOut(to: "rm", arguments: ["-rf", path])
}

func removeFile(_ path: String) {
  try! shellOut(to: "rm", arguments: [path])
}

