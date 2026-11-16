import SwiftUI
import UniformTypeIdentifiers
import PDFKit

public struct DocumentsView: View {
    @ObservedObject var db = DatabaseManager.shared

    @State private var showAddSheet: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var newTitle: String = ""
    @State private var newCategory: String = "Général"
    @State private var newText: String = ""
    
    // Configuration Docling
    @State private var selectedDoclingMode: DoclingQualityMode = .balanced
    @State private var isProcessingDocling: Bool = false
    @State private var doclingProgressText: String = ""
    @State private var doclingProgressValue: Double = 0.0
    @State private var doclingStatsSummary: String? = nil
    @State private var doclingErrorMessage: String? = nil

    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.10).ignoresSafeArea()

                if db.documents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Aucun cours pour le moment")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Importez vos cours avec le moteur Docling embarqué (100% local, sans réseau) pour générer automatiquement les flashcards QROC et le graphe de concepts.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: { showAddSheet = true }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Ajouter un Cours")
                            }
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color(red: 0.08, green: 0.72, blue: 0.65))
                            .cornerRadius(12)
                        }
                    }
                } else {
                    List {
                        ForEach(db.documents) { doc in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(doc.category)
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                                    Spacer()
                                    Text("Maîtrise : \(Int(doc.avgMastery))%")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }

                                Text(doc.title)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("\(doc.flashcardsCount) Flashcards QROC générées")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                ProgressView(value: doc.avgMastery, total: 100.0)
                                    .accentColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(Color(red: 0.07, green: 0.10, blue: 0.15))
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { idx in
                                db.deleteDocument(db.documents[idx].id)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Bibliothèque de Cours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("Informations du Cours")) {
                            TextField("Titre (ex: Insuffisance Cardiaque)", text: $newTitle)
                            TextField("Matière / Discipline (ex: Cardiologie)", text: $newCategory)
                        }

                        Section(header: Text("Moteur Docling (100% Local)")) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mode de Conversion Docling :")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)

                                Picker("Mode Docling", selection: $selectedDoclingMode) {
                                    ForEach(DoclingQualityMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())

                                Text(selectedDoclingMode.description)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(.top, 2)
                            }
                            .padding(.vertical, 4)

                            Button(action: { showFileImporter = true }) {
                                HStack {
                                    Image(systemName: "doc.badge.plus")
                                    Text("Importer un Document (PDF, TXT, Dossier)")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                            }

                            if isProcessingDocling {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text(doclingProgressText)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    ProgressView(value: doclingProgressValue, total: 1.0)
                                        .accentColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                                }
                                .padding(.vertical, 4)
                            }

                            if let stats = doclingStatsSummary {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(stats)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }

                            if let errorMsg = doclingErrorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(errorMsg)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            TextEditor(text: $newText)
                                .frame(height: 180)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }

                        Section {
                            Button(action: {
                                if !newText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    db.addDocument(
                                        title: newTitle.isEmpty ? "Nouveau Cours" : newTitle,
                                        category: newCategory.isEmpty ? "Général" : newCategory,
                                        text: newText
                                    )
                                    newTitle = ""
                                    newText = ""
                                    doclingStatsSummary = nil
                                    showAddSheet = false
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Générer les Cartes QROC & Synthèse")
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 0.08, green: 0.72, blue: 0.65))
                                    Spacer()
                                }
                            }
                        }
                    }
                    .navigationTitle("Nouveau Cours")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Annuler") { showAddSheet = false }
                        }
                    }
                    .fileImporter(
                        isPresented: $showFileImporter,
                        allowedContentTypes: [.pdf, .plainText, .folder],
                        allowsMultipleSelection: false
                    ) { result in
                        handleFileImport(result)
                    }
                }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }

                if newTitle.isEmpty {
                    self.newTitle = url.deletingPathExtension().lastPathComponent
                }

                // 1. Si c'est un fichier PDF -> Traitement par DoclingLocalEngine
                if url.pathExtension.lowercased() == "pdf" {
                    guard let fileData = try? Data(contentsOf: url) else {
                        self.doclingErrorMessage = "Erreur de lecture du fichier PDF"
                        return
                    }

                    self.isProcessingDocling = true
                    self.doclingErrorMessage = nil
                    self.doclingStatsSummary = nil
                    self.doclingProgressValue = 0.0
                    self.doclingProgressText = "Initialisation de Docling..."

                    DoclingLocalEngine.shared.parsePDF(
                        pdfData: fileData,
                        mode: selectedDoclingMode,
                        progress: { progress, text in
                            self.doclingProgressValue = progress
                            self.doclingProgressText = text
                        },
                        completion: { res in
                            self.isProcessingDocling = false
                            switch res {
                            case .success(let doclingResult):
                                self.newText = doclingResult.markdown
                                self.doclingStatsSummary = "Docling (\(selectedDoclingMode.rawValue)) : \(doclingResult.pagesCount) pages, \(doclingResult.headingsCount) titres détectés en \(String(format: "%.1f", doclingResult.processingTime))s"
                            case .failure(let error):
                                self.doclingErrorMessage = "Erreur Docling : \(error.localizedDescription)"
                            }
                        }
                    )
                }
                // 2. Si c'est un fichier texte brut
                else if let text = try? String(contentsOf: url) {
                    self.newText = text
                    self.doclingStatsSummary = "Texte brut importé (\(text.count) caractères)"
                }
                // 3. Si c'est un dossier complet
                else if url.hasDirectoryPath {
                    do {
                        let fileManager = FileManager.default
                        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

                        var combinedText = ""
                        for fileURL in contents {
                            if fileURL.pathExtension.lowercased() == "txt" || fileURL.pathExtension.lowercased() == "md", let text = try? String(contentsOf: fileURL) {
                                combinedText += "\n\n--- \(fileURL.lastPathComponent) ---\n" + text
                            } else if fileURL.pathExtension.lowercased() == "pdf", let data = try? Data(contentsOf: fileURL) {
                                let localExtracted = LocalPDFExtractor.extractText(from: data)
                                if !localExtracted.isEmpty {
                                    combinedText += "\n\n--- \(fileURL.lastPathComponent) ---\n" + localExtracted
                                }
                            }
                        }

                        self.newText = combinedText
                        if combinedText.isEmpty {
                            self.doclingErrorMessage = "Aucun fichier lisible trouvé dans le dossier sélectionné."
                        } else {
                            self.doclingStatsSummary = "Dossier importé avec succès"
                        }
                    } catch {
                        self.doclingErrorMessage = "Erreur de lecture du dossier."
                    }
                } else {
                    self.doclingErrorMessage = "Format de fichier non pris en charge."
                }
            }
        case .failure(let error):
            self.doclingErrorMessage = "Erreur de sélection : \(error.localizedDescription)"
        }
    }
}
