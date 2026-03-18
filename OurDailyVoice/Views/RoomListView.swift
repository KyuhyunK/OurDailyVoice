//
//  RoomListView.swift
//  OurDailyVoice
//
//  Created by Kyu Kim on 3/18/26.
//

import SwiftUI

struct RoomListView: View {
    @EnvironmentObject private var appState: AppState
    let site: Site

    var body: some View {
        ZStack {
            Theme.bgGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Button {
                            Haptics.tap()
                            appState.selectedSite = nil
                            appState.selectedRoom = nil
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.white.opacity(Theme.cardOpacity))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Our Daily Voice")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(.white)

                        Text(site.name)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.95))

                        Text("Select a Room")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    if site.rooms.isEmpty {
                        Text("No rooms available yet.")
                            .foregroundStyle(.white)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(Theme.cardOpacity))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
                    } else {
                        VStack(spacing: 14) {
                            ForEach(site.rooms, id: \.self) { room in
                                Button {
                                    Haptics.tap()
                                    appState.selectedRoom = room
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(room)
                                                .font(.title3.weight(.semibold))
                                                .foregroundStyle(.white)

                                            Text(site.name)
                                                .font(.subheadline)
                                                .foregroundStyle(.white.opacity(0.8))
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .padding(20)
                                    .frame(maxWidth: .infinity)
                                    .background(.white.opacity(Theme.cardOpacity))
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.corner))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.corner)
                                            .stroke(.white.opacity(0.14), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
    }
}

#Preview {
    RoomListView(
        site: Site(
            id: "aj",
            name: "Andrew Jackson",
            rooms: ["Room 101", "Room 102", "Room 103"]
        )
    )
    .environmentObject(AppState())
}
