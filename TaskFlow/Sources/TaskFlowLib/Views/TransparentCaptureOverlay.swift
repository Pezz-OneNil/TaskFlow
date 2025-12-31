import SwiftUI
import AppKit

/// Result of a capture operation
public struct CaptureResult {
    public let image: NSImage
    public let region: CGRect
    
    public init(image: NSImage, region: CGRect) {
        self.image = image
        self.region = region
    }
}

/// Transparent overlay for screen region selection
/// Per Requirement 2.1, 2.2
public struct TransparentCaptureOverlay: View {
    @Binding var isPresented: Bool
    let onCapture: (CaptureResult) -> Void
    let onCancel: () -> Void
    
    @State private var startPoint: CGPoint?
    @State private var currentPoint: CGPoint?
    @State private var isDragging = false
    
    public init(
        isPresented: Binding<Bool>,
        onCapture: @escaping (CaptureResult) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.onCapture = onCapture
        self.onCancel = onCancel
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // Selection rectangle
                if let rect = selectionRect {
                    // Darken area outside selection
                    SelectionMask(rect: rect, screenSize: geometry.size)
                    
                    // Selection border with neon glow
                    Rectangle()
                        .stroke(CyberpunkTheme.accentCyan, lineWidth: 2)
                        .shadow(color: CyberpunkTheme.accentCyan, radius: CyberpunkTheme.glowRadius)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    
                    // Dimension label
                    dimensionLabel(for: rect)
                }
                
                // Instructions
                if !isDragging {
                    instructionsOverlay
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if startPoint == nil {
                            startPoint = value.startLocation
                            print("CaptureOverlay: Drag started at \(value.startLocation)")
                        }
                        currentPoint = value.location
                        isDragging = true
                    }
                    .onEnded { value in
                        print("CaptureOverlay: Drag ended at \(value.location)")
                        if let rect = selectionRect {
                            print("CaptureOverlay: Selection rect: \(rect) (width: \(rect.width), height: \(rect.height))")
                            if rect.width > 10 && rect.height > 10 {
                                print("CaptureOverlay: Valid selection, calling captureRegion")
                                captureRegion(rect)
                            } else {
                                print("CaptureOverlay: Selection too small, resetting")
                                resetSelection()
                            }
                        } else {
                            print("CaptureOverlay: No selection rect, resetting")
                            resetSelection()
                        }
                    }
            )
            .onExitCommand {
                print("CaptureOverlay: Escape pressed, cancelling")
                onCancel()
                isPresented = false
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Selection Rectangle
    
    private var selectionRect: CGRect? {
        guard let start = startPoint, let current = currentPoint else { return nil }
        
        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let width = abs(current.x - start.x)
        let height = abs(current.y - start.y)
        
        return CGRect(x: minX, y: minY, width: width, height: height)
    }
    
    // MARK: - UI Components
    
    private var instructionsOverlay: some View {
        VStack(spacing: CyberpunkTheme.spacingM) {
            Image(systemName: "viewfinder")
                .font(.system(size: 48))
                .foregroundColor(CyberpunkTheme.accentCyan)
            
            Text("Drag to select capture region")
                .font(CyberpunkTheme.fontHeadline)
                .foregroundColor(CyberpunkTheme.textPrimary)
            
            Text("Press Escape to cancel")
                .font(CyberpunkTheme.fontCaption)
                .foregroundColor(CyberpunkTheme.textSecondary)
        }
        .padding(CyberpunkTheme.spacingL)
        .background(
            RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                .fill(CyberpunkTheme.backgroundSecondary.opacity(0.9))
        )
    }
    
    private func dimensionLabel(for rect: CGRect) -> some View {
        Text("\(Int(rect.width)) × \(Int(rect.height))")
            .font(CyberpunkTheme.fontCaption)
            .foregroundColor(CyberpunkTheme.textPrimary)
            .padding(.horizontal, CyberpunkTheme.spacingS)
            .padding(.vertical, CyberpunkTheme.spacingXS)
            .background(
                Capsule()
                    .fill(CyberpunkTheme.backgroundSecondary.opacity(0.9))
            )
            .position(x: rect.midX, y: rect.maxY + 20)
    }
    
    // MARK: - Capture Logic
    
    private func captureRegion(_ rect: CGRect) {
        print("CaptureOverlay: captureRegion called with rect \(rect)")
        // Pass the selection rect to the callback
        // The window controller will handle hiding the window and capturing
        // We create a dummy CaptureResult with just the region - the controller will do the actual capture
        let dummyResult = CaptureResult(image: NSImage(), region: rect)
        onCapture(dummyResult)
    }
    
    private func resetSelection() {
        print("CaptureOverlay: resetSelection called")
        startPoint = nil
        currentPoint = nil
        isDragging = false
    }
}

/// Mask that darkens area outside selection
struct SelectionMask: View {
    let rect: CGRect
    let screenSize: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Fill entire area with dark overlay
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.black.opacity(0.5))
            )
            
            // Clear the selection area
            context.blendMode = .destinationOut
            context.fill(
                Path(rect),
                with: .color(.white)
            )
        }
        .allowsHitTesting(false)
    }
}

