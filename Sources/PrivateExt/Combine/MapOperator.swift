//
//  MapOperator.swift
//
//
//  Created by Woody Liu on 2023/7/8.
//

import Combine

extension Publisher {
    
    public func map<T: AnyObject>(to object: T) -> AnyPublisher<T, Failure> {
        return map { [weak object] _ in return object }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    public func map<T: Sendable>(to value: T) -> AnyPublisher<T, Failure> {
        return map { _ in value }.eraseToAnyPublisher()
    }
    
    public func mapToVoid() -> AnyPublisher<Void, Failure> {
        return map(to: Void())
    }
    
}
