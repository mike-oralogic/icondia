import SwiftUI

/// Checks the application, then builds the PDF and offers ways to send it.
struct ReviewView: View {
    let application: ImageRegistrationApplication

    @State private var pdfURL: URL?
    @State private var errorMessage: String?
    @State private var showingMail = false

    private var issues: [String] { application.validationIssues }

    var body: some View {
        List {
            if issues.isEmpty {
                Section {
                    Label("All required questions are complete.", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Section {
                    ForEach(issues, id: \.self) { issue in
                        Label(issue, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Still to complete")
                } footer: {
                    Text("Go back to the form to fix these before submitting.")
                }
            }

            Section("Summary") {
                row("Personality", "\(application.personalityName) (\(application.personalityNumber))")
                row("Image type", imageType)
                row("Images", "\(application.images.count) attached / \(application.numberOfImages) declared")
                row("Proprietor", application.proprietorName)
                row("Agent", application.agentNameOrReference)
                row("Signed", application.signatureDate.formatted(date: .long, time: .omitted))
            }

            Section {
                Button {
                    generatePDF()
                } label: {
                    Label(pdfURL == nil ? "Create application PDF" : "Recreate application PDF",
                          systemImage: "doc.richtext")
                }
                .disabled(!issues.isEmpty)

                if let pdfURL {
                    if MailComposer.canSendMail {
                        Button {
                            showingMail = true
                        } label: {
                            Label("Email to the IPO", systemImage: "envelope")
                        }
                    }
                    ShareLink(item: pdfURL) {
                        Label("Share or save PDF", systemImage: "square.and.arrow.up")
                    }
                }
            } header: {
                Text("Submit")
            } footer: {
                Text("Send the completed application to the Intellectual Property Office, Market Building, PO Box 451, Fountain Street, St. Peter Port, Guernsey, GY1 3GX, or email \(MailComposer.ipoEmail). Remember to enclose payment or state a High Volume Client Account for the filing fee.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Review & Submit")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: application) { _, _ in pdfURL = nil }
        .sheet(isPresented: $showingMail) {
            if let pdfURL {
                MailComposer(
                    subject: "Application to register an image – \(application.personalityName)",
                    body: "Please find attached an application to register an image for personality \(application.personalityNumber) (\(application.personalityName)).",
                    attachmentURL: pdfURL
                )
                .ignoresSafeArea()
            }
        }
    }

    private var imageType: String {
        switch (application.isComplexImage, application.isSeriesImage) {
        case (true, true): return "Complex, series of \(application.numberInSeries)"
        case (true, false): return "Complex"
        case (false, true): return "Series of \(application.numberInSeries)"
        case (false, false): return "Standard"
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        LabeledContent(title, value: value.trimmingCharacters(in: .whitespaces).isEmpty ? "—" : value)
    }

    private func generatePDF() {
        do {
            pdfURL = try ApplicationPDFRenderer(application: application).render()
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't create the PDF: \(error.localizedDescription)"
        }
    }
}
