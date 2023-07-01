//
//  CombineBonjourBrowser.swift
//  
//
//  Created by Woody Liu on 2023/7/1.
//

import Foundation
import Combine
import Network
import PrivateExt

public extension CombineBonjourBrowser {
    
    func start(_ queue: DispatchQueue) {
        _start(queue)
    }
}

public struct CombineBonjourBrowser {
    
    public typealias Service = NWBrowser.Result
    
    public typealias State = NWBrowser.State
    
    public enum Flags: Int {
        case identical
        case interfaceAdded
        case interfaceRemoved
        case metadataChanged
    }

    public static func scan(_ type: String, domain: String? = "local") -> CombineBonjourBrowser {
        let delegate = NWBrowserDelegate()
        let parameters = NWParameters.applicationService
        parameters.includePeerToPeer = true
        let nwbrowser = NWBrowser(for: .bonjour(type: type, domain: domain), using: parameters)
        
        nwbrowser.browseResultsChangedHandler = { newResults, changes in
            delegate.receive(with: newResults, changes: changes)
        }

        nwbrowser.stateUpdateHandler = { state in
            delegate.receive(with: state)
        }
    
        return .init(start: { nwbrowser.start(queue: $0) },
                     service: { delegate.services },
                     updateState: delegate.updateState.removeDuplicates().eraseToAnyPublisher(),
                     didChanged: delegate.didChanged,
                     didFind: delegate.didFind,
                     didRemove: delegate.didRemove,
                     servicesPublisher: delegate.$services.eraseToAnyPublisher())
    }
    
    public init(
        start: @escaping (DispatchQueue) -> Void,
        service: @escaping () -> Set<Service>,
        updateState: AnyPublisher<State, Never>,
        didChanged: AnyPublisher<(old: Service, new: Service, flags: CombineBonjourBrowser.Flags), Never>,
        didFind: AnyPublisher<Service, Never>,
        didRemove: AnyPublisher<Service, Never>,
        servicesPublisher: AnyPublisher<Set<Service>, Never>
    ) {
        self._start = start
        self._service = service
        self.updateState = updateState
        self.didChanged = didChanged
        self.didFind = didFind
        self.didRemove = didRemove
        self.servicesPublisher = servicesPublisher
    }
    
    internal let _start: (DispatchQueue) -> Void
    
    internal let _service: () -> Set<Service>
    
    internal let didChanged: AnyPublisher<(old: Service, new: Service, flags: CombineBonjourBrowser.Flags), Never>
    
    public let updateState: AnyPublisher<State, Never>
    
    public let didFind: AnyPublisher<Service, Never>
    
    public let didRemove: AnyPublisher<Service, Never>
    
    public let servicesPublisher: AnyPublisher<Set<Service>, Never>
}

private class NWBrowserDelegate {
    
    typealias Service = CombineBonjourBrowser.Service

    typealias Flags = CombineBonjourBrowser.Flags
    
    typealias State =  NWBrowser.State
    
    func receive(with state: NWBrowser.State) {
        self.$updateState.send(state)
    }
    
    func receive(with results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) {
        
        for change in changes {
            switch change {
            case .added(let result):
                $didFind.send(result.service)
            case .removed(let result):
                $didRemove.send(result.service)
            case .changed(old: let old, new: let new, flags: let flags):
                $didChanged.send(
                    (old.service,
                     new.service,
                     CombineBonjourBrowser.Flags(flags))
                )
            case .identical: break
            @unknown default: break
            }
        }
        
        self.services = results
    }
    
    @PassthroughBacked
    var updateState: AnyPublisher<State, Never>
    
    @PassthroughBacked
    var didChanged: AnyPublisher<(old: Service, new: Service, flags: Flags), Never>
    
    @PassthroughBacked
    var didFind: AnyPublisher<Service, Never>
    
    @PassthroughBacked
    var didRemove: AnyPublisher<Service, Never>
    
    @Published var services: Set<Service> = []
}

fileprivate extension NWBrowser.Result {
    
    typealias Service = NWBrowser.Result

    var service: Service {
        return self
    }
}

fileprivate typealias OldFlags = NWBrowser.Result.Change.Flags

fileprivate extension OldFlags {
    var BonjourFlagsRawValue: Int {
        switch self {
        case .identical: return 0
        case .interfaceAdded: return 1
        case .interfaceRemoved: return 2
        case .metadataChanged: return 3
        default: return 0
        }
    }
}

fileprivate extension CombineBonjourBrowser.Flags {
    init(_ flags: OldFlags) {
        self.init(rawValue: flags.BonjourFlagsRawValue)!
    }
}
