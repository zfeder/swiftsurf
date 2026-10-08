//
//  ContentView.swift
//  swiftsurf
//

import Combine
import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var browser = WebViewStore()
    @AppStorage("homePage") private var homePage = "https://www.google.com/"
    @State private var address = ""

    var body: some View {
        VStack(spacing: 0) {
            header

            WebViewController(webView: browser.webView)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .overlay(alignment: .bottomTrailing) {
                    ResizeHandle()
                        .frame(width: 28, height: 28)
                        .padding(.trailing, 8)
                        .padding(.bottom, 6)
                }
        }
        .frame(minWidth: ResizablePopover.minimumContentSize.width,
               idealWidth: 680,
               minHeight: ResizablePopover.minimumContentSize.height,
               idealHeight: 720)
        .background(.regularMaterial)
        .onAppear {
            guard address.isEmpty else { return }
            address = homePage
            loadAddress()
        }
        .onReceive(browser.$currentURL) { url in
            if let url, url.absoluteString != address {
                address = url.absoluteString
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                CircleIconButton(systemName: "chevron.left",
                                 isEnabled: browser.canGoBack) {
                    browser.webView.goBack()
                }
                CircleIconButton(systemName: "chevron.right",
                                 isEnabled: browser.canGoForward) {
                    browser.webView.goForward()
                }

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)

                    TextField("Search or enter website address", text: $address) {
                        loadAddress()
                    }
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit(loadAddress)

                    if browser.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                CircleIconButton(systemName: browser.isLoading ? "xmark" : "arrow.clockwise") {
                    if browser.isLoading {
                        browser.webView.stopLoading()
                    } else {
                        browser.webView.reload()
                    }
                }
            }

            HStack(spacing: 16) {
                Label("SwiftSurf", systemImage: "globe")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(browser.pageTitle.isEmpty ? "Ready to browse" : browser.pageTitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.regularMaterial)
    }

    private func loadAddress() {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let destination: String
        if trimmed.contains("://") {
            destination = trimmed
        } else if trimmed.contains(".") && !trimmed.contains(" ") {
            destination = "https://" + trimmed
        } else {
            let query = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            destination = "https://www.google.com/search?q=" + query
        }

        guard let url = URL(string: destination) else { return }
        address = destination
        browser.webView.load(URLRequest(url: url))
    }
}

private struct CircleIconButton: View {
    let systemName: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(isEnabled ? 0.08 : 0.03))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? .primary : .tertiary)
        .disabled(!isEnabled)
    }
}

struct WebViewController: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView { webView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

final class WebViewStore: NSObject, ObservableObject, WKNavigationDelegate {
    let webView: WKWebView
    @Published var currentURL: URL?
    @Published var pageTitle = ""
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false

    override init() {
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        super.init()
        webView.navigationDelegate = self
        webView.allowsMagnification = true
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateState()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateState()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateState()
        NSLog("SwiftSurf navigation error: %@", error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        updateState()
        NSLog("SwiftSurf provisional navigation error: %@", error.localizedDescription)
    }

    private func updateState() {
        currentURL = webView.url
        pageTitle = webView.title ?? ""
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
    }
}
