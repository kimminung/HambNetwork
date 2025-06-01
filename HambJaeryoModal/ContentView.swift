//
//  ContentView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showAddMenu      = false
    @State private var selectedMenuName = ""
    
    // SwiftData에서 모든 IngredientEntity를 최신순(createdAt)으로 가져옴
    @Query(sort: \IngredientEntity.createdAt, order: .reverse)
    private var allIngredients: [IngredientEntity]
    
    @Environment(\.modelContext) private var context
    
    /// 중복 없이 최신순으로 정리한 메뉴 이름 배열
    private var menuNames: [String] {
        var seen: Set<String> = []
        return allIngredients.compactMap { entity in
            guard !seen.contains(entity.menuName) else { return nil }
            seen.insert(entity.menuName)
            return entity.menuName
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── “나의 메뉴 +” 버튼 ──────────────────────────
                Button("나의 메뉴 +") {
                    showAddMenu = true
                }
                .font(.headline)
                .padding(.vertical, 10)
                
                // ── 메뉴 목록 (각 행을 MenuRowView로 분리) ─────────
                List {
                    ForEach(menuNames, id: \.self) { name in
                        MenuRowView(menuName: name)
                    }
                }
            }
            .navigationTitle("메뉴관리")
            
            // ── “나의 메뉴 +” → IngredientSheetView ─────────
            .navigationDestination(isPresented: $showAddMenu) {
                IngredientSheetView(
                    showAddMenu:      $showAddMenu,
                    selectedMenuName: $selectedMenuName
                )
            }
        }
    }
    
    // ── Helper: 해당 메뉴명에 속한 IngredientEntity 모두 fetch ─────────
    private func fetchEntities(for menuName: String) -> [IngredientEntity] {
        let predicate = #Predicate<IngredientEntity> { $0.menuName == menuName }
        let descriptor = FetchDescriptor<IngredientEntity>(
            predicate: predicate,
            sortBy:    [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Fetch error for \(menuName):", error)
            return []
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [IngredientEntity.self], inMemory: true)
}
