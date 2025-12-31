// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI

/// Visual overlay shown during drag operations
/// Per Requirements 6.1-6.6
public struct DropZoneOverlay: View {
    let dropState: DropState
    let progress: Double
    
    @State private var glowAnimation = false
    
    public init(dropState: DropState, progress: Double = 0.0) {
        self.dropState = dropState
        self.progress = progress
    }
    
    public var body: some View {
        Group {
            switch dropState {
            case .idle:
                EmptyView()
                
            case .hovering(let isValid):
                hoveringOverlay(isValid: isValid)
                
            case .processing:
                processingOverlay
                
            case .error(let message):
                errorOverlay(message: message)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: dropState)
    }
    
    // MARK: - Hovering Overlay
    
    private func hoveringOverlay(isValid: Bool) -> some View {
        ZStack {
            // Semi-transparent background
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: isValid 
                            ? [CyberpunkTheme.accentPurple.opacity(0.3), CyberpunkTheme.accentMagenta.opacity(0.2)]
                            : [Color.red.opacity(0.3), Color.red.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
            
            // Center content
            VStack(spacing: CyberpunkTheme.spacingM) {
                // Icon with glow
                ZStack {
                    // Glow effect
                    Image(systemName: isValid ? "envelope.badge.fill" : "xmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(isValid ? CyberpunkTheme.accentMagenta : .red)
                        .blur(radius: glowAnimation ? 20 : 10)
                        .opacity(0.6)
                    
                    // Main icon
                    Image(systemName: isValid ? "envelope.badge.fill" : "xmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(isValid ? CyberpunkTheme.accentMagenta : .red)
                }
                
                // Text
                Text(isValid ? "Drop email to create task" : "Unsupported file type")
                    .font(CyberpunkTheme.fontTitle)
                    .foregroundColor(CyberpunkTheme.textPrimary)
                
                if isValid {
                    Text("Supported: .eml files")
                        .font(CyberpunkTheme.fontCaption)
                        .foregroundColor(CyberpunkTheme.textSecondary)
                }
            }
            .padding(CyberpunkTheme.spacingXL)
            .background(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                    .fill(CyberpunkTheme.backgroundSecondary.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                            .stroke(
                                isValid ? CyberpunkTheme.accentMagenta : Color.red,
                                lineWidth: 2
                            )
                            .shadow(color: isValid ? CyberpunkTheme.accentMagenta : .red, radius: glowAnimation ? 15 : 8)
                    )
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glowAnimation = true
            }
        }
        .onDisappear {
            glowAnimation = false
        }
    }
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            // Semi-transparent background
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [CyberpunkTheme.accentCyan.opacity(0.3), CyberpunkTheme.accentPurple.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
            
            // Center content
            VStack(spacing: CyberpunkTheme.spacingM) {
                // Animated icon
                ZStack {
                    // Glow effect
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 64))
                        .foregroundColor(CyberpunkTheme.accentCyan)
                        .blur(radius: 15)
                        .opacity(0.6)
                    
                    // Main icon
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 64))
                        .foregroundColor(CyberpunkTheme.accentCyan)
                }
                
                Text("Processing email...")
                    .font(CyberpunkTheme.fontTitle)
                    .foregroundColor(CyberpunkTheme.textPrimary)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(CyberpunkTheme.backgroundSecondary)
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [CyberpunkTheme.accentCyan, CyberpunkTheme.accentMagenta],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(width: 200, height: 8)
                
                Text("\(Int(progress * 100))%")
                    .font(CyberpunkTheme.fontCaption)
                    .foregroundColor(CyberpunkTheme.textSecondary)
            }
            .padding(CyberpunkTheme.spacingXL)
            .background(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                    .fill(CyberpunkTheme.backgroundSecondary.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                            .stroke(CyberpunkTheme.accentCyan, lineWidth: 2)
                            .shadow(color: CyberpunkTheme.accentCyan, radius: 10)
                    )
            )
        }
    }
    
    // MARK: - Error Overlay
    
    private func errorOverlay(message: String) -> some View {
        ZStack {
            // Semi-transparent background
            Rectangle()
                .fill(Color.red.opacity(0.2))
                .ignoresSafeArea()
            
            // Center content
            VStack(spacing: CyberpunkTheme.spacingM) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(CyberpunkTheme.fontTitle)
                    .foregroundColor(CyberpunkTheme.textPrimary)
                
                Text(message)
                    .font(CyberpunkTheme.fontBody)
                    .foregroundColor(CyberpunkTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(CyberpunkTheme.spacingXL)
            .background(
                RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                    .fill(CyberpunkTheme.backgroundSecondary.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: CyberpunkTheme.cornerRadiusL)
                            .stroke(Color.red, lineWidth: 2)
                    )
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
struct DropZoneOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DropZoneOverlay(dropState: .hovering(isValid: true))
                .previewDisplayName("Hovering Valid")
            
            DropZoneOverlay(dropState: .hovering(isValid: false))
                .previewDisplayName("Hovering Invalid")
            
            DropZoneOverlay(dropState: .processing, progress: 0.65)
                .previewDisplayName("Processing")
            
            DropZoneOverlay(dropState: .error("Failed to parse email"))
                .previewDisplayName("Error")
        }
        .frame(width: 600, height: 400)
        .background(CyberpunkTheme.backgroundPrimary)
    }
}
#endif
