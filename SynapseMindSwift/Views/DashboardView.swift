import SwiftUI

public struct DashboardView: View {
    @ObservedObject var db = DatabaseManager.shared
    @Binding var selectedTab: Int

    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.10).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SynapseMind (SwiftUI)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                                Text("Tableau de Rétention")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "brain.head.profile")
                                .font(.title)
                                .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                        }

                        // Main Due Alert Card
                        let dueCards = db.flashcards.filter { $0.nextDueDate <= Date() || $0.state == .new }
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.yellow)
                                Text("RÉVISIONS DU JOUR")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                            }

                            Text("\(dueCards.count) cartes nécessitent un rappel actif")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Moteur SM-2 & Forçage par masquage de lettres activés.")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Button(action: {
                                selectedTab = 1
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Lancer la Session")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(red: 0.08, green: 0.72, blue: 0.65))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color(red: 0.07, green: 0.10, blue: 0.15))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.08, green: 0.72, blue: 0.65).opacity(0.3), lineWidth: 1)
                        )

                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(
                                title: "Total Cours",
                                value: "\(db.documents.count)",
                                icon: "book.fill",
                                color: .blue
                            )
                            StatCard(
                                title: "Flashcards",
                                value: "\(db.flashcards.count)",
                                icon: "square.stack.3d.up.fill",
                                color: .purple
                            )
                            StatCard(
                                title: "Maîtrisées",
                                value: "\(db.flashcards.filter { $0.state == .mastered }.count)",
                                icon: "checkmark.seal.fill",
                                color: .green
                            )
                            StatCard(
                                title: "Graphe Synaptique",
                                value: "\(db.synapticLinks.count) liens",
                                icon: "bubble.left.and.bubble.right.fill",
                                color: .orange
                            )
                        }

                        // Learning Principles Notice
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MÉTHODOLOGIE NEUROSCIENTIFIQUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))

                            Text("• Répétition Espacée SM-2 : Révision aux seuils d'oubli calculés.\n• Forçage par Letter-Stripping : Masquage progressif des mots-clés.\n• QROC & Friction : Saisie obligatoire, correction des omissions.\n• Entrelacement Aléatoire : Mélange des disciplines sans biais.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(14)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(red: 0.07, green: 0.10, blue: 0.15))
        .cornerRadius(14)
    }
}
