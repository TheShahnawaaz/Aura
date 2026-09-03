import Foundation

/// Coordinates interactive user approval for destructive or high-risk actions.
/// Allows execution to pause asynchronously until the user approves or denies via the Notch HUD or Chat panel.
public final class ApprovalCoordinator: @unchecked Sendable {
    public static let shared = ApprovalCoordinator()

    private let lock = NSLock()
    private var pendingContinuations: [UUID: CheckedContinuation<Bool, Never>] = [:]

    private init() {}

    /// Requests user confirmation for an action. Pauses asynchronously until the user decides.
    public func requestApproval(request: ActionConfirmationRequest) async -> Bool {
        await MainActor.run {
            AppState.shared.state = .awaitingConfirmation(request)
        }

        return await withCheckedContinuation { continuation in
            lock.lock()
            pendingContinuations[request.id] = continuation
            lock.unlock()
        }
    }

    /// User approved the action.
    public func approve(id: UUID) {
        lock.lock()
        let continuation = pendingContinuations.removeValue(forKey: id)
        lock.unlock()

        Task { @MainActor in
            if case .awaitingConfirmation(let req) = AppState.shared.state, req.id == id {
                AppState.shared.state = .processing(phase: "Approved. Executing action...")
            }
        }

        continuation?.resume(returning: true)
    }

    /// User denied the action.
    public func deny(id: UUID) {
        lock.lock()
        let continuation = pendingContinuations.removeValue(forKey: id)
        lock.unlock()

        Task { @MainActor in
            if case .awaitingConfirmation(let req) = AppState.shared.state, req.id == id {
                AppState.shared.state = .processing(phase: "Action cancelled by user")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    AppState.shared.resetToIdle()
                }
            }
        }

        continuation?.resume(returning: false)
    }
}
