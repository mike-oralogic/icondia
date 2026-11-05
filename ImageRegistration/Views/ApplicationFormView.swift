import SwiftUI
import PhotosUI

/// The main data-entry screen. Sections and numbering follow the paper IR form.
struct ApplicationFormView: View {
    @Bindable var store: DraftStore

    @State private var photoSelection: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @State private var showingSignaturePad = false
    @State private var showingReview = false
    @State private var showingResetConfirmation = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case personalityNumber, personalityName, proprietorName, proprietorAddress,
             companyIncorporation, agent, yourReference
    }

    private var app: Binding<ImageRegistrationApplication> { $store.application }

    var body: some View {
        Form {
            noticeSection
            imageDetailsSection
            proprietorSection
            agentSection
            declarationsSection
            attachmentsSection
            checklistSection
        }
        .navigationTitle("Register an Image")
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Clear", role: .destructive) { showingResetConfirmation = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Review") { showingReview = true }
                    .fontWeight(.semibold)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .confirmationDialog("Clear the whole form?", isPresented: $showingResetConfirmation,
                            titleVisibility: .visible) {
            Button("Clear form", role: .destructive) { store.reset() }
        } message: {
            Text("All entered details, the signature and attached images will be removed.")
        }
        .sheet(isPresented: $showingSignaturePad) {
            SignatureSheet(strokes: app.signature)
        }
        .navigationDestination(isPresented: $showingReview) {
            ReviewView(application: store.application)
        }
        .onChange(of: photoSelection) { _, items in
            guard !items.isEmpty else { return }
            Task { await loadPhotos(items) }
        }
    }

    // MARK: - Sections

    private var noticeSection: some View {
        Section {
            Label {
                Text("The personality to which the image(s) are to be assigned must have been applied for or registered before an application to register an image can be made.")
                    .font(.footnote)
            } icon: {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private var imageDetailsSection: some View {
        Section {
            LabeledField(number: 1, title: "Registration/application no. of personality to which the image(s) will be attached") {
                TextField("e.g. 12345", text: app.personalityNumber)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .personalityNumber)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .personalityName }
            }
            LabeledField(number: 2, title: "Name of personality to which image(s) will be attached") {
                TextField("Personality name", text: app.personalityName)
                    .textContentType(.name)
                    .focused($focusedField, equals: .personalityName)
                    .submitLabel(.done)
            }

            VStack(alignment: .leading, spacing: 4) {
                FieldTitle(number: 3, title: "If the image is a series or complex image, please select")
                Toggle("Complex image", isOn: app.isComplexImage)
                Toggle("Series image", isOn: app.isSeriesImage)
            }

            Stepper(value: app.numberOfImages, in: 1...999) {
                FieldTitle(number: 4, title: "Number of images to be registered",
                           trailing: "\(store.application.numberOfImages)")
            }

            if store.application.isSeriesImage {
                Stepper(value: app.numberInSeries, in: 1...999) {
                    FieldTitle(number: 5, title: "Number in series",
                               trailing: "\(store.application.numberInSeries)")
                }
            }
        } header: {
            Text("Image details")
        }
    }

    private var proprietorSection: some View {
        Section("Proprietor details") {
            LabeledField(number: 6, title: "Full name of proprietor") {
                TextField("Full name", text: app.proprietorName)
                    .textContentType(.name)
                    .focused($focusedField, equals: .proprietorName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .proprietorAddress }
            }
            LabeledField(number: 7, title: "Address of proprietor (including postcode)") {
                TextField("Address and postcode", text: app.proprietorAddress, axis: .vertical)
                    .lineLimit(3...6)
                    .textContentType(.fullStreetAddress)
                    .focused($focusedField, equals: .proprietorAddress)
            }
            LabeledField(number: 8, title: "If applying in the name of a company, where is it incorporated?") {
                TextField("e.g. Guernsey (leave blank if not a company)", text: app.companyIncorporation)
                    .focused($focusedField, equals: .companyIncorporation)
                    .submitLabel(.done)
            }
        }
    }

    private var agentSection: some View {
        Section("Image rights agent details") {
            LabeledField(number: 9, title: "Name of agent / agent ref number") {
                TextField("Agent name or reference", text: app.agentNameOrReference)
                    .focused($focusedField, equals: .agent)
                    .submitLabel(.done)
            }
        }
    }

    private var declarationsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(Declarations.intro)
                ForEach(Declarations.items, id: \.self) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("•")
                        Text(item)
                    }
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                FieldTitle(number: 10, title: "Signature of applicant")
                Button {
                    showingSignaturePad = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.secondary.opacity(0.4))
                        if store.application.hasSignature {
                            SignatureShape(strokes: store.application.signature, fitToRect: true)
                                .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .padding(12)
                        } else {
                            Label("Tap to sign", systemImage: "signature")
                        }
                    }
                    .frame(height: 90)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(store.application.hasSignature ? "Signature added. Tap to change." : "Tap to sign")
            }

            DatePicker(selection: app.signatureDate, in: ...Date.now, displayedComponents: .date) {
                FieldTitle(number: 11, title: "Date of signature")
            }

            LabeledField(number: 12, title: "Your reference (optional)") {
                TextField("Optional", text: app.yourReference)
                    .focused($focusedField, equals: .yourReference)
                    .submitLabel(.done)
            }
        } header: {
            Text("Declarations")
        }
    }

    private var attachmentsSection: some View {
        Section {
            PhotosPicker(selection: $photoSelection, maxSelectionCount: 50, matching: .images) {
                Label("Add image(s) from Photos", systemImage: "photo.badge.plus")
            }

            if isLoadingPhotos {
                ProgressView("Adding images…")
            }

            if !store.application.images.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                    ForEach(Array(store.application.images.enumerated()), id: \.offset) { index, data in
                        ImageThumbnail(data: data) {
                            removeImage(at: index)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Stepper(value: app.numberOfSheetsAttached, in: 0...99) {
                FieldTitle(title: "Number of sheets attached to this form",
                           trailing: "\(store.application.numberOfSheetsAttached)")
            }
        } header: {
            Text("Images to register")
        } footer: {
            Text("You must submit the image(s) along with this form, in accordance with section 11 of the Image Rights (Bailiwick of Guernsey) Ordinance, 2012.")
        }
    }

    private var checklistSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Declarations.checklist, id: \.self) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("•")
                        Text(item)
                    }
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Toggle("I have completed all of the above", isOn: app.checklistCompleted)
                .fontWeight(.semibold)
        } header: {
            Text("Completion checklist")
        }
    }

    // MARK: - Images

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        isLoadingPhotos = true
        defer {
            isLoadingPhotos = false
            photoSelection = []
        }
        var loaded: [Data] = []
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpeg = image.jpegData(compressionQuality: 0.85) else { continue }
            loaded.append(jpeg)
        }
        store.application.images.append(contentsOf: loaded)
        store.application.numberOfImages = max(store.application.images.count, 1)
    }

    private func removeImage(at index: Int) {
        guard store.application.images.indices.contains(index) else { return }
        store.application.images.remove(at: index)
        store.application.numberOfImages = max(store.application.images.count, 1)
    }
}

