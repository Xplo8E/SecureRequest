// import SwiftUI

// struct AddEditNoteView: View {
//     @EnvironmentObject var noteViewModel: NoteViewModel
//     @State private var title: String
//     @State private var content: String
//     @State private var isSaving = false
//     @State private var showError = false
//     @State private var errorMessage = ""
//     @Environment(\.presentationMode) var presentationMode
    
//     let note: Note?
    
//     init(note: Note? = nil) {
//         self.note = note
//         _title = State(initialValue: note?.title ?? "")
//         _content = State(initialValue: note?.content ?? "")
//     }
    
//     var body: some View {
//         NavigationView {
//             Form {
//                 TextField("Title", text: $title)
//                 TextEditor(text: $content)
//             }
//             .navigationTitle(note == nil ? "Add Note" : "Edit Note")
//             .navigationBarItems(
//                 leading: Button("Cancel") {
//                     presentationMode.wrappedValue.dismiss()
//                 },
//                 trailing: Button("Save") {
//                     saveNote()
//                 }
//             )
//             .disabled(isSaving)
//             .overlay(
//                 Group {
//                     if isSaving {
//                         ProgressView()
//                     }
//                 }
//             )
//         }
//         .alert(isPresented: $showError) {
//             Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
//         }
//     }
    
//     private func saveNote() {
//         isSaving = true
//         if let existingNote = note {
//             // Update existing note
//             let updatedNote = Note(id: existingNote.id, title: title, content: content)
//             noteViewModel.updateNote(updatedNote) { result in
//                 DispatchQueue.main.async {
//                     handleSaveResult(result)
//                 }
//             }
//         } else {
//             // Add new note
//             let newNote = Note(id: UUID(), title: title, content: content)
//             noteViewModel.addNote(newNote) { result in
//                 DispatchQueue.main.async {
//                     handleSaveResult(result)
//                 }
//             }
//         }
//     }
    
//     private func handleSaveResult(_ result: Result<Void, Error>) {
//         isSaving = false
//         switch result {
//         case .success:
//             presentationMode.wrappedValue.dismiss()
//         case .failure(let error):
//             errorMessage = error.localizedDescription
//             showError = true
//         }
//     }
// }

// struct AddEditNoteView_Previews: PreviewProvider {
//     static var previews: some View {
//         AddEditNoteView()
//             .environmentObject(NoteViewModel())
//     }
// }