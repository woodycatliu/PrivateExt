//
//  File.swift
//  
//
//  Created by Woody Liu on 2023/7/1.
//

import Foundation
import CFNetwork

public typealias HTTPMessage = CFHTTPMessage

public extension HTTPMessage {

    var requestURL: URL? {
        return CFHTTPMessageCopyRequestURL(self).map { $0.takeRetainedValue() as URL }
    }

    var requestMethod: String? {
        return CFHTTPMessageCopyRequestMethod(self).map { $0.takeRetainedValue() as String }
    }

    var data: Data? {
        return CFHTTPMessageCopySerializedMessage(self).map { $0.takeRetainedValue() as Data }
    }

    func setBody(data: Data) {
        CFHTTPMessageSetBody(self, data as CFData)
    }

    func setValue(_ value: String?, forHeaderField field: String) {
        CFHTTPMessageSetHeaderFieldValue(self, field as CFString, value as CFString?)
    }

    func value(forHeaderField field: String) -> String? {
        return CFHTTPMessageCopyHeaderFieldValue(self, field as CFString).map { $0.takeRetainedValue() as String }
    }

    // 從請求訊息的原始資料解析出 HTTPMessage 的工廠方法。
    static func request(data: Data) -> HTTPMessage? {

        let request =  CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true).takeRetainedValue()
        let bytes = data.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }

        return CFHTTPMessageAppendBytes(request, bytes, data.count) ? request : nil
    }

    // 用我們提供的資訊建構出回應訊息的 HTTPMessage 的工廠方法。
    static func response(statusCode: Int, statusDescription: String?, htmlString: String) -> HTTPMessage {

        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, statusDescription as CFString?, kCFHTTPVersion1_1).takeRetainedValue()

        // 提供一些基本標頭欄位。
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: Date())
        response.setValue(dateString, forHeaderField: "Date")
        response.setValue("My Swift HTTP Server", forHeaderField: "Server")
        response.setValue("close", forHeaderField: "Connection")
        response.setValue("text/html", forHeaderField: "Content-Type")
        response.setValue("\(htmlString.count)", forHeaderField: "Content-Length")

        // 插入回應內容（這裡是一段 HTML 字串）。
        let body = htmlString.data(using: .utf8)!
        response.setBody(data: body)

        return response
    }
}
