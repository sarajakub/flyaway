import SwiftUI

struct ReportContentSheet: View {
    let thoughtId: String
    let reportedUserId: String
    @StateObject private var reportManager = ContentReportManager()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: ContentReport.ReportReason?
    @State private var additionalContext = ""

    var body: some View {
        NavigationView {
            Form {
                if reportManager.didSubmit {
                    // ── Success state ──────────────────────────────────────
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                                .accessibilityHidden(true)
                            Text("Report Submitted")
                                .font(.headline)
                            Text("Thank you for helping keep FlyAway safe. Our team will review this report within 24 hours.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                } else {
                    // ── Reason picker ──────────────────────────────────────
                    Section {
                        ForEach(ContentReport.ReportReason.allCases, id: \.self) { reason in
                            Button {
                                selectedReason = reason
                            } label: {
                                HStack {
                                    Text(reason.rawValue)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedReason == reason {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                            .accessibilityHidden(true)
                                    }
                                }
                            }
                            .accessibilityAddTraits(selectedReason == reason ? .isSelected : [])
                        }
                    } header: {
                        Text("Why are you reporting this thought?")
                    }

                    // ── Optional context ──────────────────────────────────
                    Section {
                        TextField("Additional context (optional)", text: $additionalContext, axis: .vertical)
                            .lineLimit(3...6)
                    } footer: {
                        Text("Your report is anonymous and will not be shared with the author.")
                    }

                    // ── Error ─────────────────────────────────────────────
                    if let err = reportManager.submitError {
                        Section {
                            Text(err)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }

                    // ── Submit button ─────────────────────────────────────
                    Section {
                        Button {
                            guard let reason = selectedReason else { return }
                            Task {
                                await reportManager.submitReport(
                                    thoughtId: thoughtId,
                                    reportedUserId: reportedUserId,
                                    reason: reason,
                                    additionalContext: additionalContext
                                )
                            }
                        } label: {
                            HStack {
                                if reportManager.isSubmitting {
                                    ProgressView()
                                        .padding(.trailing, 6)
                                }
                                Text("Submit Report")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(selectedReason == nil || reportManager.isSubmitting)
                        .accessibilityLabel("Submit report")
                        .accessibilityHint(selectedReason == nil ? "Select a reason above first" : "Sends your report to the moderation team")
                    }
                }
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(reportManager.didSubmit ? "Done" : "Cancel") {
                        reportManager.reset()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ReportContentSheet(thoughtId: "preview", reportedUserId: "user123")
}
