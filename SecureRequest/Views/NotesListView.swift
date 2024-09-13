import SwiftUI

struct NotesListView: View {
    @EnvironmentObject var noteViewModel: NoteViewModel
    @State private var isAddingNote = false
    @State private var noteToEdit: Note?
    @State private var showMessage = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(noteViewModel.notes) { note in
                    NoteRow(note: note)
                        .onTapGesture {
                            noteToEdit = note
                        }
                }
                .onDelete(perform: deleteNotes)
            }
            .navigationTitle("Notes")
            .navigationBarItems(trailing: Button(action: {
                isAddingNote = true
            }) {
                Image(systemName: "plus")
            })
            .alert(isPresented: $showMessage) {
                Alert(title: Text("Message"), message: Text(noteViewModel.message ?? ""), dismissButton: .default(Text("OK")))
            }
        }
        .sheet(isPresented: $isAddingNote) {
            AddNoteView()
        }
        .sheet(item: $noteToEdit) { note in
            EditNoteView(note: note)
        }
        .onAppear {
            noteViewModel.fetchNotes()
        }
        .onChange(of: noteViewModel.message) { newValue in
            if newValue != nil {
                showMessage = true
            }
        }
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            let note = noteViewModel.notes[index]
            noteViewModel.deleteNote(note)
        }
    }
}

struct NoteRow: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(note.title)
                .font(.headline)
            Text(note.content)
                .font(.subheadline)
                .lineLimit(2)
        }
    }
}