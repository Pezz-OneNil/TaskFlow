import AppKit
import SwiftUI

/// Manages the menu bar status item for quick task creation
/// Per Requirement 15 (Menu Bar Integration)
public class TFMMenuBarManager: NSObject, ObservableObject {
    public static let shared = TFMMenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var onCaptureRequested: (() -> Void)?
    private var loadingWindow: NSWindow?
    
    private override init() {
        super.init()
    }
    
    /// Set up the menu bar item with capture action
    public func setup(onCaptureRequested: @escaping () -> Void) {
        self.onCaptureRequested = onCaptureRequested
        
        // Create status item in the system menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Load the TaskFlow app icon for menu bar
            if let appIconImage = loadMenuBarIcon() {
                button.image = appIconImage
            } else {
                // Fallback to SF Symbol if app icon not available
                if let image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "TaskFlow") {
                    image.isTemplate = true
                    button.image = image
                }
            }
            button.toolTip = "TaskFlow - Click to capture"
        }
        
        // Create the menu
        let menu = NSMenu()
        
        let captureItem = NSMenuItem(
            title: "Capture New Task",
            action: #selector(captureMenuItemClicked),
            keyEquivalent: ""
        )
        captureItem.target = self
        menu.addItem(captureItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let showAppItem = NSMenuItem(
            title: "Show TaskFlow",
            action: #selector(showAppClicked),
            keyEquivalent: ""
        )
        showAppItem.target = self
        menu.addItem(showAppItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit TaskFlow",
            action: #selector(quitClicked),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    /// Load the app icon for menu bar use
    private func loadMenuBarIcon() -> NSImage? {
        // Try to load from the app bundle
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let iconImage = NSImage(contentsOfFile: iconPath) {
            // Resize for menu bar (18x18 is standard)
            let menuBarSize = NSSize(width: 18, height: 18)
            let resizedImage = NSImage(size: menuBarSize)
            resizedImage.lockFocus()
            iconImage.draw(in: NSRect(origin: .zero, size: menuBarSize),
                          from: NSRect(origin: .zero, size: iconImage.size),
                          operation: .copy,
                          fraction: 1.0)
            resizedImage.unlockFocus()
            resizedImage.isTemplate = false  // Keep colors, don't adapt to menu bar
            return resizedImage
        }
        return nil
    }
    
    @objc private func captureMenuItemClicked() {
        print("TFMMenuBarManager: Capture requested from menu bar")
        onCaptureRequested?()
    }
    
    @objc private func showAppClicked() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.isVisible || $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
    
    /// Show a loading overlay on screen during capture processing
    public func showLoadingOverlay() {
        DispatchQueue.main.async { [weak self] in
            guard self?.loadingWindow == nil else { return }
            
            // Get the main screen
            guard let screen = NSScreen.main else { return }
            
            // Create a window that covers the screen
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            window.isOpaque = false
            window.backgroundColor = NSColor.clear
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.ignoresMouseEvents = true
            
            // Create the loading view
            let loadingView = TFMLoadingOverlayView()
            window.contentView = NSHostingView(rootView: loadingView)
            
            window.orderFrontRegardless()
            self?.loadingWindow = window
        }
    }
    
    /// Hide the loading overlay
    public func hideLoadingOverlay() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingWindow?.orderOut(nil)
            self?.loadingWindow = nil
        }
    }
    
    /// Remove the menu bar item
    public func teardown() {
        hideLoadingOverlay()
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }
}

/// SwiftUI view for the loading overlay
struct TFMLoadingOverlayView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Loading card
            VStack(spacing: 16) {
                // Animated spinner
                ZStack {
                    Circle()
                        .stroke(Color.purple.opacity(0.3), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                
                Text("Creating Task...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Processing screenshot and extracting text")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.1).opacity(0.95))
                    .shadow(color: Color.purple.opacity(0.3), radius: 20)
            )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "TFMMenuBarManager")
public typealias MenuBarManager = TFMMenuBarManager

@available(*, deprecated, renamed: "TFMLoadingOverlayView")
typealias LoadingOverlayView = TFMLoadingOverlayView
