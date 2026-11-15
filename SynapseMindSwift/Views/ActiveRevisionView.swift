import SwiftUI
import AVFoundation

public struct ActiveRevisionView: View {
    @ObservedObject var db = DatabaseManager.shared

    @State private var currentIndex: Int = 0
    @State private var userTypedAnswer: String = ""
    @State private var isAnswerRevealed: Bool = false
    @State private var strippingRatio: Double = 0.5
    @State private var isInterleaved: Bool = true
    @State private var activeCards: [FlashcardModel] = []
    @State private var synthesizer = AVSpeechSynthesizer()

    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.10).ignoresSafeArea()

                if activeCards.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                        Text("Aucune carte à réviser")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Vous êtes à jour dans vos répétitions espacées !")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Button(action: {
                            loadCards()
                        }) {
                            Text("Recharger toutes les cartes")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color(red: 0.08, green: 0.72, blue: 0.65))
                                .cornerRadius(12)
                        }
                    }
                } else if currentIndex < activeCards.count {
                    let card = activeCards[currentIndex]

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            // Header & Mode Toggles
                            HStack {
                                Text("CARTE \(currentIndex + 1) / \(activeCards.count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                                Spacer()
                                Toggle("Entrelacé", isOn: $isInterleaved)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .labelsHidden()
                            }

                            // Letter Stripping Controls
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Forçage de génération (Letter-Stripping) :")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(Int(strippingRatio * 100))%")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                                }
                                Slider(value: $strippingRatio, in: 0.0...1.0, step: 0.25)
                                    .accentColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                            }
                            .padding()
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(12)

                            // Prompt Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(card.category)
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                                    Spacer()
                                    Button(action: {
                                        speak(text: card.prompt)
                                    }) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .foregroundColor(.white)
                                    }
                                }

                                let maskedPrompt = LetterStrippingEngine.maskText(card.prompt, ratio: strippingRatio)
                                Text(maskedPrompt)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .lineSpacing(6)
                            }
                            .padding()
                            .background(Color(red: 0.07, green: 0.10, blue: 0.15))
                            .cornerRadius(16)

                            // User Answer Input (QROC Friction)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Saisie de votre réponse (Restitution Active Obligatoire) :")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                TextEditor(text: $userTypedAnswer)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }

                            if !isAnswerRevealed {
                                Button(action: {
                                    isAnswerRevealed = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("Vérifier ma réponse")
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color(red: 0.08, green: 0.72, blue: 0.65))
                                    .cornerRadius(12)
                                }
                            } else {
                                // Concrete Feedback & Error Explanations
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("RÉPONSE ATTENDUE & CORRECTION")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))

                                    Text(card.answer)
                                        .font(.subheadline)
                                        .foregroundColor(.white)

                                    if !card.keyTerms.isEmpty {
                                        Text("Mots-clés requis : \(card.keyTerms.joined(separator: ", "))")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }

                                    Divider().background(Color.white.opacity(0.1))

                                    // Evaluation Rating Buttons (SM-2)
                                    Text("Évaluez l'effort de rappel :")
                                        .font(.caption)
                                        .foregroundColor(.gray)

                                    HStack(spacing: 8) {
                                        RatingButton(label: "À revoir", color: .red, rating: 0) {
                                            rateCard(rating: 0)
                                        }
                                        RatingButton(label: "Difficile", color: .orange, rating: 3) {
                                            rateCard(rating: 3)
                                        }
                                        RatingButton(label: "Bon", color: .blue, rating: 4) {
                                            rateCard(rating: 4)
                                        }
                                        RatingButton(label: "Facile", color: .green, rating: 5) {
                                            rateCard(rating: 5)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(red: 0.07, green: 0.10, blue: 0.15))
                                .cornerRadius(16)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Révision Active")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadCards()
            }
        }
    }

    private func loadCards() {
        var list = db.flashcards
        if isInterleaved {
            list.shuffle()
        }
        activeCards = list
        currentIndex = 0
        isAnswerRevealed = false
        userTypedAnswer = ""
    }

    private func rateCard(rating: Int) {
        if currentIndex < activeCards.count {
            let card = activeCards[currentIndex]
            let updated = SRSEngine.evaluate(card: card, rating: rating)
            db.updateFlashcard(updated)

            currentIndex += 1
            isAnswerRevealed = false
            userTypedAnswer = ""
        }
    }

    private func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        synthesizer.speak(utterance)
    }
}

struct RatingButton: View {
    let label: String
    let color: Color
    let rating: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.8))
                .cornerRadius(8)
        }
    }
}
