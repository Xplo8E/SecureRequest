import SwiftUI

struct NoteDetailView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading) {
            Text(note.title)
                .font(.title)
            Text(note.content)
                .font(.body)
        }
        .padding()
        .navigationTitle("Note Details")
    }
}