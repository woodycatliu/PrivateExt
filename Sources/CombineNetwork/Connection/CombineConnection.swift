//
//  CombineConnection.swift
//  BonjourReading
//
//  Created by Woody Liu on 2023/6/24.
//

import Foundation
import Combine
import Network
import PrivateExt

public extension CombineConnection {
    
    var maximumDatagramSize: Int {
        return _maximumDatagramSize()
    }
    
    var currentPath: NWPath? {
        return _currentPath()
    }
    
    var parameters: NWParameters {
        return _parameters()
    }
    
    var endpoint: NWEndpoint {
        return _endpoint()
    }
    
    func start(_ queue: DispatchQueue = DispatchQueue(label: "com.CombineConnection.default.queue")) {
        _start(queue)
    }
    
    func restart() {
        _restart()
    }
    
    func sendBatch(with maximumDatagramSize: Int? = nil, content: Data?, contentContext: ContentContext = .defaultMessage, isComplete: Bool?, completion: SendCompletion? = nil) {
        let maximumDatagramSize = maximumDatagramSize ?? self.maximumDatagramSize
        guard let data = content,
        data.count > maximumDatagramSize else {
            self.sendData(content: nil,contentContext: contentContext ,isComplete: isComplete, completion: completion)
            return
        }
        
        self.batch {
            var sandSize = 0
            let count = data.count
            while sandSize < count {
                let prefix = sandSize
                let end = min(maximumDatagramSize, count - sandSize)
                self.sendData(content: data[prefix..<end], contentContext: contentContext, isComplete: isComplete, completion: completion)
                sandSize += end
            }
        }
    }

    func batch(_ completion: @escaping () -> Void) {
        _batch(completion)
    }
    
    func sendData(content: Data?, contentContext: ContentContext = .defaultMessage, isComplete: Bool?, completion: SendCompletion?) {
        _sendData(content, contentContext, isComplete, completion)
    }
    
    func forceCancel() {
        _forceCancel()
    }
    
    func cancelCurrentEndpoint() {
        _cancelCurrentEndpoint()
    }
    
    func cancel() {
        _cancel()
    }
    
}

public struct CombineConnection {
    
    public typealias SendData = (_ content: Data?, _ contentContext: ContentContext?, _ isComplete: Bool?, _ completion: SendCompletion?) -> Void
        
    public typealias State = NWConnection.State
    
    public typealias Parameters = NWParameters
    
    public typealias Endpoint = NWEndpoint
    
    public typealias ContentContext = NWConnection.ContentContext
    
    public typealias ConnectionError = NWError
        
    public static func create(with endpoint: Endpoint, parameters: Parameters, queue: DispatchQueue? = nil) -> CombineConnection {
        
        let nwconnection = NWConnection(to: endpoint, using: parameters)
                
        let connection = CombineConnection.create(by: nwconnection)
                                
        return connection
    }

    public static func create(by nwConnection: NWConnection) -> CombineConnection {
        
        let proxy = NWConnectionProxy()
        
        nwConnection.stateUpdateHandler = {
            proxy.$stateUpdate.send($0)
        }
        
        nwConnection.pathUpdateHandler = {
            proxy.$pathUpdate.send($0)
        }
        
        var receiveMessageHandle: ((NWConnection) -> Void)!
        
        receiveMessageHandle = { nwConnection in
            nwConnection.receive(minimumIncompleteLength: 1,
                                 maximumLength: 1024 * 8)
            { [unowned nwConnection] content, contentContext, isComplete, error in
                proxy.$receiveMessage.send((content, contentContext, isComplete, error))
                if error == nil {
                    receiveMessageHandle(nwConnection)
                }
            }
        }
        
        let receiveMessage = Deferred {
            return proxy.receiveMessage.handleEvents(receiveSubscription: { _ in
                receiveMessageHandle(nwConnection)
            })
        }.eraseToAnyPublisher()
        
        return CombineConnection(
            maximumDatagramSize: {
                nwConnection.maximumDatagramSize
            },
            currentPath: {
                nwConnection.currentPath
            },
            start: {
                nwConnection.start(queue: $0)
            },
            cancel: {
                nwConnection.cancel()
            },
            forceCancel: {
                nwConnection.forceCancel()
            },
            cancelCurrentEndpoint: {
                nwConnection.cancelCurrentEndpoint()
            },
            restart: {
                nwConnection.restart()
            },
            endpoint: {
                nwConnection.endpoint
            },
            parameters: {
                nwConnection.parameters
            },
            sendData: { data, ctxt, isComplete, completion in
                
                let isComplete = isComplete ?? true
                
                let completion = completion == nil ? NWConnection.SendCompletion.idempotent : NWConnection.SendCompletion.contentProcessed(completion!.errorHandle)
                
                let ctxt = ctxt ?? .defaultMessage
                
                nwConnection.send(content: data, contentContext: ctxt, isComplete: isComplete, completion: completion)
            },
            batch: { completion  in
                nwConnection.batch {
                    completion()
                }
            },
            stateUpdate: proxy.stateUpdate,
            betterPathUpdate: proxy.betterPathUpdate,
            pathUpdate: proxy.pathUpdate,
            viabilityUpdate: proxy.viabilityUpdate,
            receiveMessage: receiveMessage
        )
    }
    
