import SwiftUI

struct EditNoteView: View {
    @EnvironmentObject var noteViewModel: NoteViewModel
    @State private var title: String
    @State private var content: String
    @Environment(\.presentationMode) var presentationMode
    
    let note: Note
    
    init(note: Note) {
        self.note = note
        _title = State(initialValue: note.title)
        _content = State(initialValue: note.content)
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextEditor(text: $content)
            }
            .navigationTitle("Edit Note")
            .navigationBarItems(trailing: Button("Save") {
                saveNote()
            })
        }
    }
    
    private func saveNote() {
        let updatedNote = Note(id: note.id, userId: note.userId, title: title, content: content, createdAt: note.createdAt, updatedAt: note.updatedAt)
        noteViewModel.updateNote(updatedNote)
        presentationMode.wrappedValue.dismiss()
    }
}
