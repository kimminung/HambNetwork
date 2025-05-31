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
    @Environment(\.dismiss) private var dismiss
    @Binding var showHistory: Bool
    
    let menuName: String
    let menuPrice: String
    let image: UIImage?
    let parsedIngredients: [IngredientInfo]
    
    @State private var isEditing = false
    
    var body: some View {
        VStack {
            HStack {
                Button("닫기") {
                    dismiss()
                }
                
                Spacer()
                
                Text("계산 결과")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button(isEditing ? "완료" : "편집") {
                    isEditing.toggle()
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
            
            List(parsedIngredients) { ing in
                VStack(alignment: .leading) {
                    Text(ing.name).font(.headline)
                    Text("사용량: \(ing.amount) / 단가: \(ing.unitPrice)원")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("저장하고 모두 닫기") {
                do {
                    for info in parsedIngredients { context.insert(IngredientEntity(menuName: menuName, info: info)) }
                    try context.save()
                    showHistory = true
                    //                            dismiss(); DispatchQueue.main.async { dismissParentSheet() }
                    dismiss()
                } catch { print("SwiftData save error:", error) }
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding()
        }
        .navigationTitle("결과")
    }
}
