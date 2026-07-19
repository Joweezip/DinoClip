import Cocoa
import SwiftUI

// --- LOGIC ---
class ClipboardManager: ObservableObject {
    @Published var items: [String] = []
    private let pasteboard = NSPasteboard.general
    private var changeCount: Int
    
    init() {
        self.changeCount = pasteboard.changeCount
        self.items = UserDefaults.standard.stringArray(forKey: "history") ?? []
        // Poll every 0.5 seconds for changes
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in self.check() }
    }
    
    func check() {
    // This looks at the system clipboard's change count
    if pasteboard.changeCount != changeCount {
        // 'string(forType: .string)' automatically waits 
        // a millisecond for Universal Clipboard to download the text
        if let str = pasteboard.string(forType: .string), !str.trimmingCharacters(in: .whitespaces).isEmpty {
            if items.first != str {
                items.removeAll { $0 == str }
                items.insert(str, at: 0)
                if items.count > 10 { items.removeLast() }
                UserDefaults.standard.set(items, forKey: "history")
            }
        }
        changeCount = pasteboard.changeCount
    }
}
    
    func copyToClipboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func deleteItem(_ item: String) {
        items.removeAll { $0 == item }
        UserDefaults.standard.set(items, forKey: "history")
    }

    func clearAll() {
        items.removeAll()
        UserDefaults.standard.set([], forKey: "history")
    }
}

// --- UI (GLASS STYLE) ---
struct DinoView: View {
    @ObservedObject var manager: ClipboardManager
    @State private var hoveredItem: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("🦖 DinoClip")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary.opacity(0.8))
                Spacer()
                Button("Clear All") { manager.clearAll() }
                    .buttonStyle(.plain)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 15).padding(.top, 12).padding(.bottom, 8)
            
            Divider().opacity(0.1).padding(.horizontal, 10)
            
            // List of Clips
            VStack(spacing: 6) {
                if manager.items.isEmpty {
                    Text("History is empty")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                } else {
                    ForEach(manager.items, id: \.self) { item in
                        HStack(spacing: 0) {
                            Button(action: { manager.copyToClipboard(item) }) {
                                Text(item.prefix(45) + (item.count > 45 ? "..." : ""))
                                    .font(.system(size: 11, design: .monospaced))
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8).padding(.horizontal, 10)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { manager.deleteItem(item) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary.opacity(0.4))
                                    .padding(.horizontal, 10)
                                    .frame(maxHeight: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                        .background(hoveredItem == item ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03))
                        .cornerRadius(6)
                        .onHover { isHovered in hoveredItem = isHovered ? item : nil }
                    }
                }
            }
            .padding(10)

            Divider().opacity(0.1).padding(.horizontal, 10)
            
            // Footer
            Button("Quit DinoClip") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .frame(width: 300)
        .background(VisualEffectView()) 
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow // Dark glass
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// --- APP DELEGATE ---
 class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover = NSPopover()
    let manager = ClipboardManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    popover.animates = false 
    popover.contentViewController = NSHostingController(rootView: DinoView(manager: manager))
    popover.behavior = .transient

    if let button = statusItem.button {
        // PROFESSIONAL FIX: Look inside the app bundle's resources
        if let iconURL = Bundle.main.url(forResource: "icon", withExtension: "png"),
           let image = NSImage(contentsOf: iconURL) {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true 
            button.image = image
        } else {
            // Fallback to emoji if the icon isn't found inside the app
            button.title = "🦖"
        }
        button.action = #selector(togglePopover)
        button.target = self
    }
}
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                // This line is the magic fix for the UI jumping or gaps
                popover.contentSize = popover.contentViewController?.view.fittingSize ?? NSSize(width: 300, height: 400)
                
                NSApplication.shared.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()