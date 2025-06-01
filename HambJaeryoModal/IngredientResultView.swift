//
//  IngredientResultView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/29/25.
//

import SwiftUI
import SwiftData

struct IngredientResultView: View {
    @Environment(\.modelContext) private var context
    
    
    @Binding var selectedMenuName: String
    @Binding var showAddMenu: Bool
    
    let menuName: String
    let menuPrice: String
    let image: UIImage?
    //    let parsedIngredients: [IngredientInfo]
    
    
    // AI가 파싱해준 초기 재료들을 이 State 배열로 복사하여 관리합니다.
    @State private var ingredients: [IngredientInfo]
    
    // “재료 추가하기” 시트를 띄우기 위한 플래그
    @State private var showAddSheet = false
    
    // 시트 안에서 입력할 새 재료의 임시 변수들
    @State private var newName: String = ""
    @State private var newAmount: String = ""
    @State private var newUnitPrice: String = ""
    
    
    private var totalCost: Int {
//        parsedIngredients.reduce(0) { $0 + $1.unitPrice }
        ingredients.reduce(0) { $0 + $1.unitPrice }
    }
    
    
    // 초기화 시 parsedIngredients를 ingredients에 복사
    init(
        selectedMenuName: Binding<String>,
        showAddMenu: Binding<Bool>,
        menuName: String,
        menuPrice: String,
        image: UIImage?,
        parsedIngredients: [IngredientInfo]
    ) {
        _selectedMenuName = selectedMenuName
        _showAddMenu = showAddMenu
        self.menuName = menuName
        self.menuPrice = menuPrice
        self.image = image
        // parsedIngredients를 State인 ingredients로 복사
        _ingredients = State(initialValue: parsedIngredients)
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            
            // ── 헤더 영역 ─────────────────────────────────────
            HStack(alignment: .top, spacing: 16) {
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "fork.knife.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .padding(12)
                                .foregroundColor(.orange)
                        )
                }
                
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(menuName)
                        .font(.headline)
                    Text("\(menuPrice)원")
                        .font(.title3).bold()
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            
            // ── 재료 리스트 ──────────────────────────────────
            List {
                //                ForEach(parsedIngredients) { ing in
                ForEach(ingredients) { ing in
                    HStack {
                        // 간단 아이콘 (재료 첫 글자 이모지 활용)
                        Text(String(ing.name.first ?? "🥘"))
                            .font(.system(size: 24))
                        
                        Text(ing.name)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(ing.amount)
                            .font(.subheadline)
                            .frame(width: 60, alignment: .trailing)
                        
                        Text("\(ing.unitPrice.formatted())원")
                            .font(.subheadline)
                            .frame(width: 70, alignment: .trailing)
                        
                        Image(systemName: "chevron.up")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .listRowSeparator(.hidden)
                }
                Button {
                    // 추가 로직 Hook
                    showAddSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("재료 추가하기")
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            
            Divider()
            
            
            // ── 하단 합계 + 등록 버튼 ────────────────────────
            VStack(spacing: 16) {
                Text("재료원가는 \(totalCost.formatted())원입니다")
                    .font(.subheadline)
                
                Button("메뉴 등록") {
                    saveMenuWithIngredients()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(
                Color(UIColor.systemBackground)
                    .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
            )
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("재료관리")
        
        .onAppear {
            print("🟡 [Debug] IngredientResultView 진입, parsedIngredients.count = \(ingredients.count)")
        }
        // ── “재료 추가하기”를 위한 시트 ─────────────────────────────────
        .sheet(isPresented: $showAddSheet) {
            VStack(alignment: .leading, spacing: 16) {
                Text("새 재료 추가")
                    .font(.headline)
                    .padding(.bottom, 10)
                
                Group {
                    Text("재료명")
                        .font(.subheadline)
                    TextField("예: 당근", text: $newName)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("사용량")
                        .font(.subheadline)
                    TextField("예: 100g", text: $newAmount)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("단위 원가")
                        .font(.subheadline)
                    TextField("예: 500", text: $newUnitPrice)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
                
                HStack {
                    Spacer()
                    Button("취소") {
                        // 입력 취소
                        newName = ""
                        newAmount = ""
                        newUnitPrice = ""
                        showAddSheet = false
                    }
                    .padding(.trailing, 20)
                    
                    Button("저장") {
                        // 새 재료를 배열에 추가
                        if let price = Int(newUnitPrice), !newName.isEmpty, !newAmount.isEmpty {
                            let newIng = IngredientInfo(
                                name: newName,
                                amount: newAmount,
                                unitPrice: price
                            )
                            ingredients.append(newIng)
                            
                            // 입력 필드 초기화
                            newName = ""
                            newAmount = ""
                            newUnitPrice = ""
                            showAddSheet = false
                        }
                    }
                    .disabled(newName.isEmpty || newAmount.isEmpty || Int(newUnitPrice) == nil)
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }
    
    // MARK: - 저장 & 루트 복귀
    private func saveMenuWithIngredients() {
        do {
            // 1️⃣ 메뉴 가격(String → Int) 변환
            let priceValue = Int(menuPrice) ?? 0
            
            // 2️⃣ 이미지(UIImage → Data) 변환 (JPEG 80% 압축)
            let imageData: Data? = image?.jpegData(compressionQuality: 0.8)
            
            
            var insertedCount = 0
            
            // 3️⃣ parsedIngredients 배열을 순회하며, 각 재료마다
            //    “같은 메뉴 이름·가격·이미지”를 포함해 삽입
            for info in ingredients {
                let entity = IngredientEntity(
                    menuName: menuName,
                    menuPrice: priceValue,
                    imageData: imageData,
                    info: info
                )
                context.insert(entity)
                insertedCount += 1
            }
            print("🚀 [Debug] 삽입할 Entity 수: \(insertedCount)")
            
            // 5️⃣ 실제 저장
            try context.save()
            print("✅ [Debug] context.save() 성공, 총 엔티티 개수: \(insertedCount)")
            
            
            // 6️⃣ 저장 후 루트 복귀
            selectedMenuName = menuName
            //            showAddMenu      = false
            
            
            // 아주 짧게 0.1초 후에 showAddMenu를 false로 변경 → Context 반영 시간을 벌어줍니다
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showAddMenu = false
            }
            
        } catch {
            print("❌ [Error] SwiftData save error:", error)
        }
    }
}
