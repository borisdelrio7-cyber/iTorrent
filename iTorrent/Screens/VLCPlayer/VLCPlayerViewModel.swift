//
//  VLCPlayerViewModel.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.03.2026.
//

import Foundation
import MvvmFoundation
import LibTorrent
import SwiftVLC

extension VLCPlayerViewModel {
    struct Config {
        let url: URL
        let torrentPair: (handle: TorrentHandle, fileIndex: Int)?
    }
}

class VLCPlayerViewModel: BaseViewModelWith<VLCPlayerViewModel.Config>, ObservableObject {
    private(set) var url: URL!
    private(set) var torrentPair: (handle: TorrentHandle, fileIndex: Int)?

    @Published var showOverlay: Bool = true
    @Published var segmentedProgress: [Double]?
    private var playbackTeardownHandler: (() -> Void)?

#if !os(visionOS)
    @Published var pipController: PiPController?
#endif

    override func prepare(with model: Config) {
        self.url = model.url
        self.torrentPair = model.torrentPair
        binding()
    }

    private func binding() {
        guard let torrentPair else { return }
        refreshSegmentedProgress()
        disposeBag.bind {
            torrentPair.handle.updatePublisher.sink { [weak self] update in
                guard let self else { return }
                refreshSegmentedProgress()
            }
        }
    }

    private func refreshSegmentedProgress() {
        guard let torrentPair else { return }
        let file = torrentPair.handle.snapshot.files[torrentPair.fileIndex]
        segmentedProgress = file.segmentedProgress
    }

    /// Fully downloaded subtitle files from the same torrent: next to the video, or inside a
    /// Subs/Subtitles folder (optionally with one folder per episode). When the folder has a single
    /// video every subtitle in it belongs to it; otherwise the file name must start with the video's.
    var externalSubtitleURLs: [URL] {
        guard let torrentPair, let root = torrentPair.handle.snapshot.downloadPath else { return [] }
        let files = torrentPair.handle.snapshot.files
        guard files.indices.contains(torrentPair.fileIndex) else { return [] }

        let videoPath = files[torrentPair.fileIndex].path as NSString
        let videoDir = videoPath.deletingLastPathComponent
        let videoName = (videoPath.lastPathComponent as NSString).deletingPathExtension.lowercased()
        let videosInDir = files.filter {
            let path = $0.path as NSString
            return path.deletingLastPathComponent == videoDir && Self.videoExtensions.contains(path.pathExtension.lowercased())
        }.count

        return files.filter { file in
            let path = file.path as NSString
            guard file.progress >= 1, Self.subtitleExtensions.contains(path.pathExtension.lowercased()) else { return false }

            let dir = path.deletingLastPathComponent
            let matchesName = path.lastPathComponent.lowercased().hasPrefix(videoName) || videosInDir <= 1
            if dir == videoDir { return matchesName }

            let prefix = videoDir.isEmpty ? "" : videoDir + "/"
            guard dir.hasPrefix(prefix) else { return false }
            let inner = dir.dropFirst(prefix.count).lowercased().split(separator: "/").map(String.init)
            guard let folder = inner.first, Self.subtitleFolders.contains(folder) else { return false }
            return matchesName || inner.dropFirst().contains(videoName)
        }
        .map { root.appending(path: $0.path) }
    }

    private static let subtitleExtensions: Set<String> = ["srt", "ass", "ssa", "vtt", "sub", "smi"]
    private static let subtitleFolders: Set<String> = ["sub", "subs", "subtitles", "subtitulos", "subtítulos"]
    private static let videoExtensions: Set<String> = ["mkv", "mp4", "m4v", "avi", "mov", "webm", "ts", "m2ts", "wmv", "flv", "mpg", "mpeg"]

    static func validateURL(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        guard url.isFileURL, (try? url.checkResourceIsReachable()) == true else { return false }

        let resourceValues = try? url.resourceValues(forKeys: [.isRegularFileKey])
        return resourceValues?.isRegularFile != false
    }

    static func canOpenInVLC(_ url: URL, timeoutMilliseconds: Int32 = 3_000) async -> Media? {
        guard validateURL(url), let media = try? Media(url: url) else { return nil }

        do {
            let metadata = try await media.parse(timeout: .milliseconds(Int64(timeoutMilliseconds)))
            if !media.tracks().isEmpty { return media }
            if (metadata.duration ?? media.duration)?.milliseconds ?? 0 > 0 { return media }
            return nil
        } catch {
            return nil
        }
    }

    static func canOpenInVLCSync(_ url: URL, timeoutMilliseconds: Int32 = 100) -> Media? {
        guard validateURL(url), let media = try? Media(url: url) else { return nil }
        return media
    }

    func registerPlaybackTeardownHandler(_ handler: @escaping () -> Void) {
        playbackTeardownHandler = handler
    }

    func requestPlaybackTeardown() {
        let handler = playbackTeardownHandler
        playbackTeardownHandler = nil
        handler?()
    }

    func clearPlaybackTeardownHandler() {
        playbackTeardownHandler = nil
    }
}
