//
//  EventBox.swift
//  LetterToEvent
//
//  Created by Hyorim Nam on 2022/08/31.
//

import UIKit

class EventBox: UIStackView {

    let title = UILabel()
    let location = UILabel()
    let startTime = UILabel()
    let endTime = UILabel()
    
    let pad: CGFloat = 8.0

    init(eventData: EventData) {
        super.init(frame: CGRect.zero)
        commonInit(eventData)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit(_ eventData: EventData) {
        // MARK: Debugging 중
        // 화면에서 길게 눌러 수정도 추가 필요(업데이트는 어떻게 해야하지?)
        // backgroundColor = .systemMint.withAlphaComponent(0.3)
        
        // 초기값
        title.text = eventData.title
        location.text = eventData.location
        if eventData.isAllDay {
            if let dayStr = eventData.startDate?.formatted(date: .abbreviated, time: .omitted) {
                startTime.text = dayStr + "  하루 종일"
            }
        } else {
            startTime.text = eventData.startDate?.formatted(date: .abbreviated, time: .shortened)
            if eventData.endDate == nil {
                endTime.text = "  " // 레이아웃을 위한 공백 스트링. 공백이 하나면 간격이 안 맞게 나옴.
            } else {
                endTime.text = eventData.endDate?.formatted(date: .abbreviated, time: .shortened)
            }
        }

        // 레이아웃 관련
        // 폰트
        title.font = .preferredFont(forTextStyle: .headline)
        [location, startTime, endTime].forEach {
            $0.font = .preferredFont(forTextStyle: .callout)
        }
        [location, endTime].forEach {
            $0.textColor = .systemGray
        }

        // 스택뷰
        axis = .horizontal
        spacing = 4
        let titleLocationStackView = UIStackView()
        let timeStackView = UIStackView()
        titleLocationStackView.axis = .vertical
        timeStackView.axis = .vertical
        titleLocationStackView.spacing = 4
        timeStackView.spacing = 4

        titleLocationStackView.addArrangedSubview(title)
        titleLocationStackView.addArrangedSubview(location)
        timeStackView.addArrangedSubview(startTime)
        timeStackView.addArrangedSubview(endTime)

        addArrangedSubview(titleLocationStackView)
        addArrangedSubview(timeStackView)
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}
