//
//  TorrentListItem.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 29/10/2023.
//

import LibTorrent
import MvvmFoundation
import SwiftUI

struct TorrentListItemView: MvvmSwiftUICellProtocol {
    typealias ViewModel = TorrentListItemViewModel

    @ObservedObject var viewModel: TorrentListItemViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.title)
                .foregroundStyle(EFBTheme.primaryText)
                .font(.subheadline.weight(.semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text(String(viewModel.progressText))
                    .font(EFBTheme.numbers(.footnote))
                    .foregroundStyle(EFBTheme.secondaryText)
                HStack(spacing: 8) {
                    Text(viewModel.state.name)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(viewModel.state.efbColor)
                    if !viewModel.metricsText.isEmpty {
                        Text(viewModel.metricsText)
                            .font(EFBTheme.numbers(.footnote))
                            .foregroundStyle(EFBTheme.secondaryText)
                    }
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            ProgressView(value: viewModel.progress)
                .tint(viewModel.state.efbColor)
        }
        .swipeActions {
            Button(role: .destructive) {
                viewModel.removeTorrent()
            } label: {
                Image(systemName: "trash")
            }
        }
    }

    static let registration: UICollectionView.CellRegistration<UICollectionViewListCell, ViewModel> = .init { cell, _, itemIdentifier in
        cell.contentConfiguration = UIHostingConfiguration {
            Self(viewModel: itemIdentifier)
        }

        var config: UIBackgroundConfiguration
        if #available(iOS 18.0, visionOS 2.0, *) {
            config = .listCell()
        } else {
            config = .listPlainCell()
        }

        config.backgroundColorTransformer = .init { color in
            guard !cell.isHighlighted, !cell.isSelected
            else { return color }

            return .clear
        }
        cell.backgroundConfiguration = config
        cell.accessories = [.disclosureIndicator(displayed: .whenNotEditing), .multiselect(displayed: .whenEditing)]
    }
}
