//
//  UsersView.swift
//  NetworkingSampleApp
//
//  Created by Matej Molnár on 07.12.2023.
//

import SwiftUI

struct UsersView: View {
    @StateObject private var viewModel = UsersViewModel()

    @State private var fromUserID: Int = 1
    @State private var toUserID: Int = 3
    @State private var parallelise = false
    @State private var userName: String = ""
    @State private var userJob: String = ""

    var body: some View {
        Form {
            getUserView

            createUserView
        }
        .navigationTitle("Users")
    }
}

private extension UsersView {
    var getUserView: some View {
        Group {
            Section {
                HStack {
                    Text("From:")

                    TextField("From user ID", value: $fromUserID, formatter: NumberFormatter())
                }

                HStack {
                    Text("To:")

                    TextField("To user ID", value: $toUserID, formatter: NumberFormatter())
                }

                Toggle("Parallelise", isOn: $parallelise)
            } header: {
                Text("Get User by ID")
            } footer: {
                Button("Get Users") {
                    viewModel.getUsers(
                        in: fromUserID...toUserID, 
                        parallelFetch: parallelise
                    )
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            
            if !viewModel.users.isEmpty {
                Section("Users") {
                    ForEach(viewModel.users) { user in
                        userCell(user)
                    }
                }
            }
        }
    }

    var createUserView: some View {
        Group {
            Section {
                TextField("Name", text: $userName)
                TextField("Job", text: $userJob)
            } header: {
                Text("Create User with parameters")
            } footer: {
                Button("Create User") {
                    viewModel.createUser(name: userName, job: userJob)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }

            if let createdUser = viewModel.createdUser {
                Section("Created User") {
                    Text("ID: \(createdUser.id)")
                    Text("Name: \(createdUser.name)")
                    Text("Job: \(createdUser.job)")
                    Text("Created at: \(createdUser.createdAt.formatted())")
                }
            }
        }
    }

    func userCell(_ user: User) -> some View {
        HStack(alignment: .center) {
            AsyncImage(url: user.avatarURL) { image in
                image
                    .resizable()
            } placeholder: {
                Color.gray
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(user.firstName + " " + user.lastName)
                    .font(.subheadline)

                Text(user.email)
                    .font(.footnote)
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    UsersView()
}
