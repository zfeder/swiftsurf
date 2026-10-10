//
//  BrowserComponents.swift
//  swiftsurf
//

import SwiftUI
import WebKit

/// Hosts the selected tab's web view, swapping it in place when the selection changes.
struct WebViewContainer: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        install(webView, in: container)
        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        guard container.subviews.first !== webView else { return }
        install(webView, in: container)
    }

    private func install(_ webView: WKWebView, in container: NSView) {
        container.subviews.forEach { $0.removeFromSuperview() }
        webView.removeFromSuperview()
        webView.frame = container.bounds
        webView.autoresizingMask = [.width, .height]
        container.addSubview(webView)
    }
}

struct CircleIconButton: View {
    let systemName: String
    var isEnabled = true
    var help: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName).font(.system(size: 12, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(isEnabled ? 0.08 : 0.03))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? .primary : .tertiary)
        .disabled(!isEnabled)
        .help(help ?? "")
        .accessibilityLabel(help ?? systemName)
    }
}

struct LoadingProgressLine: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: proxy.size.width * max(0.05, min(progress, 1)))
                .animation(.easeOut(duration: 0.2), value: progress)
        }
        .frame(height: 2)
    }
}

struct NavigationErrorView: View {
    let strings: AppStrings
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark").font(.title2).foregroundStyle(.secondary)
            Text(strings["unable"]).font(.headline)
            Text(message).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).lineLimit(3)
            Button(strings["tryAgain"], action: retry).buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 12, y: 4)
    }
}

/// In-popover replacement for `alert()`, `confirm()` and `prompt()`; system alerts would close the popover.
struct JavaScriptDialogView: View {
    let dialog: JavaScriptDialog
    let strings: AppStrings
    let answer: (_ accepted: Bool, _ text: String?) -> Void
    @State private var text = ""
    @FocusState private var textFieldIsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(format: strings["dialog.from"], dialog.host.isEmpty ? "—" : dialog.host))
                .font(.headline)
            ScrollView {
                Text(dialog.message)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 160)
            .fixedSize(horizontal: false, vertical: true)

            if case .prompt = dialog.kind {
                TextField("", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .focused($textFieldIsFocused)
                    .onSubmit { answer(true, text) }
            }

            HStack {
                Spacer()
                if dialog.kind != .alert {
                    Button(strings["cancel"]) { answer(false, nil) }
                        .keyboardShortcut(.cancelAction)
                }
                Button(strings["ok"]) { answer(true, text) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 16, y: 6)
        .onAppear {
            if case .prompt(let defaultText) = dialog.kind {
                text = defaultText
                textFieldIsFocused = true
            }
        }
    }
}
