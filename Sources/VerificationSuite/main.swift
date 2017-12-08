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

func removeDirectory(_ path: String) {
  try! shellOut(to: "rm", arguments: ["-rf", path])
}


// check script arguments

if CommandLine.argc != 5 {
  print("Usage: \(CommandLine.arguments[0]) <UNOBFUSCATED project .xcodeproj file> <UNOBFUSCATED project scheme> <OBFUSCATED project .xcodeproj file> <OBFUSCATED project scheme>")
  exit(0)
}


// build projects and extract executables paths

let xcodeprojBeforeObfuscation = CommandLine.arguments[1]
let schemeBeforeObfuscation = CommandLine.arguments[2]
let xcodeprojAfterObfuscation = CommandLine.arguments[3]
let schemeAfterObfuscation = CommandLine.arguments[4]

let buildPathBeforeObfuscation = "UnobfuscatedBuild"
let buildPathAfterObfuscation = "ObfuscatedBuild"

let unobfuscatedExecutablePath = executableFromProjectBuild(xcodeproj: xcodeprojBeforeObfuscation, scheme: schemeBeforeObfuscation, outputPath: buildPathBeforeObfuscation)
let obfuscatedExecutablePath = executableFromProjectBuild(xcodeproj: xcodeprojAfterObfuscation, scheme: schemeAfterObfuscation, outputPath: buildPathAfterObfuscation)


// TODO:
// - extract swift symbols from executables
// - demangle them
// - compare symbols before / after obfuscation


// remove build directories

removeDirectory(buildPathBeforeObfuscation)
removeDirectory(buildPathAfterObfuscation)

