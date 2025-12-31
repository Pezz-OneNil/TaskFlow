import SwiftUI

/// Model selector dropdown for choosing Ollama model
/// Per Requirements 2B - LLM model selection
public struct ModelSelectorView: View {
    @ObservedObject var settingsManager: SettingsManager
    let llmSummarizer: LLMSummarizer
    
    @State private var isRefreshing = false
    
    public init(settingsManager: SettingsManager = .shared, llmSummarizer: LLMSummarizer) {
        self.settingsManager = settingsManager
        self.llmSummarizer = llmSummarizer
    }
    
    public var body: some View {
        Menu {
            // Model list
            if settingsManager.availableModels.isEmpty {
                Text("No models available")
                    .foregroundColor(CyberpunkTheme.textSecondary)
            } else {
                ForEach(settingsManager.availableModels, id: \.self) { model in
                    Button(action: {
                        settingsManager.selectedModel = model
                    }) {
                        HStack {
                            Text(model)
                            if settingsManager.selectedModel == model {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Refresh button
            Button(action: {
                refreshModels()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Models")
                }
            }
            .disabled(isRefreshing)
            
        } label: {
            HStack(spacing: CyberpunkTheme.spacingXS) {
                Image(systemName: "cpu")
                    .font(.system(size: 12))
                Text(displayModelName)
                    .font(CyberpunkTheme.fontCaption)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .foregroundColor(CyberpunkTheme.accentCyan)
            .padding(.horizontal, CyberpunkTheme.spacingS)
            .padding(.vertical, CyberpunkTheme.spacingXS)
            .background(
                Capsule()
                    .fill(CyberpunkTheme.accentCyan.opacity(0.2))
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
    
    private var displayModelName: String {
        if isRefreshing {
            return "Loading..."
        }
        if let selected = settingsManager.selectedModel {
            // Shorten long model names
            if selected.count > 15 {
                return String(selected.prefix(12)) + "..."
            }
            return selected
        }
        return "Select Model"
    }
    
    private func refreshModels() {
        isRefreshing = true
        _Concurrency.Task {
            _ = await llmSummarizer.refreshModels()
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}
