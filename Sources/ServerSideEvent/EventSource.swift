import Foundation
import Combine


public class EventSource: NSObject {
    public enum State {
        case connecting
        case open
        case closed
    }

    public var eventPublisher: AnyPublisher<Event, Error> {
        subject.eraseToAnyPublisher()
    }

    private let subject = PassthroughSubject<Event, Error>()
    private let queue = OperationQueue()
    private var state: State = .closed
    private var urlSession: URLSession?
    private var request: URLRequest?
    private var lastEventId: String?
    private let doneToken: Data?
    private var isDone  = false

    private var stateCodeForReconnect: Range<Int> {
        doneToken == nil ? (201..<300) : (200..<300)
    }

    public init(request: URLRequest, urlSessionConfiguration: URLSessionConfiguration? = nil, doneToken: Data? = nil) {
        self.doneToken = doneToken
        super.init()
        queue.maxConcurrentOperationCount = 1
        queue.name = "tw.server.side.event.queue"
        let urlSessionConfiguration = urlSessionConfiguration ?? .default
        urlSessionConfiguration.timeoutIntervalForRequest = TimeInterval(INT_MAX)
        urlSessionConfiguration.timeoutIntervalForResource = TimeInterval(INT_MAX)
        urlSession = URLSession(configuration: urlSessionConfiguration,
                                delegate: self,
                                delegateQueue: queue)
        urlSession?.dataTask(with: addStreamHeader(for: request)).resume()
    }

    private func addStreamHeader(for request: URLRequest) -> URLRequest {
        var request = request
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        if let lastEventId {
            request.setValue(lastEventId, forHTTPHeaderField: "Last-Event-Id")
        }
        self.request = request
        return request
    }

    public func disconnect() {
        state = .closed
        urlSession?.invalidateAndCancel()
    }
}

extension EventSource: URLSessionDataDelegate {
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        state = .open
        completionHandler(.allow)
    }

    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard state == .open else { return }
        let events = Event.parse(data: data)
        guard !events.isEmpty else {  return }
        events.forEach { event in
            subject.send(event)
            switch event {
            case let .id(id): lastEventId = id
            case let .data(data):
                if let doneToken,
                   data.firstRange(of: doneToken) != nil {
                    subject.send(completion: .finished)
                    isDone = true
                }
            default: break
            }
        }
    }

    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            subject.send(completion: .failure(error))
        }

        // Reconnect
        if let request,
           let statusCode = (task.response as? HTTPURLResponse)?.statusCode,
           stateCodeForReconnect.contains(statusCode),
           !isDone {
            state = .connecting
            urlSession?.dataTask(with: addStreamHeader(for: request)).resume()
        } else {
            subject.send(completion: .finished)
        }
    }


    open func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        var newRequest = request
        self.request?.allHTTPHeaderFields?.forEach { key, value in
            newRequest.setValue(value, forHTTPHeaderField: key)
        }
        completionHandler(addStreamHeader(for: newRequest))
    }
}
