//
//  Test+Extensions.swift
//  UnrivaledTests
//
//  Created by E on 1/5/26.
//

import Foundation
import XCTest

extension XCTestCase {
    func XCTAssertGreaterThanOrEqualWithAccuracy(
        _ expression1: Double,
        _ expression2: Double,
        accuracy: Double,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line) {

        let assertionMessage = message.isEmpty ? "XCTAssertGreaterThanOrEqualWithAccuracy failed: (\"\(expression1)\") is not greater than or equal to (\"\(expression2)\") within accuracy (\"\(accuracy)\")" : message

        if !(expression1 >= expression2 - accuracy) {
            XCTFail(assertionMessage, file: file, line: line)
        }
    }
}
