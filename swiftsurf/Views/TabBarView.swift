//
//  TabBarView.swift
//  swiftsurf
//

import SwiftUI

struct TabBarView: View {
    let session: BrowserSession
    let strings: AppStrings
    @Binding var showingSettings: Bool

    var body: some View {
        HStack(spacing: 5) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(session.tabs) { tab in
                            TabButton(tab: tab,
                                      isSelected: !showingSettings && session.selectedTabID == tab.id,
                                      canClose: session.tabs.count > 1,
                                      strings: strings,
                                      select: {
                                          showingSettings = false
                                          session.selectedTabID = tab.id
                                      },
                                      close: { session.close(tab) })
                                .id(tab.id)
                                .draggable(tab.id.uuidString)
                                .dropDestination(for: String.self) { items, _ in
                                    guard let id = items.first.flatMap(UUID.init(uuidString:)) else { return false }
                                    session.moveTab(id, before: tab.id)
                                    return true
                                }
                        }
                    }
                }
                .onChange(of: session.selectedTabID) { _, id in
                    if let id {
                        withAnimation { proxy.scrollTo(id) }
                    }
                }
            }

            Button {
                showingSettings = false
                session.addTab()
                BrowserCommand.focusAddress.post()
            } label: {
                Image(systemName: "plus")
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(strings["newTab"])

            Button {
                showingSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .frame(width: 24, height: 24)
                    .background(showingSettings ? Color.primary.opacity(0.1) : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .help(strings["settings"])

            if session.privateMode {
                Label(strings["private"], systemImage: "eye.slash")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.purple)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }
}

private struct TabButton: View {
    let tab: BrowserTab
    let isSelected: Bool
    let canClose: Bool
    let strings: AppStrings
    let select: () -> Void
    let close: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            icon
            Text(tab.title.isEmpty ? strings["newTab"] : tab.title)
                .lineLimit(1)
                .frame(maxWidth: 140, alignment: .leading)
            if canClose {
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .frame(width: 14, height: 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(isSelected || isHovering ? 1 : 0.35)
                .help(strings["command.closeTab"])
            }
        }
        .font(.caption)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(isSelected ? Color.primary.opacity(0.1) : isHovering ? Color.primary.opacity(0.05) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
        .onHover { isHovering = $0 }
        .help(tab.displayURL?.absoluteString ?? tab.title)
        .contextMenu {
            Button(strings["command.closeTab"], action: close)
        }
    }

    @ViewBuilder
    private var icon: some View {
        if tab.isPrivate {
            Image(systemName: "eye.slash")
        } else if tab.isLoading {
            ProgressView().controlSize(.mini).frame(width: 14, height: 14)
        } else if let favicon = tab.favicon {
            Image(nsImage: favicon).resizable().interpolation(.high).frame(width: 14, height: 14)
        } else {
            Image(systemName: "globe")
        }
    }
}
