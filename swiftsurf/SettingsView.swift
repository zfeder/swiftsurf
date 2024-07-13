//
//  SettingsView.swift
//  swiftsurf
//
//  Created by Federico Filì on 12/07/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("homePage") private var homePage: String = "https://www.google.com/"

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.headline)
            
            HStack {
                Text("Home Page:")
                TextField("Home Page", text: $homePage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            Spacer()
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}
