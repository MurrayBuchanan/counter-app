import SwiftUI

struct CounterCardView: View {
    let counter: Counter
    var isDropTarget: Bool = false
    var dropPosition: AllCountersViewModel.DropPosition = .none
    
    private var theme: Theme {
        ThemeManager.shared.theme(for: counter)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(theme.primaryColor)
                            .frame(width: 32, height: 32)
                        if let iconName = counter.iconName {
                            Image(systemName: iconName)
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    Text(counter.name)
                        .foregroundColor(.primary)
                        .font(.body)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .frame(height: 44)
                .background(Color.clear)
            }
            .overlay(alignment: .top) {
                if isDropTarget && dropPosition == .before {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 3)
                        .offset(y: -1.5)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .overlay(alignment: .bottom) {
                if isDropTarget && dropPosition == .after {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 3)
                        .offset(y: 1.5)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct CounterCardDragPreview: View {
    let counter: Counter
    private var theme: Theme {
        ThemeManager.shared.theme(for: counter)
    }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.gradient)
                .frame(height: 44)
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(theme.primaryColor)
                        .frame(width: 32, height: 32)
                    if let iconName = counter.iconName {
                        Image(systemName: iconName)
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                Text(counter.name)
                    .foregroundColor(.white)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
