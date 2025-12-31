// ═══════════════════════════════════════════════════════════════════════════════
// TaskFlow - Intelligent Task Management for macOS
// © 2025 Pezz. All rights reserved.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI
import UniformTypeIdentifiers

/// Delegate for handling email file drops
/// Per Requirements 1.1-1.7
public struct EmailDropDelegate: DropDelegate {
    let dropHandler: EmailDropHandler
    let onDropComplete: ([EmailDropResult]) -> Void
    
    public init(dropHandler: EmailDropHandler, onDropComplete: @escaping ([EmailDropResult]) -> Void) {
        self.dropHandler = dropHandler
        self.onDropComplete = onDropComplete
    }
    
    public func validateDrop(info: DropInfo) -> Bool {
        guard dropHandler.isEnabled else { return false }
        
        // Check if any items are file URLs
        return info.hasItemsConforming(to: [.fileURL])
    }
    
    public func dropEntered(info: DropInfo) {
        guard dropHandler.isEnabled else { return }
        
        // Check if the files are .eml files
        let hasEML = hasEMLFiles(info: info)
        
        DispatchQueue.main.async {
            dropHandler.dropState = .hovering(isValid: hasEML)
        }
    }
    
    public func dropUpdated(info: DropInfo) -> DropProposal? {
        guard dropHandler.isEnabled else {
            return DropProposal(operation: .forbidden)
        }
        
        let hasEML = hasEMLFiles(info: info)
        return DropProposal(operation: hasEML ? .copy : .forbidden)
    }
    
    public func dropExited(info: DropInfo) {
        DispatchQueue.main.async {
            dropHandler.clearHoverState()
        }
    }
    
    public func performDrop(info: DropInfo) -> Bool {
        guard dropHandler.isEnabled else { return false }
        
        let providers = info.itemProviders(for: [.fileURL])
        
        guard !providers.isEmpty else { return false }
        
        // Process the drop asynchronously
        _Concurrency.Task {
            let success = await dropHandler.handleDrop(providers: providers)
            
            if success {
                await MainActor.run {
                    onDropComplete(dropHandler.lastResults)
                }
            }
        }
        
        return true
    }
    
    /// Check if the drop contains .eml files
    private func hasEMLFiles(info: DropInfo) -> Bool {
        // We can't easily check file extensions during drag,
        // so we accept any file URL and validate on drop
        return info.hasItemsConforming(to: [.fileURL])
    }
}
