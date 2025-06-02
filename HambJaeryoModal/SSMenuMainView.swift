//
//  ContentView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/28/25.
//

import SwiftUI
import SwiftData

struct SSMenuMainView: View {
    @State private var showAddMenu      = false
    @State private var selectedMenuName = ""
    
    // SwiftData에서 모든 IngredientEntity를 최신순(createdAt)으로 가져옴
    @Query(sort: \SSIngredientEntity.createdAt, order: .reverse)
    private var allIngredients: [SSIngredientEntity]
    
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
                
                
                // ── 디버그: List가 렌더링될 때마다 allIngredients.count 찍기 ──
                VStack {
                    Text("🟣 Debug – allIngredients.count = \(allIngredients.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                    // 필요하다면 두 번 이상 찍히는지 확인하기 위해 onChange도 추가할 수 있습니다.
                }
                
                // ── 메뉴 목록 (각 행을 MenuRowView로 분리) ─────────
                List {
                    ForEach(menuNames, id: \.self) { name in
                        SSMenuRowViewCell(menuName: name)
                    }
                }
            }
            .navigationTitle("메뉴관리")
            
            // ── “나의 메뉴 +” → IngredientSheetView ─────────
            .navigationDestination(isPresented: $showAddMenu) {
                SSIngredientSheetView(
                    showAddMenu:      $showAddMenu,
                    selectedMenuName: $selectedMenuName
                )
            }
        }
        // ── 디버그: allIngredients의 변화 감지
        .onChange(of: allIngredients.count) { newCount in
            print("🔵 [Debug] allIngredients.count changed to \(newCount)")
        }
        // ── 디버그: selectedMenuName이 바뀌면 showAddMenu를 false로 (IngredientSheetView를 강제 팝)
        .onChange(of: selectedMenuName) { newValue in
            if !newValue.isEmpty {
                // “메뉴 등록” 직후: 이 코드를 통해 showAddMenu가 false가 되어
                // IngredientSheetView + IngredientResultView가 모두 팝됩니다.
                showAddMenu = false
            }
        }
    }
    
    // ── Helper: 해당 메뉴명에 속한 IngredientEntity 모두 fetch ─────────
    private func fetchEntities(for menuName: String) -> [SSIngredientEntity] {
        let predicate = #Predicate<SSIngredientEntity> { $0.menuName == menuName }
        let descriptor = FetchDescriptor<SSIngredientEntity>(
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
    SSMenuMainView()
        .modelContainer(for: [SSIngredientEntity.self], inMemory: true)
}
