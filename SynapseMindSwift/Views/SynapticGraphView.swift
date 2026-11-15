import SwiftUI

public struct SynapticGraphView: View {
    @ObservedObject var db = DatabaseManager.shared

    @State private var selectedNodeTitle: String? = nil

    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.10).ignoresSafeArea()

                if db.documents.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Aucun graphe disponible")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Ajoutez plusieurs cours pour visualiser les associations synaptiques et liens inter-disciplines.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let radius: CGFloat = 100.0

                        // Draw edges
                        for link in db.synapticLinks {
                            let path = Path { p in
                                p.move(to: center)
                                p.addLine(to: CGPoint(x: center.x + 80, y: center.y - 80))
                            }
                            context.stroke(path, with: .color(Color(red: 0.08, green: 0.72, blue: 0.65).opacity(0.4)), lineWidth: 2)
                        }

                        // Draw nodes
                        for (idx, doc) in db.documents.enumerated() {
                            let angle = (Double(idx) / Double(db.documents.count)) * 2 * .pi
                            let nodePos = CGPoint(
                                x: center.x + cos(angle) * radius,
                                y: center.y + sin(angle) * radius
                            )

                            let rect = CGRect(x: nodePos.x - 20, y: nodePos.y - 20, width: 40, height: 40)
                            context.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.08, green: 0.72, blue: 0.65)))

                            context.draw(
                                Text(doc.title)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white),
                                at: CGPoint(x: nodePos.x, y: nodePos.y + 30)
                            )
                        }
                    }

                    if let title = selectedNodeTitle {
                        VStack {
                            Spacer()
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Nœud Sélectionné")
                                        .font(.caption2)
                                        .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                                    Text(title)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Button(action: { selectedNodeTitle = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(red: 0.07, green: 0.10, blue: 0.15))
                            .cornerRadius(14)
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Graphe Synaptique")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
