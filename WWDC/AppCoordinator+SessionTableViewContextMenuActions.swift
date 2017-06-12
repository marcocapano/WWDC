//
//  AppCoordinator+SessionTableViewContextMenuActions.swift
//  WWDC
//
//  Created by Soneé John on 6/11/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import Cocoa
import RealmSwift
import RxSwift
import ConfCore
import PlayerUI
import EventKit

extension AppCoordinator: SessionsTableViewControllerDelegate  {
    
    func sessionTableViewContextMenuActionWatch(viewModels: [SessionViewModel]) {
        backgroundUpdate(objects: viewModels.map({ $0.session })) { session in
            if let instance = session.instances.first {
                guard !instance.isCurrentlyLive else { return }
                
                guard instance.type == .session || instance.type == .video else { return }
            }
            
            session.setCurrentPosition(1, 1)
        }
    }
    
    func sessionTableViewContextMenuActionUnWatch(viewModels: [SessionViewModel]) {
        backgroundUpdate(objects: viewModels.map({ $0.session })) { session in
            session.resetProgress()
        }
    }
    
    func sessionTableViewContextMenuActionFavorite(viewModels: [SessionViewModel]) {
        backgroundUpdate(objects: viewModels.map({ $0.session })) { session in
            session.favorites.append(Favorite())
        }
    }
    
    func sessionTableViewContextMenuActionRemoveFavorite(viewModels: [SessionViewModel]) {
        backgroundUpdate(objects: viewModels.map({ $0.session })) { session in
            session.favorites.removeAll()
        }
    }
    
    func sessionTableViewContextMenuActionDownload(viewModels: [SessionViewModel]) {
        viewModels.forEach { viewModel in
            guard let videoAsset = viewModel.session.assets.filter({ $0.assetType == .hdVideo }).first else { return }
            
            DownloadManager.shared.download(videoAsset)
        }
    }
    
    func sessionTableViewContextMenuActionCancelDownload(viewModels: [SessionViewModel]) {
        viewModels.forEach { viewModel in
            guard let videoAsset = viewModel.session.assets.filter({ $0.assetType == .hdVideo }).first else { return }
            
            guard DownloadManager.shared.isDownloading(videoAsset.remoteURL) else { return }
                
            DownloadManager.shared.deleteDownload(for: videoAsset)
        }
    }
    
    private func backgroundUpdate<T: ThreadConfined>(objects inputObjects: [T], updateBlock: @escaping (T) -> Void) {
        let safeReferences = inputObjects.map({ ThreadSafeReference(to: $0) })
        let config = storage.realmConfig
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let realm = try Realm(configuration: config)
                let objects = safeReferences.flatMap({ realm.resolve($0) })
                
                try realm.write {
                    objects.forEach(updateBlock)
                }
            } catch {
                NSApp.presentError(error)
            }
        }
    }
    
}

