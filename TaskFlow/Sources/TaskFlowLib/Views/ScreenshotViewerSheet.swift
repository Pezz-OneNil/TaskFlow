import SwiftUI
import AppKit

/// Sheet for viewing and cropping screenshots
/// Per Requirements 2A.3, 2A.4
public struct ScreenshotViewerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let screenshot: NSImage
    let screenshotId: UUID?
    let screenshotManager: ScreenshotManager
    let textExtractor: TextExtractor
    let onCrop: ((UUID, TextExtraction?) -> Void)?
    
    @State private var zoomLevel: CGFloat = 1.0
    @State private var isCropping = false
    @State private var cropStart: CGPoint?
    @State private var cropEnd: CGPoint?
    @State private var isProcessingCrop = false
    @State private var errorMessage: String?
    
    private let minZoom: CGFloat = 0.25
    private let maxZoom: CGFloat = 4.0
    
    public init(
        screenshot: NSImage,
        screenshotId: UUID? = nil,
        screenshotManager: ScreenshotManager = ScreenshotManager(),
        textExtractor: TextExtractor = TextExtractor(),
        onCrop: ((UUID, TextExtraction?) -> Void)? = nil
    ) {
        self.screenshot = screenshot
        self.screenshotId = screenshotId
        self.screenshotManager = screenshotManager
        self.textExtractor = textExtractor
        self.onCrop = onCrop
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            // Image viewer
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        // Screenshot image
                        Image(nsImage: screenshot)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                width: screenshot.size.width * zoomLevel,
                                height: screenshot.size.height * zoomLevel
                            )
                        
                        // Crop overlay
                        if isCropping {
                            cropOverlay(imageSize: CGSize(
                                width: screenshot.size.width * zoomLevel,
                                height: screenshot.size.height * zoomLevel
                            ))
                        }
                    }
                    .frame(
                        minWidth: geometry.size.width,
                        minHeight: geometry.size.height
                    )
                }
            }
            
            Divider()
                .background(CyberpunkTheme.accentPurple.opacity(0.3))
            
            // Footer with controls
            footer
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(CyberpunkTheme.backgroundPrimary)
        .overlay {
            if isProcessingCrop {
                processingOverlay
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            GlowingText("Screenshot Viewer", color: CyberpunkTheme.accentPurple, font: CyberpunkTheme.fontTitle)
            
            Spacer()
            
            // Zoom controls
            HStack(spacing: CyberpunkTheme.spacingS) {
                NeonIconButton(systemName: "minus.magnifyingglass", color: CyberpunkTheme.accentCyan) {
                    zoomOut()
                }
                .disabled(zoomLevel <= minZoom)
                
                Text("\(Int(zoomLevel * 100))%")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                    .frame(width: 50)
                
                NeonIconButton(systemName: "plus.magnifyingglass", color: CyberpunkTheme.accentCyan) {
                    zoomIn()
                }
                .disabled(zoomLevel >= maxZoom)
                
                NeonIconButton(systemName: "1.magnifyingglass", color: CyberpunkTheme.accentCyan) {
                    zoomLevel = 1.0
                }
            }
            
            Spacer()
            
            NeonIconButton(systemName: "xmark", color: CyberpunkTheme.textSecondary) {
                dismiss()
            }
        }
        .padding(CyberpunkTheme.spacingM)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            // Image info
            VStack(alignment: .leading, spacing: 2) {
                Text("Size: \(Int(screenshot.size.width)) × \(Int(screenshot.size.height))")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                
                if let cropRect = currentCropRect {
                    Text("Selection: \(Int(cropRect.width / zoomLevel)) × \(Int(cropRect.height / zoomLevel))")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.accentCyan)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: CyberpunkTheme.spacingM) {
                if isCropping {
                    NeonButton(title: "Cancel Crop", color: CyberpunkTheme.textSecondary) {
                        cancelCrop()
                    }
                    
                    NeonButton(title: "Apply Crop", color: CyberpunkTheme.accentGreen) {
                        applyCrop()
                    }
                    .disabled(currentCropRect == nil || currentCropRect!.width < 10 || currentCropRect!.height < 10)
                } else {
                    NeonButton(title: "Crop", color: CyberpunkTheme.accentMagenta) {
                        startCrop()
                    }
                    .disabled(screenshotId == nil)
                }
                
                NeonButton(title: "Close", color: CyberpunkTheme.textSecondary) {
                    dismiss()
                }
            }
        }
        .padding(CyberpunkTheme.spacingM)
    }
    
    // MARK: - Crop Overlay
    
    @ViewBuilder
    private func cropOverlay(imageSize: CGSize) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Darkened background
                Color.black.opacity(0.4)
                    .allowsHitTesting(false)
                
                // Clear selection area
                if let rect = currentCropRect {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .blendMode(.destinationOut)
                    
                    // Selection border
                    Rectangle()
                        .stroke(CyberpunkTheme.accentCyan, lineWidth: 2)
                        .shadow(color: CyberpunkTheme.accentCyan, radius: CyberpunkTheme.glowRadius)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    
                    // Corner handles
                    cropHandles(for: rect)
                    
                    // Dimension label
                    Text("\(Int(rect.width / zoomLevel)) × \(Int(rect.height / zoomLevel))")
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
            }
            .compositingGroup()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if cropStart == nil {
                            cropStart = value.startLocation
                        }
                        cropEnd = value.location
                    }
            )
        }
        .frame(width: imageSize.width, height: imageSize.height)
    }
    
    @ViewBuilder
    private func cropHandles(for rect: CGRect) -> some View {
        let handleSize: CGFloat = 10
        let positions = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
        
        ForEach(0..<4, id: \.self) { index in
            Circle()
                .fill(CyberpunkTheme.accentCyan)
                .frame(width: handleSize, height: handleSize)
                .shadow(color: CyberpunkTheme.accentCyan, radius: 4)
                .position(positions[index])
        }
    }
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: CyberpunkTheme.spacingM) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: CyberpunkTheme.accentCyan))
                    .scaleEffect(1.5)
                
                Text("Processing crop...")
                    .font(CyberpunkTheme.fontHeadline)
                    .foregroundColor(CyberpunkTheme.textPrimary)
            }
            .padding(CyberpunkTheme.spacingL)
            .background(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                    .fill(CyberpunkTheme.backgroundSecondary)
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentCropRect: CGRect? {
        guard let start = cropStart, let end = cropEnd else { return nil }
        
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let width = abs(end.x - start.x)
        let height = abs(end.y - start.y)
        
        return CGRect(x: minX, y: minY, width: width, height: height)
    }
    
    // MARK: - Actions
    
    private func zoomIn() {
        zoomLevel = min(zoomLevel * 1.25, maxZoom)
    }
    
    private func zoomOut() {
        zoomLevel = max(zoomLevel / 1.25, minZoom)
    }
    
    private func startCrop() {
        isCropping = true
        cropStart = nil
        cropEnd = nil
    }
    
    private func cancelCrop() {
        isCropping = false
        cropStart = nil
        cropEnd = nil
    }
    
    private func applyCrop() {
        guard let screenshotId = screenshotId,
              let cropRect = currentCropRect else { return }
        
        // Convert screen coordinates to image coordinates
        let imageRect = CGRect(
            x: cropRect.origin.x / zoomLevel,
            y: cropRect.origin.y / zoomLevel,
            width: cropRect.width / zoomLevel,
            height: cropRect.height / zoomLevel
        )
        
        isProcessingCrop = true
        
        _Concurrency.Task {
            do {
                // Crop the screenshot
                let newScreenshotId = try screenshotManager.cropScreenshot(id: screenshotId, to: imageRect)
                
                // Load the cropped image and run OCR
                var extraction: TextExtraction? = nil
                if let cropped = screenshotManager.loadScreenshot(id: newScreenshotId) {
                    extraction = try? await textExtractor.extractText(from: cropped.image)
                }
                
                await MainActor.run {
                    isProcessingCrop = false
                    isCropping = false
                    onCrop?(newScreenshotId, extraction)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessingCrop = false
                    errorMessage = "Failed to crop: \(error.localizedDescription)"
                }
            }
        }
    }
}
