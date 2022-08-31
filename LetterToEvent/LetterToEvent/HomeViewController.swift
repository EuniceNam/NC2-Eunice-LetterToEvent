//
//  ViewController.swift
//  LetterToEvent
//
//  Created by Hyorim Nam on 2022/08/29.
//

// 추가 필요:
// - 카메라 권한 설정
// - 앨범 권한 설정: https://zeddios.tistory.com/1052 https://developer.apple.com/documentation/photokit/phaccesslevel

// 현재 문제:
// - 얘가 알아서 찍어버림
// - 손가락으로 조정하기가 보였다 안 보였다 함

import UIKit
import PhotosUI
import VisionKit
import Vision

class HomeViewController: UIViewController {
    @IBOutlet weak var textScanButton: UIButton!
    @IBOutlet weak var calendarScanButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        textScanButton.setImage(UIImage(systemName: "text.viewfinder"), for: .normal)
        textScanButton.setTitle(" 글씨 스캔하기", for: .normal)
        calendarScanButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        calendarScanButton.setTitle(" 캘린더 스캔하기", for: .normal)
    }
    
    @IBAction func chooseSourceForLetter(_ sender: UIButton) {
        chooseSourceActionSheet()
    }
    @IBAction func chooseSourceForCalendar(_ sender: UIButton) {
        chooseSourceActionSheet()
    }

    // 액션시트 열기: 카메라를 쓸지, 사진앨범을 쓸지
    func chooseSourceActionSheet() {
        let prompt = UIAlertController(title: "글씨를 찍어주세요", message: "읽을 사진을 골라주세요", preferredStyle: .actionSheet)
        // 새 사진 찍기
        func openCamera(_ _: UIAlertAction) {
            let documentCameraViewController = VNDocumentCameraViewController()
            documentCameraViewController.delegate = self
            present(documentCameraViewController, animated: true)
        }
        // 기존 사진 사용
        func openAlbum(_ _: UIAlertAction) {
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.filter = PHPickerFilter.images
            configuration.preferredAssetRepresentationMode = .current
            configuration.selection = .ordered
            configuration.selectionLimit = 1
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true)
        }

        let cameraAction = UIAlertAction(title: "카메라", style: .default, handler: openCamera)
        let albumAction = UIAlertAction(title: "사진", style: .default, handler: openAlbum)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        [cameraAction, albumAction, cancelAction].forEach {
            prompt.addAction($0)
        }
        self.present(prompt, animated: true, completion: nil)
    }
}

// 사진을 새로 찍는 경우 델리게이트
extension HomeViewController: VNDocumentCameraViewControllerDelegate {
    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        // 이동할 뷰컨트롤러
        guard let secondVC = storyboard?.instantiateViewController(withIdentifier: "MIDDLEVC") as? MiddleViewController
        else {
            return
        }
        // 최근 사진을 다음 뷰에 넘김
        // 나중에 해봐야지: onchange로 scan.pageCount 가 1이 되면 종료해버리는 방법
        controller.dismiss(animated: true) {
            if scan.pageCount > 0 {
                print("pageCount: \(scan.pageCount)")
                secondVC.image = scan.imageOfPage(at: scan.pageCount - 1)
                // 다음 뷰로 이동
                self.navigationController?.pushViewController(secondVC, animated: true)
            }
        }
    }
}

// 앨범의 사진을 사용하는 경우 델리게이트
extension HomeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        // 고른 사진 없음
        guard let itemProvider = results.first?.itemProvider else {
            print("results.first is nil")
            return
        }
        // 이동할 뷰
            // 헤맨 부분:
            // - VC간 정보를 넘길 때, as?를 안 하면 커스텀VC를 불러오지 못해서 변수에 접근불가
            // - 스토리보드로 접근하지 않고 클래스로 부르면 스토리보드의 내용을 사용하지 못함
            // -> 네비게이션 스택에 스토리보드를 넣되 as? 로 커스텀VC로 지정
        guard let secondVC = self.storyboard?.instantiateViewController(withIdentifier: "MIDDLEVC") as? MiddleViewController else {
            return
        }
        // 고른 사진을 다음 뷰에 넘김
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                DispatchQueue.main.async {
                    secondVC.image = image as? UIImage
                }
            }
        }
        // 다음 뷰로 이동
        navigationController?.pushViewController(secondVC, animated: true)
    }
}
