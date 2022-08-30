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
//    private var selection = [PHPickerResult]()
//    var resultViewController: UIViewController?
    var textRecognitionRequest = VNRecognizeTextRequest()

    // 사진을 찍는 경우
    @IBAction func scanDocument(_ sender: UIButton) {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
    }

    // 앨범의 사진을 사용하는 경우
    @IBAction func presentPhotoPicker(_ sender: UIButton) {
        // 다른 폴더가 맞나? "photoLibrary: .shared()" 없이 ()로 끝내도 되는듯
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = PHPickerFilter.images
        configuration.preferredAssetRepresentationMode = .current
        configuration.selection = .ordered
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view.
//    }
}

// 사진 찍는 경우
extension HomeViewController: VNDocumentCameraViewControllerDelegate {
    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {

        // 이것과 앨범 쓰는 두 경우 모두 제대로 작동한다면 중복 코드 삭제하기
        guard let secondVC = storyboard?.instantiateViewController(withIdentifier: "MIDDLEVC") as? MiddleViewController // "RESULTVC")// as? UIViewController
        else {
            return
        }

        // 해봐야지: onchange로 scan.pageCount 가 1이 되면 종료해버리는 방법
        controller.dismiss(animated: true) {
            // 참고 코드엔 processImage가 있어서 여기서 했는데 난 UIImage만 넘길 거라서 일단 지워둠
            // DispatchQueue.global(qos: .userInitiated).async {
            // 이하도 굳이 필요한지 모르겠어서 일단 지워봄
            // DispatchQueue.main.async {
                // if let resultsVC = resultViewController as? MiddleViewController {
            if scan.pageCount > 0 {
                print("pageCount: \(scan.pageCount)")
                secondVC.image = scan.imageOfPage(at: scan.pageCount - 1)
                self.navigationController?.pushViewController(secondVC, animated: true)
            }
                // }
            // }
            // }
        }
        print("func documentCamerVC out")
    }
}

// 앨범의 사진을 사용하는 경우
extension HomeViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        guard let itemProvider = results.first?.itemProvider else {
            print("results.first is nil")
            return
        }

        // 헤맨 부분:
        // - VC간 정보를 넘길 때, as?를 안 하면 커스텀VC를 불러오지 못해서 변수에 접근불가
        // - 스토리보드로 접근하지 않고 클래스로 부르면 스토리보드의 내용을 사용하지 못함
        // -> 네비게이션 스택에 스토리보드를 넣되 as? 로 커스텀VC로 지정
        guard let secondVC = self.storyboard?.instantiateViewController(withIdentifier: "MIDDLEVC") as? MiddleViewController else {
            return
        }

        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                DispatchQueue.main.async {
                    secondVC.image = image as? UIImage
                    // print("image: \(String(describing: secondVC.image))")
                }
            }
        }
        navigationController?.pushViewController(secondVC, animated: true)
    }
}
