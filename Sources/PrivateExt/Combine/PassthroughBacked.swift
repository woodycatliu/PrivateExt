//
//  PassthroughBacked.swift
//  BonjourReading
//
//  Created by Woody Liu on 2023/6/9.
//

import Combine

@propertyWrapper
public struct PassthroughBacked<Output> {
    
    private var subject: PassthroughSubject<Output, Never>
    
    public init() {
        subject = PassthroughSubject<Output, Never>()
    }
    
    public var wrappedValue: AnyPublisher<Output, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public var projectedValue: PassthroughBacked<Output> {
        self
    }
    
    public func send(_ value: Output) {
        subject.send(value)
    }
}

public extension PassthroughBacked where Output == Void {
    func send() {
        subject.send()
    }
}
