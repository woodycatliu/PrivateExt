//
//  filterTo.swift
//  
//
//  Created by Woody Liu on 2023/7/1.
//

import Combine

extension Publisher {
    
    public func filter(equalTo value: Output) -> AnyPublisher<Output, Failure> where Output: AnyObject&Equatable {
        return self.filter { [weak value] output in
            guard let value = value else { return false }
            return value == output
        }.eraseToAnyPublisher()
    }
    
    public func filter<Value: AnyObject&Equatable>(_ keyPath: KeyPath<Output, Value>,
                                                   equalTo value: Value) -> AnyPublisher<Output, Failure> {
        let percolator: (Output) -> Bool = { [weak value] output in
            guard let value = value else { return false }
            return output[keyPath: keyPath] == value
        }
        return self.filter(percolator).eraseToAnyPublisher()
    }
    
    public func filter<Value: Equatable>(_ keyPath: KeyPath<Output, Value>,
                                         equalTo value: Value) -> AnyPublisher<Output, Failure> {
        let percolator: (Output) -> Bool = { output in
            return output[keyPath: keyPath] == value
        }
        return self.filter(percolator).eraseToAnyPublisher()
    }
    
}