    public init(
        maximumDatagramSize: @escaping () -> Int,
        currentPath: @escaping () -> NWPath?,
        start: @escaping (DispatchQueue) -> Void,
        cancel: @escaping () -> Void,
        forceCancel: @escaping () -> Void,
        cancelCurrentEndpoint: @escaping () -> Void,
        restart: @escaping () -> Void,
        endpoint: @escaping () -> NWEndpoint,
        parameters: @escaping () -> NWParameters,
        sendData: @escaping SendData,
        batch: @escaping (_ completion: @escaping () -> Void) -> Void,
        stateUpdate: AnyPublisher<State, Never>,
        betterPathUpdate: AnyPublisher<Bool, Never>,
        pathUpdate: AnyPublisher<NWPath, Never>,
        viabilityUpdate: AnyPublisher<Bool, Never>,
        receiveMessage: AnyPublisher<(Data?, ContentContext?, Bool, ConnectionError?), Never>
    ) {
        
        self._maximumDatagramSize = maximumDatagramSize
        self._currentPath = currentPath
        self._start = start
        self._cancel = cancel
        self._forceCancel = forceCancel
        self._cancelCurrentEndpoint = cancelCurrentEndpoint
        self._restart = restart
        self._endpoint = endpoint
        self._parameters = parameters
        self._sendData = sendData
        self.stateUpdate = stateUpdate
        self.betterPathUpdate = betterPathUpdate
        self.pathUpdate = pathUpdate
        self.viabilityUpdate = viabilityUpdate
        self.receiveMessage = receiveMessage
        self._batch = batch
    }
    
    public let stateUpdate: AnyPublisher<State, Never>
     
    public let betterPathUpdate: AnyPublisher<Bool, Never>
    
    public let pathUpdate: AnyPublisher<NWPath, Never>
    
    public let viabilityUpdate: AnyPublisher<Bool, Never>
    
    public let receiveMessage: AnyPublisher<(Data?, ContentContext?, Bool, ConnectionError?), Never>
     
    let _maximumDatagramSize: () -> Int
    
    let _currentPath: () -> NWPath?
    
    let _start: (DispatchQueue) -> Void
    
    let _cancel: () -> Void
    
    let _forceCancel: () -> Void
    
    let _cancelCurrentEndpoint: () -> Void
    
    let _restart: () -> Void
    
    let _endpoint: () -> NWEndpoint

    let _parameters: () -> NWParameters
    
    let _sendData: SendData
    
    let _batch: (_ completion: @escaping () -> Void) -> Void
    
}

final class NWConnectionProxy {
    
    init() { }
    
    typealias State = NWConnection.State
    
    typealias Parameters = NWParameters
    
    typealias Endpoint = NWEndpoint
    
    typealias ContentContext = NWConnection.ContentContext
    
    typealias ConnectionError = NWError
    
    @PassthroughBacked
    var stateUpdate: AnyPublisher<State, Never>
    
    @PassthroughBacked
    var betterPathUpdate: AnyPublisher<Bool, Never>
    
    @PassthroughBacked
    var pathUpdate: AnyPublisher<NWPath, Never>
    
    @PassthroughBacked
    var viabilityUpdate: AnyPublisher<Bool, Never>
    
    @PassthroughBacked
    var receiveMessage: AnyPublisher<(Data?, ContentContext?, Bool, ConnectionError?), Never>
    
}

public extension CombineConnection {
    
    struct SendCompletion {
                
        public init(errorHandle: @escaping (_ error: ConnectionError?) -> Void) {
            self.errorHandle = errorHandle
        }
        
        /// Completion handler to be invoked when send content has been successfully processed, or failed to send due to an error.
        /// Note that this does not guarantee that the data was sent out over the network, or acknowledge, but only that
        /// it has been consumed by the protocol stack.
        public let errorHandle: (_ error: ConnectionError?) -> Void
        
    }
}
