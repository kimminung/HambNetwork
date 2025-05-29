//
//  ContentView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showSheet = false
    @State private var showHistory = false
    
    var body: some View {
        NavigationStack {
            List {
                Button("나의 메뉴 +") {
                    showSheet = true
                }
                .font(.headline)
                
                NavigationLink("저장된 재료 내역", destination: IngredientHistoryView()).opacity(0)
            }
            .navigationDestination(isPresented: $showHistory) {
                IngredientHistoryView()
            }
            .navigationTitle("HambJaeryo")
            .sheet(isPresented: $showSheet) {
                IngredientSheetView(isPresented: $showSheet,
                                    showHistory: $showHistory)
            }

        }
    }
}


#Preview {
    ContentView().modelContainer(for: [IngredientEntity.self], inMemory: true)
}
