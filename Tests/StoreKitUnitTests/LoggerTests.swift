//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LoggerTests.swift
//
//  Created by Nacho Soto on 11/29/22.

import Nimble
import XCTest

@testable import RevenueCat

// Note: this is in `StoreKitUnitTests` because it modifies the global `Logger.logLevel`
// which means it would interfere with other tests if ran concurrently.
class LoggerTests: TestCase {

    private var logger: TestLogHandler!
    private var previousLogLevel: LogLevel!

    override func setUp() {
        super.setUp()

        self.logger = .init()
        self.previousLogLevel = Logger.logLevel
    }

    override func tearDown() {
        Logger.logLevel = self.previousLogLevel
        self.logger = nil

        super.tearDown()
    }

    func testLogLevelOrderContainsAllLevels() {
        expect(Set(LogLevel.order.keys)) == Set(LogLevel.allCases)
    }

    func testLogLevelOrdering() {
        let levels: [LogLevel] = LogLevel.allCases.shuffled()

        expect(levels.sorted()) == [
            .verbose,
            .debug,
            .info,
            .warn,
            .error
        ]
    }

    func testLoggerLogsMessagesWithHigherLevel() {
        Logger.logLevel = .info
        Logger.warn(Message.test1)

        self.logger.verifyMessageWasLogged(Message.test1, level: .warn)
    }

    func testLoggerLogsMessagesWithHigherLevelThanVerbose() {
        Logger.logLevel = .verbose
        Logger.info(Message.test1)

        self.logger.verifyMessageWasLogged(Message.test1, level: .info)
    }

    func testLoggerLogsMessagesWithSameLevel() {
        Logger.logLevel = .info
        Logger.info(Message.test1)

        self.logger.verifyMessageWasLogged(Message.test1, level: .info)
    }

    func testLoggerDoesNotLogMessagesWithLowerLevel() {
        Logger.logLevel = .info
        Logger.debug(Message.test1)
        Logger.info(Message.test2)

        self.logger.verifyMessageWasNotLogged(Message.test1)
    }

    func testLoggerLogsErrors() {
        let error = Error.error1 as NSError
        Logger.error("Error", error: error)
        self.logger.verifyErrorWasLogged(error)
    }

    func testLoggerLogsErrorsWithDebugLevel() {
        Logger.logLevel = .debug

        let error = Error.error1 as NSError
        Logger.error("Error", error: error)
        self.logger.verifyErrorWasLogged(error)
    }

    func testCreatingErrorsLogsThem() {
        let error = ErrorUtils.customerInfoError()

        self.logger.verifyMessageWasLogged(error.localizedDescription, level: .error, expectedCount: 1)
    }

    func testCreatingErrorsForwardsThem() {
        let error = ErrorUtils.customerInfoError()

        self.logger.verifyErrorWasLogged(error.asPublicError)
    }

    func testPurchasesLogHandler() {
        defer {
            Purchases.restoreLogHandler()
            TestLogHandler.restore()
        }

        var messages: [LoggedMessage] = []

        Purchases.logHandler = { messages.append(.init($0, $1)) }

        Logger.info(Message.test1)
        Logger.warn(Message.test2)

        expect(messages) == [
            .init(.info, "\(LogIntent.info.prefix) \(Message.test1.description)"),
            .init(.warn, "\(LogIntent.warning.prefix) \(Message.test2.description)")
        ]
    }

    func testPurchasesErrorHandler() {
        defer {
            Purchases.restoreLogHandler()
            TestLogHandler.restore()
        }

        var errors: [PublicError] = []

        Purchases.errorHandler = { errors.append($0) }

        Logger.error("Error 1", error: Error.error1 as NSError)
        Logger.error("Error 2", error: Error.error2 as NSError)

        expect(errors) == [
            Error.error1 as NSError,
            Error.error2 as NSError
        ]
    }

}

private extension LoggerTests {

    enum Message: LogMessage {

        case test1
        case test2

        var description: String {
            switch self {
            case .test1: return "Log message 1"
            case .test2: return "Log message 2"
            }
        }

        var category: String { return "debug_logs" }

    }

    struct LoggedMessage: Equatable {

        var level: LogLevel
        var message: String

        init(_ level: LogLevel, _ message: String) {
            self.level = level
            self.message = message
        }

    }

    enum Error: Swift.Error {
        case error1
        case error2
    }

}
