import Foundation

public struct SRSEngine {
    /// Rating quality: 0 (A revoir), 3 (Difficile), 4 (Bon), 5 (Facile)
    public static func evaluate(card: FlashcardModel, rating: Int) -> FlashcardModel {
        var updated = card
        let q = max(0, min(5, rating))

        if q < 3 {
            // Failure -> reset repetitions
            updated.repetitionCount = 0
            updated.intervalDays = 1
            updated.state = .learning
        } else {
            // Success -> calculate next interval
            if updated.repetitionCount == 0 {
                updated.intervalDays = 1
            } else if updated.repetitionCount == 1 {
                updated.intervalDays = 6
            } else {
                updated.intervalDays = Int(round(Double(updated.intervalDays) * updated.easinessFactor))
            }
            updated.repetitionCount += 1
            updated.state = updated.intervalDays >= 14 ? .mastered : .review
        }

        // Update Easiness Factor (EF)
        let delta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        updated.easinessFactor = max(1.3, updated.easinessFactor + delta)

        // Calculate next due date
        updated.nextDueDate = Calendar.current.date(byAdding: .day, value: updated.intervalDays, to: Date()) ?? Date()

        return updated
    }
}
