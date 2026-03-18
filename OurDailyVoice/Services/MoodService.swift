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

    // MARK: - Models

    struct Club: Identifiable, Hashable, Codable {
        var id: String
        var name: String
        var rooms: [String]
    }

    // MARK: - Defaults

    private let defaultClubs: [Club] = [
        Club(id: "aj", name: "Andrew Jackson", rooms: ["Room 101", "Room 102"]),
        Club(id: "Chad", name: "Chadwell", rooms: ["Room A", "Room B"]),
        Club(id: "EEP", name: "East End Prep", rooms: ["Room 1"]),
        Club(id: "EV", name: "Eagle View", rooms: ["Blue Room", "Green Room"]),
        Club(id: "FV", name: "Fair View", rooms: []),
        Club(id: "Fr", name: "Franklin", rooms: []),
        Club(id: "GG", name: "Glengarry", rooms: []),
        Club(id: "NB", name: "Neely's Bend", rooms: []),
        Club(id: "PT", name: "Preston Taylor", rooms: []),
        Club(id: "Shw", name: "Shwab", rooms: []),
        Club(id: "Val", name: "Valor", rooms: [])
    ]

    private lazy var db = Firestore.firestore()
    private let selectedClubDefaultsKey = "SelectedClubId"

    // MARK: - Club Selection

    private func clubsCollection() -> CollectionReference {
        db.collection(Constants.sitesCollection)
    }

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

    // MARK: - Clubs

    func fetchClubs() async throws -> [Club] {
        var clubs = defaultClubs

        let snapshot = try await clubsCollection().getDocuments()

        for doc in snapshot.documents {
            let data = doc.data()

            guard let name = data["name"] as? String, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }

            let rooms = (data["rooms"] as? [String]) ?? []
            let club = Club(id: doc.documentID, name: name, rooms: rooms)

            if let index = clubs.firstIndex(where: { $0.name.caseInsensitiveCompare(club.name) == .orderedSame }) {
                clubs[index] = club
            } else {
                clubs.append(club)
            }
        }

        clubs.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return clubs
    }

    @discardableResult
    func addClub(name: String, rooms: [String] = []) async throws -> Club {
        let ref = clubsCollection().document()

        try await ref.setData([
            "name": name,
            "rooms": rooms,
            "createdAt": FieldValue.serverTimestamp()
        ])

        let club = Club(id: ref.documentID, name: name, rooms: rooms)
        setSelectedClubId(club.id)
        return club
    }

    // MARK: - Auth

    func ensureSignedIn() async throws -> String {
        if let user = Auth.auth().currentUser {
            return user.uid
        }

        let result = try await Auth.auth().signInAnonymously()
        return result.user.uid
    }

    // MARK: - Individual Mood Logging

    private func clubMoodsCollection(clubId: String) -> CollectionReference {
        db.collection(Constants.sitesCollection)
            .document(clubId)
            .collection("moods")
    }

    func addMood(clubId: String, emoji: String, value: Int, day: Date) async throws {
        let ref = clubMoodsCollection(clubId: clubId).document()

        try await ref.setData([
            "emoji": emoji,
            "value": value,
            "day": Timestamp(date: Calendar.current.startOfDay(for: day)),
            "timestamp": FieldValue.serverTimestamp()
        ])

        print("[Firestore] wrote: \(Constants.sitesCollection)/\(clubId)/moods/\(ref.documentID)")
    }

    func addMoodUsingSelectedClub(emoji: String, value: Int, day: Date) async throws {
        guard let clubId = selectedClubId else {
            throw NSError(domain: "MoodService", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "No club selected."
            ])
        }

        try await addMood(clubId: clubId, emoji: emoji, value: value, day: day)
    }

    func fetchMoodsForDay(clubId: String, day: Date) async throws -> [MoodEntry] {
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!

        let snap = try await clubMoodsCollection(clubId: clubId)
            .whereField("day", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("day", isLessThan: Timestamp(date: end))
            .order(by: "day")
            .order(by: "timestamp", descending: true)
            .getDocuments(source: .server)

        return snap.documents.compactMap { doc -> MoodEntry? in
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
    
    func fetchMoodsForDayUsingSelectedClub(day: Date) async throws -> [MoodEntry] {
        guard let clubId = selectedClubId else {
            throw NSError(domain: "MoodService", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "No club selected."
            ])
        }

        return try await fetchMoodsForDay(clubId: clubId, day: day)
    }

    // MARK: - Aggregated Session Logging

    private func sessionDoc(clubId: String, day: Date) -> DocumentReference {
        let dayId = SessionDay.dayId(for: day)

        return db.collection(Constants.sitesCollection)
            .document(clubId)
            .collection("sessions")
            .document(dayId)
    }

    func appendGroupMoodUsingSelectedClub(day: Date, mode: SessionMode, value: Int) async throws {
        guard let clubId = selectedClubId else {
            throw NSError(domain: "MoodService", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "No club selected."
            ])
        }

        let ref = sessionDoc(clubId: clubId, day: day)
        let dayStart = Calendar.current.startOfDay(for: day)

        _ = try await db.runTransaction { txn, errPtr in
            do {
                let snap = try txn.getDocument(ref)
                var data = snap.data() ?? [:]

                var enterValues = data["enterValues"] as? [Int] ?? []
                var leaveValues = data["leaveValues"] as? [Int] ?? []

                if mode == .enter {
                    enterValues.append(value)
                } else {
                    leaveValues.append(value)
                }

                func avg(_ xs: [Int]) -> Double? {
                    guard !xs.isEmpty else { return nil }
                    return Double(xs.reduce(0,+)) / Double(xs.count)
                }

                let enterAvg = avg(enterValues)
                let leaveAvg = avg(leaveValues)
                let delta = (enterAvg != nil && leaveAvg != nil) ? leaveAvg! - enterAvg! : nil

                data["day"] = Timestamp(date: dayStart)
                data["enterValues"] = enterValues
                data["leaveValues"] = leaveValues
                data["enterAvg"] = enterAvg as Any
                data["leaveAvg"] = leaveAvg as Any
                data["delta"] = delta as Any
                data["updatedAt"] = FieldValue.serverTimestamp()

                txn.setData(data, forDocument: ref, merge: true)

            } catch {
                errPtr?.pointee = error as NSError
            }

            return nil
        }
    }

    func fetchSessionDayUsingSelectedClub(day: Date) async throws -> SessionDay? {
        guard let clubId = selectedClubId else {
            throw NSError(domain: "MoodService", code: 400, userInfo: [
                NSLocalizedDescriptionKey: "No club selected."
            ])
        }

        let doc = try await sessionDoc(clubId: clubId, day: day).getDocument()
        guard doc.exists else { return nil }

        return SessionDay(doc: doc)
    }
}
