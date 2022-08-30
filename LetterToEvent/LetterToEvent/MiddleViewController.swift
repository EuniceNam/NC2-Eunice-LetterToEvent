//
//  MiddleViewController.swift
//  LetterToEvent
//
//  Created by Hyorim Nam on 2022/08/29.
//

import UIKit
import PhotosUI
import VisionKit
import Vision

class MiddleViewController: UIViewController {

    var image: UIImage?
    
    var textRecognitionRequest = VNRecognizeTextRequest()
    var testResultViewController: UIViewController?

    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var testImageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    var transcript = ""

    private func configTextRecognitionRequest() {
        textRecognitionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    DispatchQueue.main.async {
                        print("requestResults: \(requestResults)")
                        self.addRecognizedText(recognizedText: requestResults)
                    }
                }
            } else {
                self.textView?.text = "No text detected"
            }
        })
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
    }

    private func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("cannot get cgimage")
            return
        }
        let handler = VNImageRequestHandler(cgImage: cgImage)
        do {
            try handler.perform([textRecognitionRequest])
        } catch {
            print("process image handler err: \(error)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textLabel.text = "testImage"
        textLabel.backgroundColor = .green
        testImageView.image = image
        testImageView.backgroundColor = .red

        DispatchQueue.main.async {
            self.configTextRecognitionRequest()
            if let image = self.image {
                self.processImage(image)
            }
        }
    }
}

extension MiddleViewController {
    func addRecognizedText(recognizedText: [VNRecognizedTextObservation]) {
        let maximumCandidates = 1
        for observation in recognizedText {
            guard let candidate = observation.topCandidates(maximumCandidates).first else {
                continue
            }
            transcript += candidate.string
            print(transcript)
            // 줄 별로 읽기 시도하기 <- 지금은 모르겠음
            transcript += "\n"
        }
        textView?.text = transcript
    }
}
