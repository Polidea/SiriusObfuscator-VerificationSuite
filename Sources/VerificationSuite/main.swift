import Foundation

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

// extract symbol names from executables and demangle them

let symbolsBefore = demangle(symbols: extractSymbolNames(executable: unobfuscatedExecutablePath))
let symbolsBeforeFile = "before.txt"
printToFile(string: symbolsBefore, filename: symbolsBeforeFile)

let symbolsAfter = demangle(symbols: extractSymbolNames(executable: obfuscatedExecutablePath))
let symbolsAfterFile = "after.txt"
printToFile(string: symbolsAfter, filename: symbolsAfterFile)

// compare symbol names before / after obfuscation

print("\n\nDIFF BEFORE / AFTER OBFUSCATION:")
let diff = diffFiles(before: symbolsBeforeFile, after: symbolsAfterFile)
print(diff)

// remove build directories and symbol files

removeDirectory(buildPathBeforeObfuscation)
removeDirectory(buildPathAfterObfuscation)

removeFile(symbolsBeforeFile)
removeFile(symbolsAfterFile)