// MARK: - Small building blocks

/// "1." style numbered caption used for each question, matching the paper form.
private struct FieldTitle: View {
    var number: Int? = nil
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if let number {
                Text("\(number).")
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.semibold)
            }
            Text(title)
            if let trailing {
                Spacer()
                Text(trailing)
                    .monospacedDigit()
                    .fontWeight(.semibold)
            }
        }
    }
}

private struct LabeledField<Content: View>: View {
    let number: Int
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldTitle(number: number, title: title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content
        }
        .padding(.vertical, 2)
    }
}

private struct ImageThumbnail: View {
    let data: Data
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.secondary.opacity(0.2)
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, Color.black.opacity(0.6))
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .padding(4)
            .accessibilityLabel("Remove image")
        }
    }
}

/// Full-screen sheet for drawing the signature, away from the scrolling form.
private struct SignatureSheet: View {
    @Binding var strokes: [[CGPoint]]
    @State private var draft: [[CGPoint]] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sign in the box below with your finger.")
                    .foregroundStyle(.secondary)
                SignaturePad(strokes: $draft)
                Spacer()
            }
            .padding()
            .navigationTitle("Signature of applicant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        strokes = draft
                        dismiss()
                    }
                }
            }
            .onAppear { draft = strokes }
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    NavigationStack {
        ApplicationFormView(store: DraftStore(fileURL: URL.temporaryDirectory.appending(path: "preview.json")))
    }
}
