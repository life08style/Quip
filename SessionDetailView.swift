import SwiftUI

struct SessionDetailView: View {
    let session: GroupSession
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("It's a Match! 🎉")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(session.activityName)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Label {
                        Text(session.scheduledTime.formatted(date: .abbreviated, time: .shortened))
                    } icon: {
                        Image(systemName: "clock.fill").foregroundStyle(.blue)
                    }
                    
                    Label {
                        Text(session.participants.joined(separator: ", "))
                    } icon: {
                        Image(systemName: "person.3.fill").foregroundStyle(.green)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Text("Suggested Locations")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                
                // Lazy loading for location rows
                LazyVStack(spacing: 12) {
                    LocationRow(name: session.location1, link: session.bookingLink1)
                    LocationRow(name: session.location2, link: session.bookingLink2)
                }
                
                Spacer()
                
                Button(action: {
                    // Open chat action
                }) {
                    Label("Open Group Chat", systemImage: "message.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Plan Details")
    }
}

struct LocationRow: View {
    let name: String
    let link: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                Text("Available at suggested time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let url = URL(string: link) {
                Link(destination: url) {
                    Text("Book")
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
