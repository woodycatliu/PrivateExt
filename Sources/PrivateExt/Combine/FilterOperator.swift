//
//  filterTo.swift
//  
//
//  Created by Woody Liu on 2023/7/1.
//

import Combine

extension Publisher {
    
    public func filterTo(_ isIncluded: @escaping (Self.Output) -> Bool) -> AnyPublisher<Output, Failure> {
        self.filter(isIncluded).eraseToAnyPublisher()
    }
    
    public func filterTo(equalTo value: Output) -> AnyPublisher<Output, Failure> where Output: AnyObject&Equatable {
        return self.filterTo { [weak value] output in
            guard let value = value else { return false }
            return value == output
        }
    }
    
    public func filterTo<Value: AnyObject&Equatable>(equalTo value: Value, _ keyPath: KeyPath<Output, Value>) -> AnyPublisher<Output, Failure> {
        let filtor: (Output) -> Bool = { [weak value] output in
            guard let value = value else { return false }
            return output[keyPath: keyPath] == value
        }
        return self.filter(filtor).eraseToAnyPublisher()
    }
    
}
