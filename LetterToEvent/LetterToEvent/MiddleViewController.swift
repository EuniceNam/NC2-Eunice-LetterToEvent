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
import AVFoundation

class MiddleViewController: UIViewController {

    var image: UIImage?
    
    var textRecognitionRequest = VNRecognizeTextRequest()
    var testResultViewController: UIViewController?

    @IBOutlet weak var testImageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    var transcript = ""
    var transcriptArray = [String]()

    var events = [EventData]()
    let eventStore = EKEventStore()
    @IBOutlet weak var eventPreviewTextView: UITextView!

//    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var eventStackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        testImageView.image = image
        testImageView.backgroundColor = .systemGray5
        eventPreviewTextView.text = ""
        eventStackView.axis = .vertical
        eventStackView.spacing = 16
        eventStackView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        transcript = ""
        transcriptArray.removeAll()
        self.testImageView.image = image
        super.viewWillAppear(animated)
        
        if let image = self.image {
                self.configTextRecognitionRequest()
                self.processImage(image)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.testImageView.image = image
    }

    // open PHPicker
    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
        print("tapped")
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = PHPickerFilter.images
        configuration.preferredAssetRepresentationMode = .current
        configuration.selection = .ordered
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @IBAction func addEventAndFinish(_ sender: UIButton) {
        // auth 확인 후 등록
        var eventcnt = 0
        for ev in self.events {
            if ev.isValidEvent() {
                eventcnt += 1
                if checkEventAuth() {
                    addEvent(eventdata: ev)
                }
            }
        }
        if eventcnt > 0 {
        // 캘린더 열기
        // 해당 날짜로 열기는 지금 안 함
            if let calendarUrl = URL(string: "calshow://") {
                if UIApplication.shared.canOpenURL(calendarUrl) {
                    UIApplication.shared.open(calendarUrl)
                }
            }
            // 홈으로 가기
            navigationController?.popToRootViewController(animated: true)
        } else {
            let noEventAlert = UIAlertController(title: "저장할 일정이 없습니다", message: "", preferredStyle: .alert)
            let ok = UIAlertAction(title: "확인", style: .default, handler: nil)
            noEventAlert.addAction(ok)
            self.present(noEventAlert, animated: true)
        }
    }

    private func configTextRecognitionRequest() {
        textRecognitionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    DispatchQueue.main.async {
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
            // 줄 별로 읽기 시도하기 <- 지금은 모르겠음
            transcript += "\n"
        }
        textView?.text = transcript
        
        // viewDidLoad에서 하면 안 됨 (결과가 늦게 와서)
        self.ArrayToEventData()
    }
    
    func ArrayToEventData() {
        // array 비우고 시작
        self.events.removeAll()
        eventPreviewTextView.text = ""
        eventStackView.arrangedSubviews.forEach {
            eventStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for i in self.transcriptArray {
            self.events.append(EventData(text: i))
        }
        for ev in self.events {
            self.eventPreviewTextView.text += ev.toString()
            if ev.isValidEvent() {
                let tmpview = EventBox(eventData: ev)
                eventStackView.addArrangedSubview(tmpview)
                
                print(ev.title)
            }
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
        if eventdata.endDate == nil {
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

extension MiddleViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        // 고른 사진 없음
        guard let itemProvider = results.first?.itemProvider else {
            print("results.first is nil")
            return
        }
        // 고른 사진을 넘김
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                self.image = image as? UIImage
                DispatchQueue.main.async {
                    if let image = self.image {
                        self.testImageView.image = image
                    }
                }
            }
        }
    }
}
