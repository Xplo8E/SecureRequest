import SwiftUI

struct AddNoteView: View {
    @EnvironmentObject var noteViewModel: NoteViewModel
    @State private var title = ""
    @State private var content = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextEditor(text: $content)
            }
            .navigationTitle("Add Note")
            .navigationBarItems(trailing: Button("Save") {
                saveNote()
            })
        }
    }
    
    private func saveNote() {
        noteViewModel.addNote(title: title, content: content)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddNoteView_Previews: PreviewProvider {
    static var previews: some View {
        AddNoteView()
            .environmentObject(NoteViewModel())
    }
}
