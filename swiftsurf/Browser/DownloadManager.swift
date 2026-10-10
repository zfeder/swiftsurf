//
//  DownloadManager.swift
//  swiftsurf
//

import AppKit
import Observation
import WebKit

@Observable
final class DownloadItem: Identifiable {
    enum State: Equatable {
        case downloading
        case finished
        case failed(String)
        case cancelled
    }

    let id = UUID()
    var filename: String
    var destination: URL?
    var fractionCompleted = 0.0
    var state = State.downloading

    @ObservationIgnored fileprivate weak var download: WKDownload?
    @ObservationIgnored fileprivate var progressObservation: NSKeyValueObservation?

    init(filename: String) {
        self.filename = filename
    }
}

/// Saves WebKit downloads straight to ~/Downloads and tracks their progress.
@Observable
final class DownloadManager {
    private(set) var items: [DownloadItem] = []
    @ObservationIgnored private var delegates: [UUID: DownloadDelegate] = [:]

    var activeCount: Int {
        items.filter { $0.state == .downloading }.count
    }

    func track(_ download: WKDownload) {
        let item = DownloadItem(filename: download.originalRequest?.url?.lastPathComponent ?? "download")
        item.download = download
        item.progressObservation = download.progress.observe(\.fractionCompleted) { [weak item] progress, _ in
            let fraction = progress.fractionCompleted
            DispatchQueue.main.async { item?.fractionCompleted = fraction }
        }
        let delegate = DownloadDelegate(item: item) { [weak self] item in
            item.progressObservation = nil
            self?.delegates[item.id] = nil
        }
        delegates[item.id] = delegate
        download.delegate = delegate
        items.insert(item, at: 0)
    }

    func cancel(_ item: DownloadItem) {
        item.download?.cancel { _ in }
        item.state = .cancelled
    }

    func reveal(_ item: DownloadItem) {
        guard let destination = item.destination else { return }
        NSWorkspace.shared.activateFileViewerSelecting([destination])
    }

    func open(_ item: DownloadItem) {
        guard let destination = item.destination else { return }
        NSWorkspace.shared.open(destination)
    }

    func clearInactive() {
        items.removeAll { $0.state != .downloading }
    }

    static var downloadsDirectory: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    }

    /// `directory/filename`, or `name 2.ext`, `name 3.ext`… when that file already exists.
    static func uniqueDestination(for filename: String, in directory: URL,
                                  fileExists: (String) -> Bool = FileManager.default.fileExists(atPath:)) -> URL {
        let safeName = filename.replacingOccurrences(of: "/", with: "-")
        let base = (safeName as NSString).deletingPathExtension
        let ext = (safeName as NSString).pathExtension
        var candidate = directory.appendingPathComponent(safeName)
        var counter = 2
        while fileExists(candidate.path) {
            let name = ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)"
            candidate = directory.appendingPathComponent(name)
            counter += 1
        }
        return candidate
    }
}

private final class DownloadDelegate: NSObject, WKDownloadDelegate {
    private let item: DownloadItem
    private let onComplete: (DownloadItem) -> Void

    init(item: DownloadItem, onComplete: @escaping (DownloadItem) -> Void) {
        self.item = item
        self.onComplete = onComplete
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let destination = DownloadManager.uniqueDestination(for: suggestedFilename,
                                                            in: DownloadManager.downloadsDirectory)
        item.filename = destination.lastPathComponent
        item.destination = destination
        completionHandler(destination)
    }

    func downloadDidFinish(_ download: WKDownload) {
        item.fractionCompleted = 1
        item.state = .finished
        onComplete(item)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        if item.state != .cancelled {
            item.state = .failed(error.localizedDescription)
        }
        onComplete(item)
    }
}
