import Foundation

/// Intercepts OpenAI-compatible requests to Google Gemini's endpoint to preserve and reinject
/// Google's proprietary `thought_signature` / `extra_content` metadata across tool execution turns.
///
/// Models like `gemini-3-flash-preview` and `gemini-2.5-pro` emit a `thought_signature` in their
/// `tool_calls` response and strictly reject subsequent turns with HTTP 400 if the signature is missing.
/// Standard OpenAI clients drop non-standard fields; this protocol transparently caches and reinjects them.
public final class GeminiThoughtSignatureProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var signatureCache: [String: [String: Any]] = [:]
    private static let handledKey = "GeminiThoughtSignatureProtocolHandled"

    private var activeTask: URLSessionDataTask?

    public static func register() {
        URLProtocol.registerClass(GeminiThoughtSignatureProtocol.self)
    }

    public static func unregister() {
        URLProtocol.unregisterClass(GeminiThoughtSignatureProtocol.self)
    }

    public override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url?.absoluteString,
              url.contains("generativelanguage.googleapis.com") else {
            return false
        }
        guard URLProtocol.property(forKey: handledKey, in: request) == nil else {
            return false
        }
        return true
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    public override func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)

        var finalRequest = mutableRequest as URLRequest

        // Reinject cached thought_signatures into outgoing messages if present
        if let bodyData = finalRequest.httpBody ?? extractBodyData(from: finalRequest),
           var json = try? JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any],
           var messages = json["messages"] as? [[String: Any]] {

            var modified = false
            for (mIdx, msg) in messages.enumerated() {
                if let toolCalls = msg["tool_calls"] as? [[String: Any]] {
                    var updatedToolCalls = toolCalls
                    for (tIdx, tc) in toolCalls.enumerated() {
                        if tc["extra_content"] == nil, let id = tc["id"] as? String {
                            Self.lock.lock()
                            let cachedExtra = Self.signatureCache[id]
                            Self.lock.unlock()

                            if let cachedExtra {
                                var copy = tc
                                copy["extra_content"] = cachedExtra
                                updatedToolCalls[tIdx] = copy
                                modified = true
                            }
                        }
                    }
                    if modified {
                        var updatedMsg = msg
                        updatedMsg["tool_calls"] = updatedToolCalls
                        messages[mIdx] = updatedMsg
                    }
                }
            }

            if modified {
                json["messages"] = messages
                if let newBody = try? JSONSerialization.data(withJSONObject: json, options: []) {
                    mutableRequest.httpBody = newBody
                    finalRequest = mutableRequest as URLRequest
                }
            }
        }

        let session = URLSession(configuration: .ephemeral)
        activeTask = session.dataTask(with: finalRequest) { [weak self] data, response, error in
            guard let self else { return }

            if let data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]] {
                for choice in choices {
                    if let message = choice["message"] as? [String: Any],
                       let toolCalls = message["tool_calls"] as? [[String: Any]] {
                        for tc in toolCalls {
                            if let id = tc["id"] as? String,
                               let extra = tc["extra_content"] as? [String: Any] {
                                Self.lock.lock()
                                Self.signatureCache[id] = extra
                                Self.lock.unlock()
                            }
                        }
                    }
                }
            }

            if let response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            if let error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else {
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
        activeTask?.resume()
    }

    public override func stopLoading() {
        activeTask?.cancel()
        activeTask = nil
    }

    private func extractBodyData(from req: URLRequest) -> Data? {
        guard let stream = req.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }
        return data.isEmpty ? nil : data
    }
}
