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

import EventKitUI

class MiddleViewController: UIViewController {

    var image: UIImage?
    
    var textRecognitionRequest = VNRecognizeTextRequest()
    var testResultViewController: UIViewController?

    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var testImageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    var transcript = ""
    var transcriptArray = [String]()

    var events = [EventData]()
    let eventStore = EKEventStore()
    @IBOutlet weak var eventPreviewTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        textLabel.text = "testImage"
        textLabel.backgroundColor = .green
        testImageView.image = image
        testImageView.backgroundColor = .red
        eventPreviewTextView.text = ""

        self.configTextRecognitionRequest()
//        DispatchQueue.global(qos: .userInitiated).async {
            if let image = self.image {
                self.processImage(image)
            }
//        }
        // 순차실행ㅇ 안 되어 옮김
//        for i in self.transcriptArray {
//            print("@in")
//            self.events.append(EventData(text: i))
//        }
//        for ev in self.events {
//            self.eventPreviewTextView.text += ev.toString()
//        }
    }

    @IBAction func addEventAndFinish(_ sender: UIButton) {
        // auth 확인 후 등록
        for ev in self.events {
            if ev.isValidEvent() {
                if checkEventAuth() {
                    addEvent(eventdata: ev)
                    // 캘린더 열기
                    // 해당 날짜로 열기는 지금 안 함
                    if let calendarUrl = URL(string: "calshow://") {
                        if UIApplication.shared.canOpenURL(calendarUrl) {
                            UIApplication.shared.open(calendarUrl)
                        }
                    }
                    // 홈으로 가기
                    navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }

    private func configTextRecognitionRequest() {
        textRecognitionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    DispatchQueue.main.async {
                        // print("requestResults: \(requestResults)")
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
}

extension MiddleViewController {
    func addRecognizedText(recognizedText: [VNRecognizedTextObservation]) {
        let maximumCandidates = 1
        for observation in recognizedText {
            guard let candidate = observation.topCandidates(maximumCandidates).first else {
                continue
            }
            self.transcriptArray.append(candidate.string)
            transcript += candidate.string
            // print(transcript)
            // 줄 별로 읽기 시도하기 <- 지금은 모르겠음
            transcript += "\n"
        }
        textView?.text = transcript
        
        // viewDidLoad에서 하면 안 됨 (결과가 늦게 와서)
        for i in self.transcriptArray {
            self.events.append(EventData(text: i))
        }
        for ev in self.events {
            self.eventPreviewTextView.text += ev.toString()
        }
    }
}

extension MiddleViewController{
    func checkEventAuth() -> Bool {
        var auth = false
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            eventStore.requestAccess(to: .event) { granted, error in
                if granted {
                    auth = true
                }
            }
        case .authorized:
            auth = true
        default:
            // alert 띄우기
            break
        }
        return auth
    }
    func addEvent(eventdata: EventData) {
        let event = EKEvent(eventStore: eventStore)
        // 어느 캘린더를 쓸 지 선택을 추가할 수도 있음
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.title = eventdata.title
        event.startDate = eventdata.startDate
        event.isAllDay = eventdata.isAllDay
        if !event.isAllDay && eventdata.endDate == nil {
            event.endDate = Date.init(timeInterval: 3600, since: event.startDate)
        } else {
            event.endDate = eventdata.endDate
        }
        event.location = eventdata.location
        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
        } catch {
            print(error)
        }
    }
}
