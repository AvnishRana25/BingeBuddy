import SwiftUI
struct ShimmerRowView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    ShimmerView()
                        .frame(width: 200, height: 20)
                        .cornerRadius(4)
                    
                    ShimmerView()
                        .frame(width: 120, height: 16)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
            }
            
            ShimmerView()
                .frame(height: 32)
                .cornerRadius(4)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal, 16)
    }
} 
