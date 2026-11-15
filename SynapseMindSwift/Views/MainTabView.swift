import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Tableau", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)

            ActiveRevisionView()
                .tabItem {
                    Label("Révision", systemImage: "bolt.fill")
                }
                .tag(1)

            DocumentsView()
                .tabItem {
                    Label("Cours", systemImage: "book.fill")
                }
                .tag(2)

            SynapticGraphView()
                .tabItem {
                    Label("Graphe", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(3)
        }
        .accentColor(Color(red: 0.08, green: 0.72, blue: 0.65))
    }
}