/// Multi-monitor capture overlay controller
/// Creates overlay windows on all connected screens using AppKit views (not SwiftUI)
public class CaptureOverlayWindowController: NSObject {
    
    private var onCapture: ((CaptureResult) -> Void)?
    private var onCancel: (() -> Void)?
    private let screenCaptureEngine = ScreenCaptureEngine()
    
    // Windows for each screen
    private var overlayWindows: [NSWindow] = []
    private var overlayViews: [CaptureOverlayNSView] = []
    
    // Keep a strong reference to prevent deallocation during capture
    private static var activeController: CaptureOverlayWindowController?
    
    public init(onCapture: @escaping (CaptureResult) -> Void, onCancel: @escaping () -> Void) {
        self.onCapture = onCapture
        self.onCancel = onCancel
        
        super.init()
        
        setupOverlayWindows()
    }
    
    /// Create overlay windows for all connected screens
    private func setupOverlayWindows() {
        let screens = NSScreen.screens
        print("CaptureController: Setting up overlays for \(screens.count) screen(s)")
        
        for (index, screen) in screens.enumerated() {
            print("CaptureController: Screen \(index): frame=\(screen.frame), visibleFrame=\(screen.visibleFrame)")
            
            // Create window with the screen's frame
            let overlayWindow = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen  // Associate window with specific screen
            )
            
            overlayWindow.isOpaque = false
            overlayWindow.backgroundColor = NSColor.clear
            overlayWindow.level = .screenSaver
            overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            overlayWindow.ignoresMouseEvents = false
            overlayWindow.hasShadow = false
            overlayWindow.isReleasedWhenClosed = false
            
            // Set the frame explicitly to match the screen
            overlayWindow.setFrame(screen.frame, display: true)
            
            // Create AppKit-based overlay view with bounds matching the screen size
            // The view's coordinate system starts at (0,0) in bottom-left
            let viewFrame = NSRect(origin: .zero, size: screen.frame.size)
            let overlayView = CaptureOverlayNSView(frame: viewFrame)
            overlayView.screenFrame = screen.frame
            overlayView.screenIndex = index
            overlayView.onCapture = { [weak self] rect, screenIdx in
                self?.handleCapture(rect: rect, screenIndex: screenIdx)
            }
            overlayView.onCancel = { [weak self] in
                self?.cancelCapture()
            }
            
            overlayWindow.contentView = overlayView
            overlayWindows.append(overlayWindow)
            overlayViews.append(overlayView)
            
            print("CaptureController: Window \(index) created at \(overlayWindow.frame)")
        }
    }
    
    private func handleCapture(rect: CGRect, screenIndex: Int) {
        guard screenIndex < NSScreen.screens.count else { return }
        let screen = NSScreen.screens[screenIndex]
        
        // The rect is in view coordinates (bottom-left origin within the view)
        // The view frame matches the screen frame
        // NSScreen coordinates also use bottom-left origin
        // So we just need to add the screen's origin to get global NSScreen coordinates
        let globalRect = CGRect(
            x: screen.frame.origin.x + rect.origin.x,
            y: screen.frame.origin.y + rect.origin.y,
            width: rect.width,
            height: rect.height
        )
        
        print("CaptureController: Screen \(screenIndex) frame: \(screen.frame)")
        print("CaptureController: Local rect (view coords): \(rect)")
        print("CaptureController: Global rect (NSScreen coords): \(globalRect)")
        
        performCapture(for: globalRect, on: screen)
    }
    
    /// Perform the actual capture - hides all windows first, then captures
    private func performCapture(for globalRect: CGRect, on screen: NSScreen) {
        print("CaptureController: performCapture called")
        print("CaptureController: Global rect (NSScreen coords): \(globalRect)")
        
        // Store callbacks locally
        let captureCallback = self.onCapture
        let cancelCallback = self.onCancel
        let captureEngine = self.screenCaptureEngine
        
        // Hide all overlay windows immediately
        for window in overlayWindows {
            window.orderOut(nil)
        }
        print("CaptureController: All windows hidden")
        
        // Delay to ensure windows are fully hidden before capture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            print("CaptureController: Starting async capture task")
            
            _Concurrency.Task {
                do {
                    // Find the primary screen (the one with origin 0,0 in NSScreen coordinates)
                    guard let primaryScreen = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.main else {
                        throw ScreenCaptureError.noDisplaysAvailable
                    }
                    
                    print("CaptureController: Primary screen: \(primaryScreen.frame)")
                    
                    // CGWindowListCreateImage uses a coordinate system where:
                    // - Origin (0,0) is at the TOP-LEFT of the PRIMARY display
                    // - Y increases downward
                    // - Screens above the primary have NEGATIVE Y values in CG coords
                    // - Screens below the primary have POSITIVE Y values in CG coords
                    //
                    // NSScreen uses a coordinate system where:
                    // - Origin (0,0) is at the BOTTOM-LEFT of the PRIMARY display
                    // - Y increases upward
                    // - Screens above the primary have POSITIVE Y values in NS coords
                    // - Screens below the primary have NEGATIVE Y values in NS coords
                    //
                    // Conversion formula:
                    // CG_Y = primaryScreen.height - NS_Y - rect.height
                    //
                    // This works because:
                    // - For a point at the TOP of primary screen: NS_Y = primaryHeight, CG_Y = 0
                    // - For a point at the BOTTOM of primary screen: NS_Y = 0, CG_Y = primaryHeight
                    // - For screens ABOVE primary: NS_Y > primaryHeight, so CG_Y becomes negative
                    
                    let primaryHeight = primaryScreen.frame.height
                    
                    let cgRect = CGRect(
                        x: globalRect.origin.x,
                        y: primaryHeight - globalRect.origin.y - globalRect.height,
                        width: globalRect.width,
                        height: globalRect.height
                    )
                    
                    print("CaptureController: Primary height: \(primaryHeight)")
                    print("CaptureController: CG rect (for capture): \(cgRect)")
                    
                    let image = try await captureEngine.captureSelectedRegion(rect: cgRect)
                    print("CaptureController: Capture successful, size: \(image.size)")
                    
                    let result = CaptureResult(image: image, region: cgRect)
                    
                    await MainActor.run {
                        print("CaptureController: Calling capture callback")
                        captureCallback?(result)
                        self?.cleanup()
                    }
                } catch {
                    print("CaptureController: Capture error - \(error)")
                    await MainActor.run {
                        cancelCallback?()
                        self?.cleanup()
                    }
                }
            }
        }
    }
    
    private func cancelCapture() {
        print("CaptureController: cancelCapture called")
        onCancel?()
        cleanup()
    }
    
    private func cleanup() {
        print("CaptureController: cleanup called")
        // Clear the views first (this will trigger deinit and remove event monitors)
        overlayViews.removeAll()
        
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
        CaptureOverlayWindowController.activeController = nil
    }
    
    public func present() {
        print("CaptureController: present called with \(overlayWindows.count) windows")
        CaptureOverlayWindowController.activeController = self
        
        // First, order all windows to front
        for (index, window) in overlayWindows.enumerated() {
            window.orderFrontRegardless()
            print("CaptureController: Showing window \(index) at \(window.frame)")
        }
        
        // Make the first window key (for keyboard events)
        if let firstWindow = overlayWindows.first {
            firstWindow.makeKey()
        }
        
        // Activate the app
        NSApp.activate(ignoringOtherApps: true)
        
        // Make each overlay view the first responder for its window
        for (index, window) in overlayWindows.enumerated() {
            if let view = overlayViews[safe: index] {
                window.makeFirstResponder(view)
            }
        }
    }
}

