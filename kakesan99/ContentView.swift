import SwiftUI

struct ContentView: View {
    @State private var viewModel = QuizViewModel()

    var body: some View {
        VStack(spacing: 32) {
            Text("かけざん九九")
                .font(.largeTitle.bold())

            questionArea

            statusArea

            Spacer()

            Button {
                viewModel.askQuestion()
            } label: {
                Label(buttonTitle, systemImage: "speaker.wave.2.fill")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isBusy)
        }
        .padding()
    }

    private var buttonTitle: String {
        switch viewModel.phase {
        case .idle, .error: "もんだいを だす"
        default: "つぎの もんだい"
        }
    }

    @ViewBuilder
    private var questionArea: some View {
        if let question = viewModel.currentQuestion {
            VStack(spacing: 8) {
                Text("\(question.table)のだん")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(question.displayText)
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
            }
        } else {
            Text("ボタンを おして もんだいを きいてね")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var statusArea: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()

        case .speaking:
            Label("もんだいを よみあげているよ…", systemImage: "speaker.wave.3.fill")
                .font(.title3)
                .foregroundStyle(.blue)

        case .listening:
            VStack(spacing: 12) {
                Label("こたえを こえで いってね！", systemImage: "mic.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .tint(.red)
                if !viewModel.recognizedText.isEmpty {
                    Text(viewModel.recognizedText)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

        case .result(let correct):
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("きこえた こたえ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(recognizedDisplay)
                        .font(.title.bold())
                }
                if correct {
                    Label("せいかい！", systemImage: "circle")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(.green)
                } else {
                    VStack(spacing: 4) {
                        Label("ざんねん…", systemImage: "xmark")
                            .font(.system(size: 40, weight: .heavy))
                            .foregroundStyle(.red)
                        if let question = viewModel.currentQuestion {
                            Text("こたえは \(question.answer) だよ")
                                .font(.title3)
                        }
                    }
                }
            }

        case .error(let message):
            Text(message)
                .font(.callout)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }

    private var recognizedDisplay: String {
        if let answer = viewModel.recognizedAnswer {
            return "\(answer)"
        }
        return viewModel.recognizedText.isEmpty ? "（きこえなかったよ）" : viewModel.recognizedText
    }
}

#Preview {
    ContentView()
}
