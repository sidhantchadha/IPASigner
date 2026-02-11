// ResignIPAApp.swift
import SwiftUI
import AppKit

@main
struct ResignIPAApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class ConsoleLog: ObservableObject {
    @Published var output = ""

    func append(_ line: String) {
        DispatchQueue.main.async {
            self.output += "\n\(line)"
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.output = ""
        }
    }
}

struct ContentView: View {
    @State private var ipaURL: URL?
    @State private var provisionURL: URL?
    @State private var signingIdentities: [String] = []
    @State private var selectedIdentity: String = ""
    @StateObject private var console = ConsoleLog()

    var body: some View {
        VStack(spacing: 20) {
            Button("Select .ipa File") {
                ipaURL = openFileDialog(allowedTypes: ["ipa"])
                if let ipa = ipaURL {
                    console.append("📦 Selected IPA: \(ipa.lastPathComponent)")
                }
            }

            Button("Select Provisioning Profile") {
                provisionURL = openFileDialog(allowedTypes: ["mobileprovision"])
                if let prov = provisionURL {
                    console.append("🧾 Selected Provisioning Profile: \(prov.lastPathComponent)")
                }
            }

            Picker("Select Signing Identity", selection: $selectedIdentity) {
                ForEach(signingIdentities, id: \ .self) {
                    Text($0)
                }
            }
            .onAppear(perform: loadSigningIdentities)

            Button("Resign IPA") {
                if let ipa = ipaURL, let provision = provisionURL {
                    console.clear()
                    resignIPA(ipa: ipa, provision: provision, identity: selectedIdentity)
                }
            }

            Divider()
            Text("Console Output:").bold().frame(maxWidth: .infinity, alignment: .leading)
            TextEditor(text: $console.output)
                .font(.system(.footnote, design: .monospaced))
                .frame(height: 250)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)

            Spacer()

            Text("Built with ❤️ by Sidhant Chadha")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 10)
        }
        .padding()
        .frame(width: 600)
    }

    func openFileDialog(allowedTypes: [String]) -> URL? {
        let dialog = NSOpenPanel()
        dialog.allowedFileTypes = allowedTypes
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        return dialog.runModal() == .OK ? dialog.url : nil
    }

    func loadSigningIdentities() {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launchPath = "/usr/bin/security"
        task.arguments = ["find-identity", "-v", "-p", "codesigning"]

        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        let regex = try! NSRegularExpression(pattern: "\\\"(.*?iPhone.*?|.*?Apple.*?|.*?Developer.*?|.*?Distribution.*?)\\\"", options: [])
        let matches = regex.matches(in: output, range: NSRange(output.startIndex..., in: output))
        signingIdentities = matches.map {
            String(output[Range($0.range(at: 1), in: output)!])
        }
        if let first = signingIdentities.first {
            selectedIdentity = first
        }
    }

    func resignIPA(ipa: URL, provision: URL, identity: String) {
        console.append("Starting resign...")

        let tempDirBase = URL(fileURLWithPath: NSTemporaryDirectory())
        let tempDir = tempDirBase.appendingPathComponent("resign-temp")
        try? FileManager.default.removeItem(at: tempDir)

        let payloadDir = tempDir.appendingPathComponent("Payload")

        run("unzip \"\(ipa.path)\" -d \"\(tempDir.path)\"", logTo: console)

        guard let appName = try? FileManager.default.contentsOfDirectory(atPath: payloadDir.path).first(where: { $0.hasSuffix(".app") }) else {
            console.append("❌ .app not found inside Payload")
            return
        }

        let appPath = payloadDir.appendingPathComponent(appName)
        let embeddedPath = appPath.appendingPathComponent("embedded.mobileprovision")
        try? FileManager.default.removeItem(at: embeddedPath)
        try? FileManager.default.copyItem(at: provision, to: embeddedPath)

        let profilePlist = tempDir.appendingPathComponent("profile.plist")
        let entitlementsPath = tempDir.appendingPathComponent("entitlements.plist")

        console.append("📝 Extracting provisioning profile...")
        run("security cms -D -i \"\(provision.path)\" > \"\(profilePlist.path)\"", logTo: console)
        console.append("📝 Profile extracted to: \(profilePlist.path)")

        console.append("🔍 Attempting to parse provisioning profile...")
        do {
            let profilePlistData = try Data(contentsOf: profilePlist)
            console.append("📊 Profile data loaded: \(profilePlistData.count) bytes")
            if let profileDict = try PropertyListSerialization.propertyList(from: profilePlistData, options: [], format: nil) as? [String: Any] {
                console.append("📱 Provisioning profile parsed successfully with \(profileDict.keys.count) keys")
                if let entitlements = profileDict["Entitlements"] as? [String: Any] {
                    console.append("🔑 Entitlements found with \(entitlements.count) keys")

                    // ✅ Update CFBundleIdentifier from provisioning profile
                    if let appIdentifier = entitlements["application-identifier"] as? String {
                    console.append("📋 Found application-identifier: \(appIdentifier)")
                    let components = appIdentifier.split(separator: ".")
                    if components.count > 1 {
                        let newBundleID = components.dropFirst().joined(separator: ".")
                        console.append("🔄 Extracted Bundle ID: \(newBundleID)")
                        let infoPlistPath = appPath.appendingPathComponent("Info.plist")
                        if FileManager.default.fileExists(atPath: infoPlistPath.path) {
                            console.append("📄 Info.plist found at: \(infoPlistPath.path)")
                            var format = PropertyListSerialization.PropertyListFormat.xml
                            let plistData = try Data(contentsOf: infoPlistPath)
                            if var plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: &format) as? [String: Any] {
                                let oldBundleID = plist["CFBundleIdentifier"] as? String ?? "unknown"
                                console.append("🔍 Current Bundle ID: \(oldBundleID)")
                                plist["CFBundleIdentifier"] = newBundleID
                                let updatedPlist = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
                                try updatedPlist.write(to: infoPlistPath)
                                console.append("✅ Updated CFBundleIdentifier from \(oldBundleID) to \(newBundleID)")
                            } else {
                                console.append("⚠️ Could not parse Info.plist as dictionary")
                            }
                        } else {
                            console.append("⚠️ Info.plist not found at expected location")
                        }
                    } else {
                        console.append("⚠️ Application identifier has unexpected format: \(appIdentifier)")
                    }
                } else {
                    console.append("⚠️ No application-identifier found in entitlements")
                }

                    let entitlementsData = try PropertyListSerialization.data(fromPropertyList: entitlements, format: .xml, options: 0)
                    try entitlementsData.write(to: entitlementsPath)
                    console.append("✅ Entitlements written to: \(entitlementsPath.path)")
                } else {
                    console.append("⚠️ No Entitlements found in provisioning profile")
                }
            } else {
                console.append("⚠️ Could not parse provisioning profile plist")
            }
        } catch {
            console.append("❌ Failed to extract entitlements or update bundle ID: \(error.localizedDescription)")
            return
        }


        run("rm -rf \"\(appPath.appendingPathComponent("_CodeSignature").path)\"", logTo: console)

        if let frameworks = try? FileManager.default.contentsOfDirectory(atPath: appPath.appendingPathComponent("Frameworks").path) {
            for fw in frameworks where fw.hasSuffix(".framework") {
                let fwPath = appPath.appendingPathComponent("Frameworks/").appendingPathComponent(fw)
                run("codesign -f -s \"\(identity)\" --entitlements=\"\(entitlementsPath.path)\" \"\(fwPath.path)\"", logTo: console)
            }
        }

        run("codesign -f -s \"\(identity)\" --entitlements=\"\(entitlementsPath.path)\" --deep \"\(appPath.path)\"", logTo: console)

        let resignedIPA = tempDir.appendingPathComponent("resigned.ipa")
        run("cd \"\(tempDir.path)\" && zip -qr \"\(resignedIPA.path)\" Payload", logTo: console)

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "resigned.ipa"
        panel.allowedFileTypes = ["ipa"]

        if panel.runModal() == .OK, let target = panel.url {
            do {
                try FileManager.default.copyItem(at: resignedIPA, to: target)
                console.append("✅ Resigned IPA saved at \(target.path)")
            } catch {
                console.append("❌ Failed to save resigned IPA: \(error.localizedDescription)")
            }
        } else {
            console.append("❌ Save operation was canceled or failed.")
        }
    }

    func run(_ cmd: String, logTo console: ConsoleLog) {
        console.append("$ \(cmd)")
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", cmd]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            console.append(output)
        }
    }
}
