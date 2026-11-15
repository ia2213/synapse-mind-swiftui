import Foundation

public struct LetterStrippingEngine {
    public static func maskText(_ text: String, ratio: Double) -> String {
        let clampedRatio = max(0.0, min(1.0, ratio))
        if clampedRatio <= 0.05 { return text }

        let words = text.components(separatedBy: " ")
        var maskedWords: [String] = []

        for word in words {
            if word.count <= 2 {
                maskedWords.append(word)
                continue
            }

            var charArray = Array(word)
            for i in 0..<charArray.count {
                let char = charArray[i]
                if char.isLetter {
                    if Double.random(in: 0...1) < clampedRatio {
                        charArray[i] = "_"
                    }
                }
            }
            maskedWords.append(String(charArray))
        }

        return maskedWords.joined(separator: " ")
    }
}
