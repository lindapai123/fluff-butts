import SwiftUI

struct CourseSelectionSheet: View {
    @Binding var selectedCourse: CourseType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            Text("Choose a Course")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.20, green: 0.20, blue: 0.35))
                .padding(.top, 18)
                .padding(.bottom, 20)

            VStack(spacing: 12) {
                ForEach(CourseType.allCases, id: \.self) { course in
                    Button {
                        if course.isAvailable {
                            selectedCourse = course
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(course.isAvailable
                                          ? Color(red: 0.88, green: 0.93, blue: 1.0)
                                          : Color.gray.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: course.icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(course.isAvailable
                                                     ? Color(red: 0.15, green: 0.45, blue: 0.90)
                                                     : .gray)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 8) {
                                    Text(course.rawValue)
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(course.isAvailable ? .primary : .gray)
                                    if !course.isAvailable {
                                        Text("COMING SOON")
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(Color.orange))
                                    }
                                }
                                Text(course.description)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedCourse == course {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(red: 0.15, green: 0.65, blue: 0.30))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedCourse == course
                                      ? Color(red: 0.88, green: 0.96, blue: 0.88)
                                      : Color(.systemBackground))
                                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                    }
                    .disabled(!course.isAvailable)
                }
            }

            Spacer()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
