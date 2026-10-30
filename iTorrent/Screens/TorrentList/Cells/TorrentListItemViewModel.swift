//
//  TorrentListItemViewModel.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import Combine
import LibTorrent
import MvvmFoundation
import SwiftUI

class TorrentListItemViewModel: BaseViewModelWith<TorrentHandle>, MvvmSelectableProtocol, ObservableObject, Identifiable {
    var torrentHandle: TorrentHandle!
    var selectAction: (() -> Void)?
    var id: ObjectIdentifier { .init(torrentHandle) }

    @Published var title: String = ""
    @Published var progressText: String = ""
    @Published var state: TorrentHandle.State = .paused
    @Published var metricsText: String = ""
    @Published var progress: Double = 0

    override func prepare(with model: TorrentHandle) {
        torrentHandle = model
        updateUI()

        disposeBag.bind {
            torrentHandle.updatePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateUI()
                }
        }

        selectAction = { [unowned self] in
            navigate(to: TorrentDetailsViewModel.self, with: model, by: .detail(asRoot: true))
        }
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func removeTorrent() {
        alert(title: %"torrent.remove.title", message: torrentHandle.snapshot.name, actions: [
            .init(title: %"torrent.remove.action.dropData", style: .destructive, action: { [unowned self] in
                TorrentService.shared.removeTorrent(by: torrentHandle.snapshot.infoHashes, deleteFiles: true)
            }),
            .init(title: %"torrent.remove.action.keepData", style: .default, action: { [unowned self] in
                TorrentService.shared.removeTorrent(by: torrentHandle.snapshot.infoHashes, deleteFiles: false)
            }),
            .init(title: %"common.cancel", style: .cancel, isPrimary: true)
        ])
    }
}

private extension TorrentListItemViewModel {
    func updateUI() {
        let snapshot = torrentHandle.snapshot
        let percent = "\(String(format: "%.2f", snapshot.progress * 100))%"
        title = snapshot.name
        progressText = %"\(snapshot.totalWantedDone.bitrateToHumanReadable) of \(snapshot.totalWanted.bitrateToHumanReadable) (\(percent))"
        state = snapshot.friendlyState
        switch state {
        case .downloading:
            metricsText = "↓ \(snapshot.downloadRate.bitrateToHumanReadable)/s · \(snapshot.timeRemains)"
        case .seeding:
            metricsText = "↑ \(snapshot.uploadRate.bitrateToHumanReadable)/s"
        default:
            metricsText = ""
        }
        progress = snapshot.progress
    }
}
