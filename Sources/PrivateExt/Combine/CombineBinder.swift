//
//  CombineBinder.swift
//
//
//  Created by Woody Liu on 2023/7/2.
//

import Combine
import Foundation

extension Publisher where Failure == Never {
    
    public func bind(to binder: CombineBinder<Output>) -> AnyCancellable {
        subscribe(binder)
        return AnyCancellable(binder)
    }
    
    public func handleEvents(to binder: CombineBinder<Output>) -> Publishers.HandleEvents<Self> {
        return handleEvents(receiveOutput: binder.binding)
    }
}

public struct CombineBinder<Input>: Subscriber, Cancellable {
    
    public typealias Failure = Never
    
    public init<Base: AnyObject, Scheduler: Combine.Scheduler>(_ base: Base,
                                                                 scheduler: Scheduler = DispatchQueue.main,
                                                                 binding: @escaping (Base, Input) -> Void)  {
        self._bind = { [weak base] input in
            scheduler.schedule { [weak base] in
                if let base = base {
                    binding(base, input)
                }
            }
        }
    }
    
    public func receive(_ input: Input) -> Subscribers.Demand {
        self._bind(input)
        return .unlimited
    }
    
    public func receive(subscription: Subscription) {
        self.subscontainter.subscription = subscription
        subscription.request(.unlimited)
    }
    
    public var combineIdentifier: CombineIdentifier {
        return CombineIdentifier()
    }
    
    public func cancel() {
        subscontainter.subscription?.cancel()
    }
    
    fileprivate var binding: (Input) -> () {
        return _bind
    }
    
    private let _bind: (Input) -> Void
    
    public func receive(completion: Subscribers.Completion<Failure>) {}
    
    private let subscontainter = SubscriptionContainer()
    
    private class SubscriptionContainer {
        var subscription: Subscription?
    }
}

