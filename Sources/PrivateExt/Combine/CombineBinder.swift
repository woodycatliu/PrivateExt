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
    
    public func bind<S: Subject>(to subject: S) where S.Output == Output {
        return setFailureType(to: S.Failure.self)
            .receive(subscriber: AnySubscriber(subject))
    }

}

extension Publisher {
    
    public func bind<S: Subject>(to subject: S) where S.Output == Output, S.Failure == Failure {
        return receive(subscriber: AnySubscriber(subject))
    }
    
    public func handleEvents(toOutput binder: CombineBinder<Output>,
                             toError errorBinder: CombineBinder<Subscribers.Completion<Failure>>? = nil) -> Publishers.HandleEvents<Self> {
        return handleEvents(receiveOutput: binder.binding, receiveCompletion: errorBinder?.binding)
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
        self.subsContainer.subscription = subscription
        subscription.request(.unlimited)
    }
    
    public var combineIdentifier: CombineIdentifier {
        return CombineIdentifier()
    }
    
    public func cancel() {
        subsContainer.subscription?.cancel()
    }
    
    fileprivate var binding: (Input) -> () {
        return _bind
    }
    
    private let _bind: (Input) -> Void
    
    public func receive(completion: Subscribers.Completion<Failure>) {}
    
    private let subsContainer = SubscriptionContainer()
    
    private class SubscriptionContainer {
        var subscription: Subscription?
    }
}

