/// Holding Delete deletes once, then again and again after a short wait, as on iOS.
@MainActor
final class KeyRepeater {
    private static let delay = Duration.milliseconds(500)
    private static let interval = Duration.milliseconds(100)
    private var task: Task<Void, Never>?

    func start(_ action: @escaping @MainActor () -> Void) {
        stop()
        action()
        task = Task {
            var wait = Self.delay
            while (try? await Task.sleep(for: wait)) != nil {
                action()
                wait = Self.interval
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
