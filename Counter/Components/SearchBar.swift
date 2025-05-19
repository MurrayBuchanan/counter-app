import SwiftUI

//MARK: - SearchBar
struct SearchBar: View {
   @Binding var text: String
   @State private var isEditing = false
   @StateObject private var speechRecognizer = SpeechRecognizer()
   @FocusState private var isFocused: Bool
   @State private var recordingTimer: Timer?
   @State private var showPermissionAlert = false
   @Namespace private var cancelButtonNamespace
   
   var body: some View {
       HStack {
           HStack {
               Image(systemName: "magnifyingglass")
                   .foregroundColor(.gray)
               
               ZStack(alignment: .trailing) {
                   TextField("Search", text: $text)
                       .textFieldStyle(.plain)
                       .foregroundColor(.primary)
                       .disableAutocorrection(true)
                       .focused($isFocused)
                       .onSubmit {
                           withAnimation(.easeInOut) { isEditing = false; isFocused = false }
                       }
                       .onChange(of: isFocused) { _, newValue in
                           withAnimation(.easeInOut) { isEditing = newValue }
                       }
                       .placeholder(when: text.isEmpty) {
                           Text("Search")
                               .foregroundColor(.gray)
                       }
                   if text.isEmpty {
                       Button {
                           handleMicrophoneTap()
                       } label: {
                           Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic.slash.fill")
                               .foregroundColor(speechRecognizer.isRecording ? .red : .gray)
                               .animation(.easeInOut, value: speechRecognizer.isRecording)
                       }
                       .transition(.opacity)
                       .accessibilityLabel("Start voice search")
                       .accessibilityHint("Double tap to start voice input")
                       .buttonStyle(.plain)
                       .padding(.trailing, 4)
                   } else {
                       Button {
                           withAnimation(.easeInOut) { text = "" }
                       } label: {
                           Image(systemName: "xmark.circle.fill")
                               .foregroundColor(.gray)
                       }
                       .accessibilityLabel("Clear search")
                       .buttonStyle(.plain)
                       .padding(.trailing, 4)
                       .transition(.opacity)
                   }
               }
               .animation(.easeInOut, value: text.isEmpty)
           }
           .padding(8)
           .background(Color(.systemGray6))
           .cornerRadius(10)
           .shadow(color: Color(.systemGray3).opacity(0.2), radius: 1, x: 0, y: 1)
           .contentShape(Rectangle())
           
           if isEditing {
               ZStack {
                   Button("Cancel") {
                       withAnimation(.easeInOut) { isEditing = false; isFocused = false }
                   }
                   .foregroundColor(.blue)
                   .id("cancel")
                   .transition(.move(edge: .trailing).combined(with: .opacity))
               }
           }
       }
       .padding(.horizontal)
       .animation(.easeInOut, value: isEditing)
       .onChange(of: speechRecognizer.transcript) { _, newValue in
           text = newValue
       }
       .onDisappear {
           stopRecording()
       }
       .alert("Speech Recognition Permission Needed", isPresented: $showPermissionAlert) {
           Button("OK", role: .cancel) { }
       } message: {
           Text("Please enable speech recognition in Settings to use voice search.")
       }
   }
   
   private func handleMicrophoneTap() {
       speechRecognizer.checkPermission { granted in
           if granted {
               if speechRecognizer.isRecording {
                   stopRecording()
               } else {
                   startRecording()
               }
           } else {
               showPermissionAlert = true
           }
       }
   }
   
   private func startRecording() {
       // Cancel any existing timer
       recordingTimer?.invalidate()
       recordingTimer = nil
       
       // Start recording
       speechRecognizer.startRecording()
       
       // Set up new timer
       recordingTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { _ in
           if speechRecognizer.isRecording {
               stopRecording()
           }
       }
   }
   
   private func stopRecording() {
       // Cancel timer
       recordingTimer?.invalidate()
       recordingTimer = nil
       
       // Stop recording if active
       if speechRecognizer.isRecording {
           speechRecognizer.stopRecording()
       }
   }
}

struct SearchBar_Previews: PreviewProvider {
    @State static var text = ""
    static var previews: some View {
        SearchBar(text: $text)
    }
}
// Gray placehplder text
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}
