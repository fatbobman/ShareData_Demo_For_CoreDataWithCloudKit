//
//  ContentView.swift
//  ShareDataViaCloudKitAndCoreData
//
//  Created by Yang Xu on 2021/9/9.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @FetchRequest(entity: Note.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Note.timestamp, ascending: false)], animation: .default)
    private var notes: FetchedResults<Note>
    private let stack = CoreDataStack.shared
    @State private var id = UUID()
    var body: some View {
        NavigationView {
            List {
                ForEach(notes) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    }
                    label: {
                        HStack {
                            Text(note.name ?? "")
                            if stack.isShared(object: note) {
                                if stack.isOwner(object: note) {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .id(id)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            withAnimation {
                                stack.deleteNote(note)
                            }
                        }
                        label: {
                            Label("Del", systemImage: "trash")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        withAnimation {
                            stack.addNote()
                        }
                    }
                    label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationTitle("ShareDemo")
            .onAppear{id = UUID()}
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
