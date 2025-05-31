//
//  ContentView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showAddMenu = false
    @State private var showHistory = false
    
    var body: some View {
        NavigationStack {
            List {
                Button("나의 메뉴 +") {
                    showAddMenu = true
                }
                .font(.headline)
                NavigationLink(
                    destination: IngredientSheetView(showHistory: $showHistory),
                    isActive: $showAddMenu
                ) { EmptyView() }
                
                NavigationLink(
                    "저장된 재료 내역",
                    destination: IngredientHistoryView()).opacity(0)
            }
            .navigationDestination(isPresented: $showHistory) {
                IngredientHistoryView()
            }
            .navigationTitle("HambJaeryo")
        }
    }
}


#Preview {
    ContentView().modelContainer(for: [IngredientEntity.self], inMemory: true)
}
