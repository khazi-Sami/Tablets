import PhotosUI
import SwiftData
import SwiftUI

struct PrescriptionScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PrescriptionScannerViewModel()

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ZStack {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: Spacing.large) {
                            hero

                            if let image = viewModel.scannedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 260)
                                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
                                    .appShadow(AppShadow.soft)
                            } else {
                                PrescriptionScanFrameView()
                            }

                            actionButtons

                            warningCard

                            if !viewModel.rawText.isEmpty {
                                rawTextCard
                            }

                            if !viewModel.drafts.isEmpty {
                                draftsSection
                                CapsuleButton("Confirm and Save Medicines", systemImage: "checkmark.shield.fill") {
                                    viewModel.saveConfirmedDrafts(modelContext: modelContext)
                                }
                            }
                        }
                        .padding(Spacing.medium)
                        .padding(.bottom, 140)
                    }

                    if viewModel.isProcessing {
                        ReportGeneratingOverlay()
                    }
                }
            }
            .navigationTitle("Scan Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.isShowingCamera) {
                DocumentCameraScanner { images in
                    viewModel.processScannedImages(images)
                } onCancel: {}
            }
            .onChange(of: viewModel.selectedPhotoItem) { _, _ in
                viewModel.loadSelectedPhoto()
            }
            .onChange(of: viewModel.didSave) { _, didSave in
                if didSave { dismiss() }
            }
            .alert("Prescription scanner", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var hero: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            HStack(spacing: Spacing.medium) {
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(AppColor.medicalBlue)
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Prescription Scanner")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.ink)
                    Text("Extract medicine details from a prescription photo, then verify every draft before saving.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.small) {
            CapsuleButton("Camera", systemImage: "camera.fill") {
                viewModel.isShowingCamera = true
            }

            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                Label("Gallery", systemImage: "photo.fill")
                    .font(AppFont.button)
                    .foregroundStyle(AppColor.medicalBlueDeep)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(AppColor.cream.opacity(0.88))
                    .clipShape(Capsule())
                    .appShadow(AppShadow.soft)
            }
        }
    }

    private var warningCard: some View {
        PillCardContainer(style: .lavender) {
            Label("Please verify all medicine details before saving. Tablets only extracts and organizes user-provided prescription text.", systemImage: "exclamationmark.shield.fill")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
        }
    }

    private var rawTextCard: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Extracted text")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)
                Text(viewModel.rawText)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
                    .lineLimit(8)
            }
        }
    }

    private var draftsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            DashboardSectionTitle("Review drafts")
            ForEach($viewModel.drafts) { $draft in
                PrescriptionDraftCard(draft: $draft)
            }
        }
    }
}

#Preview {
    PrescriptionScannerView()
        .modelContainer(SampleData.previewContainer)
}
