//
//  SSIngredientSheetView.swift
//  HambJaeryoModal
//
//  Created by coulson on 5/28/25.
//

import SwiftUI
import PhotosUI
import FirebaseAI
import SwiftData

struct SSIngredientSheetView: View {
    
    @Binding var showAddMenu: Bool
    @Binding var selectedMenuName: String
    
    @State private var navigateToResult = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var menuName: String = ""
    @State private var menuPrice: String = ""
    @State private var parsedIngredients: [IngredientInfo] = []
    
    
    @Environment(\.modelContext) private var context
    
    
    private var model: GenerativeModel?
    
    
    init(
        showAddMenu: Binding<Bool>,
        selectedMenuName: Binding<String>,
        firebaseService: FirebaseAI = FirebaseAI.firebaseAI()
    ) {
        _showAddMenu  = showAddMenu
        _selectedMenuName = selectedMenuName
        //            self.model = firebaseService.generativeModel(modelName: "gemini-1.5-pro")
        self.model = firebaseService.generativeModel(modelName: "gemini-2.0-flash-001")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal, 10)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                        Text("이미지 선택")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 10)
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
            
            Group {
                Text("메뉴 이름")
                    .font(.headline)
                TextField("예: 된장찌개", text: $menuName)
                    .textFieldStyle(.roundedBorder)
                
                Text("메뉴 가격")
                    .font(.headline)
                TextField("예: 9000", text: $menuPrice)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
            Button("재료원가 계산하기") {
                Task { await analyzeIngredients() }
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .navigationTitle("재료원가계산")
        // ── iOS 16+ navigationDestination 사용 ─────────────────────────
        .navigationDestination(
            isPresented: $navigateToResult,
            destination: {
                // parsedIngredients가 채워진 직후 navigateToResult가 true가 되면,
                // IngredientResultView가 푸시(=push)됩니다.
                SSIngredientResultView(
                    selectedMenuName: $selectedMenuName,
                    showAddMenu:      $showAddMenu,
                    menuName:         menuName,
                    menuPrice:        menuPrice,
                    image:            selectedImage,
                    parsedIngredients: parsedIngredients
                )
            }
        )
    }
    
    // MARK: - Gemini API 호출 및 파싱
    func analyzeIngredients() async {
        guard let selectedImage,
              //        guard let imageData = selectedImage.jpegData(compressionQuality: 0.7) else { return }
              let model else { return }
        
        let prompt = """
        음식 이름: \(menuName)
        음식 가격: \(menuPrice)원
        
        아래의 음식 이름과 사진을 참고하여, 이 음식에 사용된 재료 정보를 다음 JSON 형식으로 제공해줘:
        
        [
          {
            "name": "재료명",
            "amount": "사용량 및 그램단위 (예: 100g)",
            "unitPrice": 단위 원가 (숫자, 원 단위)
          },
          ...
        ]
        
        - 사용된 재료는 주재료 위주로 구성
        - 'unitPrice'는 'amount'의 단위 만큼만 사용했을 때 얼마인지 계산해줘.
        - 텍스트 설명 없이 JSON 배열만 출력
        """
        
        do {
            let parts: [any PartsRepresentable] = [selectedImage]
            var fullText = ""
            for try await chunk in try model.generateContentStream(prompt, parts) {
                if let text = chunk.text { fullText += text }
            }
            
            // 백틱 제거 및 JSON 추출
            let cleaned = fullText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard
                let first = cleaned.firstIndex(of: "["),
                let last  = cleaned.lastIndex(of: "]"),
                let data  = String(cleaned[first...last]).data(using: .utf8)
            else { return }
            
            
            let decoded = try JSONDecoder().decode([IngredientInfo].self, from: data)
            // 1️⃣ – Main Thread에서 상태 갱신 및 저장 수행
            await MainActor.run {
                parsedIngredients = decoded
                
                // 3️⃣ – 저장이 끝나면 화면 전환
                navigateToResult = true
            }
            
        } catch {
            print("Gemini API 호출 실패: \(error)")
        }
        
    }
}
