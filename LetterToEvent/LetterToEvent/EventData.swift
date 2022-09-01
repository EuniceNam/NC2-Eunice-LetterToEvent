//
//  Event+.swift
//  LetterToEvent
//
//  Created by Hyorim Nam on 2022/08/30.
//

import Foundation

struct EventData {
    var title: String
    var startDate: Date?
    var endDate: Date?
    var isAllDay: Bool = false
    var location: String?

    init(text: String) {
        title = ""
        let words = text.components(separatedBy: " ")
        // 월 일 시 분
        var startDateArray: [Int?] = [nil, nil, nil, nil]
        var endDateArray: [Int?] = [nil, nil, nil, nil]
        var isLocationExist = false
        for word in words {
            var isWordUsed = false
            if word.contains(":") {
                let time = word.split(separator: ":").compactMap{str in Int(str)}
                if time.count == 2 {
                    if startDateArray[2] == nil {
                        startDateArray[2] = time[0]
                        startDateArray[3] = time[1]
                        isWordUsed = true
                    } else if endDateArray[2] == nil {
                        endDateArray[2] = time[0]
                        endDateArray[3] = time[1]
                        isWordUsed = true
                    }
                }
            } else if word.contains(".") {
                var md = word.split(separator: ".").compactMap{str in Int(str)}
                if md.count == 2 {
                    if startDateArray[0] == nil {
                        startDateArray[0] = md[0]
                        startDateArray[1] = md[1]
                        isWordUsed = true
                    } else if endDateArray[0] == nil {
                        endDateArray[0] = md[0]
                        endDateArray[1] = md[1]
                        isWordUsed = true
                    }
                }
            } else if word.contains("@") {
                let tmpArr = word.components(separatedBy: "@")
                if !tmpArr[0].isEmpty {
                    elseText(tmpArr[0])
                }
                isLocationExist = true
                if !tmpArr[1].isEmpty {
                    elseText(tmpArr[1])
                }
            }
            if !isWordUsed {
                elseText(word)
            }
        }
        if title.isEmpty {
            title = "No title"
        }
        
        if !startDateArray.compactMap {$0}.isEmpty {
            if startDateArray[3] == nil {
                isAllDay = true
            }
            let startDateComponent = DateComponents(
                year: Calendar.current.component(.year, from: Date.now),
                month: startDateArray[0],
                day: startDateArray[1],
                hour: startDateArray[2],
                minute: startDateArray[3])
            self.startDate = Calendar.current.date(from: startDateComponent)
        }
        if !endDateArray.compactMap {$0}.isEmpty {
            let endDateComponent = DateComponents(
                year: Calendar.current.component(.year, from: Date.now),
                month: endDateArray[0],
                day: endDateArray[1],
                hour: endDateArray[2],
                minute: endDateArray[3])
            self.endDate = Calendar.current.date(from: endDateComponent)
        }
        func elseText(_ text: String) {
            if isLocationExist {
                if location == nil || location == "" {
                    location = text
                } else {
                    location! += " "
                    location! += text
                }
            } else {
                if !title.isEmpty {
                    title += " "
                }
                title += text
            }
        }
    }
    func isValidEvent() -> Bool {
        if startDate == nil {
            return false
        } else {
            return true
        }
    }
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일 hh시 mm분"
        let str = "title: \(title)\n"
            + "start date: \(formatter.string(for: startDate))\n"
            + "end date: \(formatter.string(for: endDate))\n"
            + "isAllDay: \(isAllDay)\n"
            + "location: \(location)\n"
            + "\n"
        return str
    }
}

enum TRModel: Int {
    case VNRv2
    case MLKit2v3
}
