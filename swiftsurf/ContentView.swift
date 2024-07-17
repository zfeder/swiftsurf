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

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { webViewStore.webView.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!webViewStore.webView.canGoBack)
                
                TextField("URL", text: $urlString, onCommit: loadURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: { webViewStore.webView.reload() }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            WebViewController(webView: webViewStore.webView)
                .cornerRadius(10)
                .padding(8)
            
            // Placeholder per il pulsante di ridimensionamento
            Color.clear.frame(height: 20)
        }
        .frame(minWidth: 320, minHeight: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            ResizeButton(),
            alignment: .bottomTrailing
        )
        .onAppear {
            loadURL()
        }
    }

    func loadURL() {
        if let url = URL(string: urlString) {
            webViewStore.webView.load(URLRequest(url: url))
        }
    }
}

struct ResizeButton: View {
    var body: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .foregroundColor(.gray)
            .frame(width: 20, height: 20)
            .background(Color.clear)
    }
}

struct WebViewController: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

class WebViewStore: ObservableObject {
    let webView: WKWebView
    
    init() {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.allowsMagnification = true
    }
}
