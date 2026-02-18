import SwiftUI

struct ClubPickerView: View {
    @EnvironmentObject private var appState: AppState
    let service = MoodService()

    @State private var clubs: [MoodService.Club] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading clubs...")
            } else if let error {
                Text(error).foregroundStyle(.red)
            } else {
                List(clubs) { club in
                    Button {
                        service.setSelectedClubId(club.id)
                        appState.selectedSite = Site(id: club.id, name: club.name)
                    } label: {
                        HStack {
                            Text(club.name)
                            Spacer()
                            if appState.selectedSite?.id == club.id {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Site")
        .task { await load() }
    }

    private func load() async {
        do {
            clubs = try await service.fetchClubs()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
