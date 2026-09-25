import Observation

/// Calls `onChange` (on the main actor) every time the observed value changes. Keeps observing until `isActive` is false.
@MainActor
func observeChanges<T: Equatable>(_ value: @escaping @MainActor () -> T, onChange: @escaping @MainActor (T) -> Void) {
    let current = withObservationTracking { value() } onChange: {
        Task { @MainActor in
            observeChanges(value, onChange: onChange)
        }
    }
    onChange(current)
}
