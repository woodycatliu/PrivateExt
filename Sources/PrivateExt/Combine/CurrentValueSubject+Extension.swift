//
//  CurrentValueSubject+Extension.swift
//  
//
//  Created by Woody Liu on 2023/7/2.
//

import Combine

public extension CurrentValueSubject where Failure == Never {
    
    convenience init(with publisher: AnyPublisher<Output, Failure>, value: Output) {
        self.init(value)
        publisher.receive(subscriber: AnySubscriber(self))
    }
    
    var bindingValue: BindingValue<Output> {
        return BindingValue(self)
    }
    
}