/// AppKit-based overlay view for screen capture selection
/// Uses pure AppKit to avoid SwiftUI memory management issues
class CaptureOverlayNSView: NSView {
    var screenFrame: CGRect = .zero
    var screenIndex: Int = 0
    var onCapture: ((CGRect, Int) -> Void)?
    var onCancel: (() -> Void)?
    
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var isDragging = false
    
    // Track the escape key monitor
    private var localMonitor: Any?
    private var globalMonitor: Any?
    
    private var selectionRect: CGRect? {
        guard let start = startPoint, let current = currentPoint else { return nil }
        
        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let width = abs(current.x - start.x)
        let height = abs(current.y - start.y)
        
        return CGRect(x: minX, y: minY, width: width, height: height)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        
        // Add event monitors for escape key
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                print("CaptureOverlayNSView: Escape pressed (local monitor)")
                self?.onCancel?()
                return nil // Consume the event
            }
            return event
        }
    }
    
    deinit {
        // Remove event monitors
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            print("CaptureOverlayNSView: Escape pressed (keyDown)")
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        startPoint = point
        currentPoint = point
        isDragging = true
        print("CaptureOverlayNSView: Mouse down at \(point)")
        needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        print("CaptureOverlayNSView: Mouse up at \(currentPoint ?? .zero)")
        
        if let rect = selectionRect {
            print("CaptureOverlayNSView: Selection rect (view coords): \(rect)")
            if rect.width > 10 && rect.height > 10 {
                print("CaptureOverlayNSView: Valid selection")
                // Pass the rect in view coordinates - the controller will handle conversion
                // NSView uses bottom-left origin, same as NSScreen
                onCapture?(rect, screenIndex)
            } else {
                print("CaptureOverlayNSView: Selection too small, resetting")
                resetSelection()
            }
        } else {
            resetSelection()
        }
    }
    
    private func resetSelection() {
        startPoint = nil
        currentPoint = nil
        isDragging = false
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Draw semi-transparent background
        context.setFillColor(NSColor.black.withAlphaComponent(0.3).cgColor)
        context.fill(bounds)
        
        // Draw selection rectangle if dragging
        if let rect = selectionRect {
            // Clear the selection area
            context.setBlendMode(.clear)
            context.fill(rect)
            context.setBlendMode(.normal)
            
            // Draw selection border
            context.setStrokeColor(NSColor.cyan.cgColor)
            context.setLineWidth(2)
            context.stroke(rect)
            
            // Draw dimension label
            let dimensionText = "\(Int(rect.width)) × \(Int(rect.height))"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.white
            ]
            let textSize = dimensionText.size(withAttributes: attributes)
            let textRect = CGRect(
                x: rect.midX - textSize.width / 2 - 8,
                y: rect.minY - textSize.height - 12,
                width: textSize.width + 16,
                height: textSize.height + 8
            )
            
            // Background for text
            context.setFillColor(NSColor.black.withAlphaComponent(0.7).cgColor)
            let bgPath = NSBezierPath(roundedRect: textRect, xRadius: 4, yRadius: 4)
            bgPath.fill()
            
            // Draw text
            dimensionText.draw(
                at: CGPoint(x: textRect.origin.x + 8, y: textRect.origin.y + 4),
                withAttributes: attributes
            )
        }
        
        // Draw instructions if not dragging
        if !isDragging {
            drawInstructions(in: context)
        }
    }
    
    private func drawInstructions(in context: CGContext) {
        let centerX = bounds.midX
        let centerY = bounds.midY
        
        let title = "Drag to select capture region"
        let subtitle = "Works on any monitor • Press Escape to cancel"
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: NSColor.white
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.lightGray
        ]
        
        let titleSize = title.size(withAttributes: titleAttributes)
        let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
        
        let boxWidth = max(titleSize.width, subtitleSize.width) + 48
        let boxHeight: CGFloat = 100
        let boxRect = CGRect(
            x: centerX - boxWidth / 2,
            y: centerY - boxHeight / 2,
            width: boxWidth,
            height: boxHeight
        )
        
        // Draw background box
        context.setFillColor(NSColor.black.withAlphaComponent(0.8).cgColor)
        let bgPath = NSBezierPath(roundedRect: boxRect, xRadius: 12, yRadius: 12)
        bgPath.fill()
        
        // Draw title
        title.draw(
            at: CGPoint(x: centerX - titleSize.width / 2, y: centerY + 5),
            withAttributes: titleAttributes
        )
        
        // Draw subtitle
        subtitle.draw(
            at: CGPoint(x: centerX - subtitleSize.width / 2, y: centerY - 25),
            withAttributes: subtitleAttributes
        )
    }
}



// MARK: - Array Safe Subscript Extension

private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
