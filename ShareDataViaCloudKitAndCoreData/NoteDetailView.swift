//
//  NoteDetailView.swift
//  NoteDetailView
//
//  Created by Yang Xu on 2021/9/9.
//

import CloudKit
import CoreData
import Foundation
import SwiftUI
import UIKit

struct NoteDetailView: View {
    let note: Note
    private let stack = CoreDataStack.shared
    @State private var showShareController = false
    @FetchRequest private var memos: FetchedResults<Memo>
    @State var sharing = false

    init(note: Note) {
        self.note = note
        _memos = FetchRequest(entity: Memo.entity(),
                              sortDescriptors: [NSSortDescriptor(keyPath: \Memo.timestamp, ascending: false)],
                              predicate: NSPredicate(format: "%K = %@", #keyPath(Memo.note), note),
                              animation: .default)
    }

    var body: some View {
        List {
            ForEach(memos) { memo in
                Text(memo.text ?? "")
                    .swipeActions {
                        Button(role: .destructive) {
                            stack.deleteMemo(memo)
                        }
                        label: {
                            Label("Del", systemImage: "trash")
                        }
                        Button {
                            stack.changeMemoText(memo)
                        }
                        label: {
                            Label("Edit", systemImage: "square.and.pencil")
                        }
                        .tint(.orange)
                    }
            }
        }
        .toolbar {
            ToolbarItem {
                HStack {
                    if sharing {
                        ProgressView()
                    }

                    Button {
                        if isShared {
                            showShareController = true
                        } else {
                            // 先出现弹窗，后生成ckshare，用户体验会更好些
//                            openSharingController(note: note)
                            // 生成ckshare后弹窗
                            Task.detached {
                                await createShare(note)
                            }
                        }
                    }
                    label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button {
                        withAnimation {
                            stack.addMemo(note)
                        }
                    }
                    label: {
                        Image(systemName: "plus")
                    }
                }
                .controlGroupStyle(.navigation)
            }
        }
        .navigationTitle(note.name ?? "")
        .sheet(isPresented: $showShareController) {
            let share = stack.getShare(note)!
            CloudSharingView(share: share, container: stack.ckContainer, note: note)
                .ignoresSafeArea()
        }
    }

    private func openSharingController(note: Note) {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter { $0.isKeyWindow }.first

        let sharingController = UICloudSharingController {
            (_, completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) in

            stack.persistentContainer.share([note], to: nil) { _, share, container, error in
                if let actualShare = share {
                    note.managedObjectContext?.performAndWait {
                        actualShare[CKShare.SystemFieldKey.title] = note.name
                    }
                }
                completion(share, container, error)
            }
        }

        keyWindow?.rootViewController?.present(sharingController, animated: true)
    }

    private var isShared: Bool {
        stack.isShared(object: note)
    }
    
    func createShare(_ note: Note) async {
        sharing = true
        do {
            let (_, share, _) = try await stack.persistentContainer.share([note], to: nil)
            share[CKShare.SystemFieldKey.title] = note.name
        } catch {
            print("Faile to create share")
            sharing = false
        }
        sharing = false
        showShareController = true
    }
}
