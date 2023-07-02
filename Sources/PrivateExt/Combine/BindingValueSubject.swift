//
//  BindingValueSubject.swift
//
//
//  Created by Woody Liu on 2023/7/2.
//

import Combine

@frozen public struct BindingValue<Output>: Publisher {
    
    public typealias Failure = Never
    
    public func accept(_ input: Output) {
        subject.send(input)
    }
    
    public var value: Output {
        get {
            subject.value
        }
    }
    
    public init(_ value: Output) {
        self.init(BindingValueSubject(value))
    }
    
    public init(_ subject: CurrentValueSubject<Output, Failure>) {
        self.init(BindingValueSubject(subject))
    }
    
    public init(with publisher: AnyPublisher<Output, Failure>, value: Output, set: @escaping (Output) -> Void) {
        let subject = BindingValueSubject(with: publisher, value: value, set: set)
        self.init(subject)
    }
    
    public init(_ bindingValue: BindingValue<Output>) {
        let s = bindingValue.subject
        self.subject = s.child()
    }
    
    internal init(_ subject: BindingValueSubject<Output>) {
        self.subject = subject
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
    
    private let subject: BindingValueSubject<Output>
}

// MARK: BindingValueSubject

public extension BindingValueSubject {
    var binding: BindingValue<Output> {
        return BindingValue(self)
    }
}

final public class BindingValueSubject<Output>: Subject {
    
    public typealias Failure = Never
    
    final public var value: Output {
       _get()
    }
    
    public convenience init(_ value: Output) {
        let subject = CurrentValueSubject<Output, Failure>(value)
        self.init(subject)
    }
    
    public convenience init(with publisher: AnyPublisher<Output, Failure>, value: Output, set: @escaping (Output) -> Void) {
        let subject = CurrentValueSubject(with: publisher, value: value)
        self.init(
            set: set,
            get: {
                subject.value
            },
            publisher: subject.eraseToAnyPublisher()
        )
    }
    
    public convenience init(_ subject: CurrentValueSubject<Output, Failure>) {
        self.init(
            set: { value in
                subject.send(value)
            },
            get: {
                subject.value
            },
            publisher: subject.eraseToAnyPublisher()
        )
    }
    
    public init(set: @escaping (Output) -> Void,
                get: @escaping () -> Output,
                publisher: AnyPublisher<Output, Failure>){
        self._set = set
        self._get = get
        self._publisher = publisher
    }
    
    public func send(_ input: Output) {
        _set(input)
    }
    
    public func send(completion: Subscribers.Completion<Never>) {}
    
    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
        _publisher.receive(subscriber: subscriber)
    }
    
    public func send(subscription: Subscription) {}
    
    private convenience init(_ subject: BindingValueSubject<Output>) {
        self.init(set: subject._set, get: subject._get, publisher: subject._publisher)
    }
        
    private let _set: ((Output) -> Void)
    
    private let _get: () -> Output
    
    private let _publisher: AnyPublisher<Output, Failure>
    
}

extension BindingValueSubject {
    
    fileprivate func child() -> BindingValueSubject<Output> {
        return BindingValueSubject(self)
    }
    
}
