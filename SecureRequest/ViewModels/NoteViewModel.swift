import Foundation

class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var message: String?
    
    func addNote(title: String, content: String) {
        NetworkManager.shared.request("/notes", method: "POST", body: ["title": title, "content": content]) { (result: Result<Note, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self.message = "Note successfully added"
                    self.fetchNotes()
                case .failure(let error):
                    self.message = "Error adding note: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateNote(_ note: Note) {
        NetworkManager.shared.request("/notes/\(note.id)", method: "PUT", body: ["title": note.title, "content": note.content]) { (result: Result<UpdateNoteResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.message = response.message
                    self.fetchNotes()
                case .failure(let error):
                    self.message = "Error updating note: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func deleteNote(_ note: Note) {
        NetworkManager.shared.request("/notes/\(note.id)", method: "DELETE") { (result: Result<DeleteNoteResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self.message = "Note successfully deleted"
                    self.fetchNotes()
                case .failure(let error):
                    self.message = "Error deleting note: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchNotes() {
        NetworkManager.shared.request("/notes", method: "GET") { (result: Result<[Note], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedNotes):
                    self.notes = fetchedNotes
                case .failure(let error):
                    self.message = "Failed to fetch notes: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct AddNoteResponse: Codable {
    let message: String
}

struct DeleteNoteResponse: Codable {
    let message: String
}

struct UpdateNoteResponse: Codable {
    let message: String
}

