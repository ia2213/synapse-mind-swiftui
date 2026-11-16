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
    @State private var isProcessingDocling: Bool = false
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
                        Text("Ajoutez vos documents ou leçons pour générer automatiquement les flashcards et la fiche de synthèse.")
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
                            TextField("Matière / Discipline", text: $newCategory)
                        }

                        Section(header: Text("Contenu du Cours (Manuel ou Import)")) {
                            Button(action: { showFileImporter = true }) {
                                HStack {
                                    Image(systemName: "doc.badge.plus")
                                    Text("Importer un fichier (PDF, TXT, Dossier)")
                                }
                            }
                            
                            if isProcessingDocling {
                                HStack {
                                    ProgressView()
                                    Text("Extraction du document en cours...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            if let errorMsg = doclingErrorMessage {
                                Text(errorMsg)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            TextEditor(text: $newText)
                                .frame(height: 180)
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
                                    showAddSheet = false
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Générer les Cartes & Synthèse")
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
                
                // Si c'est un fichier PDF
                if url.pathExtension.lowercased() == "pdf" {
                    guard let fileData = try? Data(contentsOf: url) else {
                        self.doclingErrorMessage = "Erreur de lecture du PDF"
                        return
                    }
                    
                    self.isProcessingDocling = true
                    self.doclingErrorMessage = nil
                    
                    DoclingClient.shared.convertDocument(fileData: fileData, filename: url.lastPathComponent) { res in
                        DispatchQueue.main.async {
                            self.isProcessingDocling = false
                            switch res {
                            case .success(let markdown):
                                self.newText = markdown
                            case .failure(let error):
                                // Fallback local automatique immédiat
                                let localExtracted = LocalPDFExtractor.extractText(from: fileData)
                                if !localExtracted.isEmpty {
                                    self.newText = localExtracted
                                } else {
                                    self.doclingErrorMessage = "Erreur d'extraction : \(error.localizedDescription)"
                                }
                            }
                        }
                    }
                } 
                // Si c'est un fichier texte (.txt, .md)
                else if let text = try? String(contentsOf: url) {
                    self.newText = text
                }
                // Si c'est un dossier
                else if url.hasDirectoryPath {
                    do {
                        let fileManager = FileManager.default
                        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        
                        var combinedText = ""
                        for fileURL in contents {
                            if fileURL.pathExtension.lowercased() == "txt" || fileURL.pathExtension.lowercased() == "md", let text = try? String(contentsOf: fileURL) {
                                combinedText += "\n\n--- \(fileURL.lastPathComponent) ---\n" + text
                            } else if fileURL.pathExtension.lowercased() == "pdf", let data = try? Data(contentsOf: fileURL) {
                                let pdfText = LocalPDFExtractor.extractText(from: data)
                                if !pdfText.isEmpty {
                                    combinedText += "\n\n--- \(fileURL.lastPathComponent) ---\n" + pdfText
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.newText = combinedText
                            if combinedText.isEmpty {
                                self.doclingErrorMessage = "Aucun fichier texte ou PDF lisible trouvé dans le dossier."
                            }
                        }
                    } catch {
                        self.doclingErrorMessage = "Erreur de lecture du dossier."
                    }
                } else {
                    self.doclingErrorMessage = "Format de fichier non pris en charge."
                }
            }
        case .failure(let error):
            self.doclingErrorMessage = "Erreur d'accès: \(error.localizedDescription)"
        }
    }
}
