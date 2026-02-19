import Foundation
import Flutter
import HUMAN

class HumanManager {
    static let shared = HumanManager()

    func start() {
        do {
            let policy = HSPolicy()
            policy.automaticInterceptorPolicy.interceptorType = .none
            try HumanSecurity.start(appId: "PX_APP_ID", policy: policy)
        } catch {
            print("Error: \(error)")
        }
    }

    func setupChannel(with controller: FlutterViewController) {
        let humanChannel = FlutterMethodChannel(
            name: "com.humansecurity/sdk",
            binaryMessenger: controller.binaryMessenger
        )
        humanChannel.setMethodCallHandler {
            (call: FlutterMethodCall, result: @escaping FlutterResult) in

            if call.method == "humanGetHeaders" {
                var json: String?
                do {
                    let headers = HumanSecurity.BD
                        .headersForURLRequest(forAppId: "PX_APP_ID")
                    let data = try JSONSerialization
                        .data(withJSONObject: headers)
                    json = String(data: data, encoding: .utf8)
                } catch {
                    print("Error: \(error)")
                }
                result(json)
            } else if call.method == "humanHandleResponse" {
                if let response = call.arguments as? String,
                   let data = response.data(using: .utf8),
                   let httpURLResponse = HTTPURLResponse(
                       url: URL(string: "https://example.com")!,
                       statusCode: 403,
                       httpVersion: nil,
                       headerFields: nil
                   ) {
                    let handled = HumanSecurity.BD.handleResponse(
                        response: httpURLResponse,
                        data: data
                    ) { challengeResult in
                        result(
                            challengeResult == .solved
                                ? "solved" : "cancelled"
                        )
                    }
                    if handled {
                        return
                    }
                }
                result("false")
            } else {
                result("")
            }
        }
    }
}
