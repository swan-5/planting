import SwiftUI

/// Not in PRODUCT_SPEC.md — added on request: a plain one-line-per-feature
/// guide, reached from Settings, so features added along the way (clover,
/// fortune, birthday, holidays, recurrence delete scope, ...) have
/// somewhere a new user can skim them.
struct FeatureGuideView: View {
    private struct Item: Identifiable {
        let icon: String
        let text: String
        var id: String { text }
    }

    private let items: [Item] = [
        Item(icon: "calendar", text: "캘린더 한 화면에서 일정과 할 일을 함께 확인해요"),
        Item(icon: "hand.draw", text: "일정·할 일을 길게 눌러 다른 날짜로 옮기거나 복사할 수 있어요"),
        Item(icon: "arrow.left.arrow.right", text: "캘린더를 좌우로 스와이프하면 월이 바뀌어요"),
        Item(icon: "checkmark.square", text: "할 일은 반복 설정, 검색, 정렬을 지원해요"),
        Item(icon: "trash", text: "반복되는 일정·할 일은 이번 것만 / 이후 전체 / 전체 중 골라 삭제할 수 있어요"),
        Item(icon: "doc.text", text: "메모는 날짜별로 남기고 필요하면 Face ID로 잠글 수 있어요"),
        Item(icon: "tag", text: "카테고리마다 색을 지정해서 일정·할 일을 구분해요"),
        Item(icon: "chevron.down", text: "월 이름을 누르면 이번 달 완료율과 회고를 볼 수 있어요"),
        Item(icon: "leaf", text: "한 주의 할 일을 모두 끝내면 네잎클로버가 한 잎씩 자라나요"),
        Item(icon: "sparkles", text: "네잎클로버를 누르면 오늘의 운세를 볼 수 있어요"),
        Item(icon: "birthday.cake", text: "로그인할 때 입력한 생일이 매년 캘린더에 자동으로 표시돼요"),
        Item(icon: "flag", text: "설정에서 공휴일 표시를 켜고 끌 수 있어요"),
        Item(icon: "square.grid.2x2", text: "홈 화면에 위젯을 추가하면 오늘 일정과 할 일을 바로 볼 수 있어요"),
    ]

    var body: some View {
        List(items) { item in
            HStack(spacing: PlantingSpacing.md) {
                Image(systemName: item.icon)
                    .foregroundStyle(PlantingColor.primaryBlue)
                    .frame(width: 22)
                Text(item.text)
                    .font(PlantingFont.body())
                    .foregroundStyle(PlantingColor.primaryText)
            }
            .padding(.vertical, PlantingSpacing.xs)
        }
        .listStyle(.plain)
        .navigationTitle("기능 소개")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FeatureGuideView()
    }
}
