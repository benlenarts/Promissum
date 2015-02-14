//
//  PromiseSource.swift
//  Promissum
//
//  Created by Tom Lokhorst on 2014-10-11.
//  Copyright (c) 2014 Tom Lokhorst. All rights reserved.
//

import Foundation

public class PromiseSource<T> {
  typealias ResultHandler = Result<T> -> Void
  public let promise: Promise<T>!
  public var warnUnresolvedDeinit: Bool

  private var handlers: [Result<T> -> Void] = []

  private let onAddHandler: ((Promise<T>, ResultHandler) -> Void)?

  public convenience init(warnUnresolvedDeinit: Bool = true) {
    self.init(onAddHandler: nil, warnUnresolvedDeinit: warnUnresolvedDeinit)
  }

  public init(onAddHandler: ((Promise<T>, ResultHandler) -> Void)?, warnUnresolvedDeinit: Bool) {
    self.onAddHandler = onAddHandler
    self.warnUnresolvedDeinit = warnUnresolvedDeinit

    self.promise = Promise(source: self)
  }

  deinit {
    if warnUnresolvedDeinit {
      switch promise.state {
      case .Unresolved:
        println("PromiseSource.deinit: WARNING: Unresolved PromiseSource deallocated, maybe retain this object?")
      default:
        break
      }
    }
  }

  public func resolve(value: T) {

    switch promise.state {
    case State<T>.Unresolved:
      promise.state = State<T>.Resolved(Box(value))

      executeResultHandlers(.Value(Box(value)))
    default:
      break
    }
  }

  public func reject(error: NSError) {

    switch promise.state {
    case State<T>.Unresolved:
      promise.state = State<T>.Rejected(error)

      executeResultHandlers(.Error(error))
    default:
      break
    }
  }

  internal func addHander(handler: Result<T> -> Void) {
    if let onAddHandler = onAddHandler {
      onAddHandler(promise, handler)
    }
    else {
      handlers.append(handler)
    }
  }

  private func executeResultHandlers(result: Result<T>) {

    // Call all previously scheduled handlers
    callHandlers(result, handlers)

    // Cleanup
    handlers = []
  }
}

internal func callHandlers<T>(arg: T, handlers: [T -> Void]) {
  for handler in handlers {
    handler(arg)
  }
}
