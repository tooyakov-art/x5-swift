import SwiftUI

public struct GlassEffectContainer<Content: View>: View {
    var spacing: CGFloat?
    @ViewBuilder var content: Content
    
    public init(spacing: CGFloat? = 0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            // СЛОЙ 1: Жидкая подложка (Metaballs)
            // Рендерим контент как символы, размываем и склеиваем
            Canvas { context, size in
                // Достаем контент по тегу
                if let symbol = context.resolveSymbol(id: 1) {
                    // 1. Создаем эффект "жижи"
                    // Размываем элементы друг в друга
                    context.addFilter(.blur(radius: 12))
                    
                    // 2. Отсекаем полутона (Alpha Threshold)
                    // Это делает края снова четкими, создавая эффект слияния
                    context.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    
                    // Рисуем результат
                    context.draw(symbol, at: CGPoint(x: size.width / 2, y: size.height / 2))
                }
            } symbols: {
                // Здесь мы передаем только "тела" кнопок для склеивания
                HStack(spacing: spacing) {
                    content
                        // Важно: превращаем кнопки в белые пятна для маски
                        .foregroundColor(.white)
                        // Убираем детали, оставляем только форму
                        .blur(radius: 0) 
                }
                .tag(1)
            }
            // Накладываем стеклянный материал поверх жидкой формы
            .opacity(0.4) // Прозрачность самой жидкости
            .blendMode(.plusLighter) // Режим наложения для свечения
            
            // СЛОЙ 2: Реальный контент (Иконки и текст)
            // Они остаются четкими поверх жидкости
            HStack(spacing: spacing) {
                content
            }
        }
        // Добавляем глобальный стеклянный фон контейнеру
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .opacity(0.1) // Легкая подложка
        )
    }
}
