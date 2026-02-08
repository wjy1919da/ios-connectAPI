import SwiftUI
import AVFoundation

enum MonitorStatus: String {
    case idle = "Ready"
    case listening = "Monitoring..."
    case active = "Engaged"
    case error = "Error"
}

final class CryMonitorViewModel: ObservableObject {
    @Published var status: MonitorStatus = .idle
    @Published var currentVolume: Float = 0
    @Published var threshold: Float = 0.15
    @Published var history: [String] = []
    @Published var errorMessage: String? = nil

    private let audioEngine = AVAudioEngine()
    private var inputFormat: AVAudioFormat?

    func startMonitoring() {
        errorMessage = nil
        status = .listening

        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if !granted {
                    self.status = .error
                    self.errorMessage = "Microphone permission denied."
                    return
                }
                self.configureAndStartEngine()
            }
        }
    }

    func stopMonitoring() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        status = .idle
        currentVolume = 0
    }

    private func configureAndStartEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setPreferredSampleRate(16000)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputFormat = format

            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            status = .error
            errorMessage = "Failed to start audio engine."
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        if frameLength == 0 { return }

        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))

        DispatchQueue.main.async {
            self.currentVolume = rms
            if self.status == .listening && rms > self.threshold {
                self.status = .active
                self.appendHistory("Cry detected. Comforting...")
            } else if self.status == .active && rms < (self.threshold * 0.6) {
                self.status = .listening
                self.appendHistory("Calm detected. Continue monitoring.")
            }
        }
    }

    private func appendHistory(_ text: String) {
        history.append(text)
        if history.count > 10 {
            history.removeFirst(history.count - 10)
        }
    }
}

struct CryMonitorView: View {
    @StateObject private var viewModel = CryMonitorViewModel()

    private func statusColor() -> Color {
        switch viewModel.status {
        case .idle:
            return Color.gray.opacity(0.2)
        case .listening:
            return Color.yellow.opacity(0.25)
        case .active:
            return Color.green.opacity(0.25)
        case .error:
            return Color.red.opacity(0.2)
        }
    }

    private func statusTextColor() -> Color {
        switch viewModel.status {
        case .idle:
            return .gray
        case .listening:
            return .yellow
        case .active:
            return .green
        case .error:
            return .red
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("No More Cry")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.appBlue)
                        Text("AI Soothing Companion")
                            .font(.caption)
                            .foregroundColor(.softGray)
                    }

                    VStack(spacing: 18) {
                        Text(viewModel.status.rawValue)
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(statusColor())
                            .foregroundColor(statusTextColor())
                            .cornerRadius(20)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Threshold")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.appBlue)
                                Spacer()
                                Text("\(Int(viewModel.threshold * 100))%")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.softGray)
                            }

                            Slider(value: $viewModel.threshold, in: 0.02...0.5, step: 0.01)
                                .tint(.appBlue)

                            HStack {
                                Text("Input")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.softGray)
                                    .frame(width: 50, alignment: .leading)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.dividerGray, lineWidth: 1)
                                            )
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(viewModel.currentVolume > viewModel.threshold ? Color.cryRed : Color.appBlue)
                                            .frame(width: geo.size.width * CGFloat(min(viewModel.currentVolume * 2, 1)))
                                    }
                                }
                                .frame(height: 10)
                            }
                        }
                        .padding(20)
                        .background(Color.softBlue.opacity(0.4))
                        .cornerRadius(18)

                        VStack(spacing: 8) {
                            if viewModel.history.isEmpty {
                                Text(viewModel.status == .idle ? "Source: Microphone" : "Listening...")
                                    .font(.caption)
                                    .foregroundColor(.softGray)
                            } else {
                                ForEach(viewModel.history.indices, id: \.self) { idx in
                                    Text(viewModel.history[idx])
                                        .font(.caption)
                                        .foregroundColor(.appBlue)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 90)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.dividerGray, lineWidth: 1)
                        )

                        HStack {
                            if viewModel.status == .idle || viewModel.status == .error {
                                Button {
                                    viewModel.startMonitoring()
                                } label: {
                                    Text("Start Monitoring")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 28)
                                        .padding(.vertical, 12)
                                        .background(Color.appBlue)
                                        .cornerRadius(16)
                                }
                            } else {
                                Button {
                                    viewModel.stopMonitoring()
                                } label: {
                                    Text("Stop Session")
                                        .font(.headline)
                                        .foregroundColor(.cryRed)
                                        .padding(.horizontal, 28)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.cryRed, lineWidth: 2)
                                        )
                                }
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.cryRed)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.cryRed.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(24)
                    .cardStyle()
                    .padding(.horizontal)

                    Text("Tip: Place the device near the baby. Adjust the threshold if it triggers too easily.")
                        .font(.caption2)
                        .foregroundColor(.softGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .padding(.vertical)
            }
            .background(Color.softBlue.ignoresSafeArea())
            .navigationTitle("Cry Monitor")
        }
    }
}

#Preview {
    CryMonitorView()
}
