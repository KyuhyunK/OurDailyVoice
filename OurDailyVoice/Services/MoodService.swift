//
//  MoodService.swift
//  OurDailyVoice
//
//  Created by Kyu Kim on 1/14/26.
//

// Stores JSON from MoodEntry to Firebase

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class MoodService {
    struct Club: Identifiable, Hashable, Codable {
        var id: String
        var name: String
    }

    // Premade clubs available by default
    private let defaultClubs: [Club] = [
        Club(id: "aj", name: "Andrew Jackson"),
        Club(id: "Chad", name: "Chadwell"),
        Club(id: "EEP", name: "East End Prep"),
        Club(id: "EV", name: "Eagle View"),
        Club(id: "FV", name: "Fair View"),
        Club(id: "Fr", name: "Franklin"),
        Club(id: "GG", name: "Glengarry"),
        Club(id: "NB", name: "Neely's Bend"),
        Club(id: "PT", name: "Preston Taylor"),
        Club(id: "Shw", name: "Shwab"),
        Club(id: "Val", name: "Valor")
    ]

    private let db = Firestore.firestore()

    private let selectedClubDefaultsKey = "SelectedClubId"

    // We store clubs under: clubs/{clubId}
    private func clubsCollection() -> CollectionReference {
        db.collection("clubs")
    }

    // Persist and access the user's selected club
    func setSelectedClubId(_ clubId: String?) {
        let defaults = UserDefaults.standard
        if let clubId {
            defaults.set(clubId, forKey: selectedClubDefaultsKey)
        } else {
            defaults.removeObject(forKey: selectedClubDefaultsKey)
        }
    }

    func getSelectedClubId() -> String? {
        UserDefaults.standard.string(forKey: selectedClubDefaultsKey)
    }

    var selectedClubId: String? { getSelectedClubId() }

    // Fetch list of clubs: built-in defaults plus any created in Firestore
    func fetchClubs() async throws -> [Club] {
        // Start with defaults
        var clubs = defaultClubs
        // Fetch custom clubs from Firestore
        let snapshot = try await clubsCollection().getDocuments()
        for doc in snapshot.documents {
            let data = doc.data()
            let name = (data["name"] as? String) ?? doc.documentID
            let club = Club(id: doc.documentID, name: name)
            // Avoid duplicates if an id matches a default
            if clubs.contains(where: { $0.id == club.id }) == false {
                clubs.append(club)
            }
        }
        // Sort by name for a stable UI
        clubs.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return clubs
    }

    // Create a new custom club in Firestore and return it
    @discardableResult
    func addClub(name: String) async throws -> Club {
        // Create a new document with auto id
        let ref = clubsCollection().document()
        try await ref.setData([
            "name": name,
            "createdAt": FieldValue.serverTimestamp()
        ])
        let club = Club(id: ref.documentID, name: name)
        // Optionally select it immediately
        setSelectedClubId(club.id)
        return club
    }

    // We store club moods under: clubs/{clubId}/moods/{autoId}
    private func clubMoodsCollection(clubId: String) -> CollectionReference {
        db.collection("clubs").document(clubId).collection("moods")
    }

    /// Ensures we have a user identity without a login screen.
    func ensureSignedIn() async throws -> String {
        if let user = Auth.auth().currentUser { return user.uid }
        let result = try await Auth.auth().signInAnonymously()
        return result.user.uid
    }

    func addMood(clubId: String, emoji: String, value: Int, day: Date) async throws {
        let ref = clubMoodsCollection(clubId: clubId).document()
        do {
            try await ref.setData([
                "emoji": emoji,
                "value": value,
                "day": Timestamp(date: Calendar.current.startOfDay(for: day)),
                "timestamp": FieldValue.serverTimestamp()
            ])
            print("[Firestore] wrote: clubs/\(clubId)/moods/\(ref.documentID)")
        } catch {
            print("[Firestore] WRITE FAILED:", error.localizedDescription)
            throw error
        }
    }

    // Convenience: add mood using the persisted selected club
    func addMoodUsingSelectedClub(emoji: String, value: Int, day: Date) async throws {
        guard let clubId = selectedClubId else {
            throw NSError(domain: "MoodService", code: 400, userInfo: [NSLocalizedDescriptionKey: "No club selected. Set a club before logging moods."])
        }
        try await addMood(clubId: clubId, emoji: emoji, value: value, day: day)
    }

    func fetchMoodsForDay(clubId: String, day: Date) async throws -> [MoodEntry] {
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)

        let snap = try await clubMoodsCollection(clubId: clubId)
            .whereField("day", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("day", isLessThan: Timestamp(date: end))
            .order(by: "timestamp", descending: true)
            .getDocuments(source: .server)

        return snap.documents.compactMap { doc in
            let data = doc.data()
            guard
                let emoji = data["emoji"] as? String,
                let value = data["value"] as? Int,
                let dayTS = data["day"] as? Timestamp,
                let timeTS = data["timestamp"] as? Timestamp
            else { return nil }

            return MoodEntry(
                id: doc.documentID,
                emoji: emoji,
                value: value,
                timestamp: timeTS.dateValue(),
                day: dayTS.dateValue()
            )
        }
    }

    // Convenience: fetch moods for the selected club
    func fetchMoodsForDayUsingSelectedClub(day: Date) async throws -> [MoodEntry] {
        guard let clubId = selectedClubId else {
            throw NSError(domain: "MoodService", code: 400, userInfo: [NSLocalizedDescriptionKey: "No club selected. Set a club before fetching moods."])
        }
        return try await fetchMoodsForDay(clubId: clubId, day: day)
    }
}
