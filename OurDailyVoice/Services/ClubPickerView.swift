import SwiftUI

struct ClubPickerView: View {
    @State private var clubs: [MoodService.Club] = []
    @State private var selectedClubId: String?
    @State private var newClubName: String = ""

    var body: some View {
        List {
            ForEach(clubs) { club in
                Button(action: {
                    select(club)
                }) {
                    Text(club.name)
                }
                .buttonStyle(.plain)
            }

            Section("Add a New Club") {
                TextField("New club name", text: $newClubName)
                Button("Add Club") {
                    addClub()
                }
            }
        }
    }

    private func select(_ club: MoodService.Club) {
        selectedClubId = club.id
    }

    private func addClub() {
        guard !newClubName.isEmpty else { return }
        let newClub = MoodService.Club(id: UUID().uuidString, name: newClubName)
        clubs.append(newClub)
        newClubName = ""
    }
}
