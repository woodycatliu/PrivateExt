//
//  MapOperator.swift
//
//
//  Created by Woody Liu on 2023/7/8.
//

import Combine

public extension Publisher {
    
    func map<T>(to value: T) -> AnyPublisher<T, Failure> {
        return map { _ in value }.eraseToAnyPublisher()
    }
    
    func mapToVoid() -> AnyPublisher<Void, Failure> {
        return map(to: Void())
    }
   
    
}
