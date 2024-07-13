//
//  ContentView.swift
//  Navigator
//
//  Created by Federico Filì on 12/07/24.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State private var urlString: String = "https://www.google.com/"
    @StateObject private var webViewStore = WebViewStore()
    @AppStorage("homePage") private var homePage: String = "https://www.google.com/"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(PlainButtonStyle())
                
                TextField("URL", text: $urlString, onCommit: { loadURL() })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: { reloadPage() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            WebViewController(webView: webViewStore.webView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Spacer()
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .foregroundColor(.gray)
                    .padding(5)
            }
        }
        .frame(minWidth: 320, minHeight: 400)
        .onAppear {
            loadURL(urlString: homePage)
        }
    }

    func loadURL(urlString: String? = nil) {
        if let urlString = urlString, let url = URL(string: urlString) {
            webViewStore.loadUrl(url)
        } else if let url = URL(string: self.urlString) {
            webViewStore.loadUrl(url)
        }
    }

    func reloadPage() {
        webViewStore.webView.reload()
    }

    func goBack() {
        if webViewStore.webView.canGoBack {
            webViewStore.webView.goBack()
        }
    }

    func goHome() {
        loadURL(urlString: homePage)
    }

    func setHomePage() {
        homePage = webViewStore.webView.url?.absoluteString ?? homePage
    }
}

struct WebViewController: NSViewControllerRepresentable {
    let webView: WKWebView

    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        viewController.view = webView
        return viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

class WebViewStore: ObservableObject {
    @Published var webView: WKWebView

    init() {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15"
        self.webView.configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        
        self.webView.autoresizingMask = [.width, .height]
    }

    func loadUrl(_ url: URL) {
        webView.load(URLRequest(url: url))
    }
}
