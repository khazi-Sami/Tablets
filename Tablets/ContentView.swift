//
//  ContentView.swift
//  Tablets
//
//  Created by sami Siddiqui on 14/05/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        AppRootView()
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleData.previewContainer)
}
