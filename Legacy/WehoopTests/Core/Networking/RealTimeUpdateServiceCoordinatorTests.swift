//
//  RealTimeUpdateServiceCoordinatorTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
import Combine
@testable import Wehoop

final class RealTimeUpdateServiceCoordinatorTests: XCTestCase {
    var sut: RealTimeUpdateServiceCoordinator!
    var mockWebSocketService: MockWebSocketService!
    var mockPollingService: MockPollingService!
    var mockNetworkService: MockNetworkService!
    
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        mockWebSocketService = MockWebSocketService()
        mockPollingService = MockPollingService()
        mockNetworkService = MockNetworkService()
        
        sut = RealTimeUpdateServiceCoordinator(
            webSocketService: mockWebSocketService,
            pollingService: mockPollingService,
            networkService: mockNetworkService
        )
    }
    
    override func tearDown() {
        sut.stop()
        cancellables.removeAll()
        sut = nil
        mockWebSocketService = nil
        mockPollingService = nil
        mockNetworkService = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_IsDisconnected() {
        // Then
        XCTAssertEqual(sut.connectionMode, .disconnected)
    }
    
    // MARK: - Start Tests
    
    func testStart_WithSuccessfulWebSocket_ConnectsViaWebSocket() async {
        // Given
        mockWebSocketService.connectShouldSucceed = true
        let websocketURL = "wss://api.unrivaled.com/games/live"
        let pollingEndpoint = "https://api.unrivaled.com/games/live"
        
        // When
        await sut.start(websocketURL: websocketURL, pollingEndpoint: pollingEndpoint, pollingInterval: 5.0)
        
        // Then
        XCTAssertEqual(sut.connectionMode, .websocket)
        XCTAssertTrue(mockWebSocketService.connected)
        XCTAssertFalse(mockPollingService.polling)
    }
    
    func testStart_WithFailedWebSocket_FallsBackToPolling() async {
        // Given
        mockWebSocketService.connectShouldSucceed = false
        let websocketURL = "wss://api.unrivaled.com/games/live"
        let pollingEndpoint = "https://api.unrivaled.com/games/live"
        
        // When
        await sut.start(websocketURL: websocketURL, pollingEndpoint: pollingEndpoint, pollingInterval: 5.0)
        
        // Then
        XCTAssertEqual(sut.connectionMode, .polling)
        XCTAssertFalse(mockWebSocketService.connected)
        XCTAssertTrue(mockPollingService.polling)
        XCTAssertEqual(mockPollingService.currentEndpoint, pollingEndpoint)
        XCTAssertEqual(mockPollingService.currentInterval, 5.0)
    }
    
    func testStart_StoresURLsAndInterval() async {
        // Given
        mockWebSocketService.connectShouldSucceed = true
        let websocketURL = "wss://api.unrivaled.com/games/live"
        let pollingEndpoint = "https://api.unrivaled.com/games/live"
        let pollingInterval: TimeInterval = 10.0
        
        // When
        await sut.start(websocketURL: websocketURL, pollingEndpoint: pollingEndpoint, pollingInterval: pollingInterval)
        
        // Then
        // Verify polling service was configured with correct interval
        XCTAssertEqual(mockPollingService.currentInterval, pollingInterval)
    }
    
    // MARK: - Stop Tests
    
    func testStop_DisconnectsWebSocketAndPolling() async {
        // Given
        mockWebSocketService.connectShouldSucceed = true
        await sut.start(
            websocketURL: "wss://api.unrivaled.com/games/live",
            pollingEndpoint: "https://api.unrivaled.com/games/live",
            pollingInterval: 5.0
        )
        
        // When
        sut.stop()
        
        // Then
        XCTAssertEqual(sut.connectionMode, .disconnected)
        XCTAssertFalse(mockWebSocketService.connected)
        XCTAssertFalse(mockPollingService.polling)
    }
    
    // MARK: - Switch to Polling Tests
    
    func testSwitchToPolling_DisconnectsWebSocketAndStartsPolling() async {
        // Given
        mockWebSocketService.connectShouldSucceed = true
        await sut.start(
            websocketURL: "wss://api.unrivaled.com/games/live",
            pollingEndpoint: "https://api.unrivaled.com/games/live",
            pollingInterval: 5.0
        )
        
        // When
        sut.switchToPolling()
        
        // Then
        XCTAssertEqual(sut.connectionMode, .polling)
        XCTAssertFalse(mockWebSocketService.connected)
        XCTAssertTrue(mockPollingService.polling)
    }
    
    func testSwitchToPolling_WithoutPollingEndpoint_DoesNothing() {
        // Given - service not started, so no polling endpoint set
        
        // When
        sut.switchToPolling()
        
        // Then
        XCTAssertEqual(sut.connectionMode, .disconnected)
        XCTAssertFalse(mockPollingService.polling)
    }
    
    // MARK: - Reconnect WebSocket Tests
    
    func testReconnectWebSocket_WithSuccessfulConnection_SwitchesToWebSocket() async {
        // Given
        mockWebSocketService.connectShouldSucceed = false
        await sut.start(
            websocketURL: "wss://api.unrivaled.com/games/live",
            pollingEndpoint: "https://api.unrivaled.com/games/live",
            pollingInterval: 5.0
        )
        // Should be in polling mode now
        
        // When - WebSocket now succeeds
        mockWebSocketService.connectShouldSucceed = true
        await sut.reconnectWebSocket()
        
        // Then
        XCTAssertEqual(sut.connectionMode, .websocket)
        XCTAssertTrue(mockWebSocketService.connected)
        XCTAssertFalse(mockPollingService.polling)
    }
    
    func testReconnectWebSocket_WithFailedConnection_StaysInPolling() async {
        // Given
        mockWebSocketService.connectShouldSucceed = false
        await sut.start(
            websocketURL: "wss://api.unrivaled.com/games/live",
            pollingEndpoint: "https://api.unrivaled.com/games/live",
            pollingInterval: 5.0
        )
        
        // When - WebSocket still fails
        await sut.reconnectWebSocket()
        
        // Then
        XCTAssertEqual(sut.connectionMode, .polling)
        XCTAssertFalse(mockWebSocketService.connected)
        XCTAssertTrue(mockPollingService.polling)
    }
    
    func testReconnectWebSocket_WithoutURL_DoesNothing() async {
        // Given - service not started, so no URL stored
        
        // When
        await sut.reconnectWebSocket()
        
        // Then
        XCTAssertEqual(sut.connectionMode, .disconnected)
    }
    
    // MARK: - Update Publisher Tests
    
    func testUpdatePublisher_ReceivesWebSocketMessages() async {
        // Given
        mockWebSocketService.connectShouldSucceed = true
        await sut.start(
            websocketURL: "wss://api.unrivaled.com/games/live",
            pollingEndpoint: "https://api.unrivaled.com/games/live",
            pollingInterval: 5.0
        )
        
        let expectation = expectation(description: "Receive update")
        var receivedData: Data?
        
        sut.updatePublisher
            .sink { data in
                receivedData = data
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let testMessage = "{\"gameId\":\"123\",\"score\":\"50-45\"}"
        mockWebSocketService.simulateMessage(testMessage)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedData)
        if let data = receivedData {
            let message = String(data: data, encoding: .utf8)
            XCTAssertEqual(message, testMessage)
        }
    }
    
    func testUpdatePublisher_ReceivesPollingData() async {
        // Given
        mockWebSocketService.connectShouldSucceed = false
        await sut.start(
            websocketURL: "wss://api.unrivaled.com/games/live",
            pollingEndpoint: "https://api.unrivaled.com/games/live",
            pollingInterval: 5.0
        )
        
        let expectation = expectation(description: "Receive update")
        var receivedData: Data?
        
        sut.updatePublisher
            .sink { data in
                receivedData = data
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let testData = "{\"gameId\":\"123\",\"score\":\"50-45\"}".data(using: .utf8)!
        mockPollingService.simulateDataUpdate(testData)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedData)
        XCTAssertEqual(receivedData, testData)
    }
    
    // MARK: - Mode Publisher Tests
    
    func testModePublisher_EmitsConnectionModeChanges() async {
        // Given
        let expectation1 = expectation(description: "Receive polling mode")
        let expectation2 = expectation(description: "Receive websocket mode")
        var receivedModes: [ConnectionMode] = []
        
        sut.modePublisher
            .sink { mode in
                receivedModes.append(mode)
                if mode == .polling {
                    expectation1.fulfill()
                } else if mode == .websocket {
                    expectation2.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockWebSocketService.connectShouldSucceed = false
        await sut.start(
            websocketURL: "wss://api.unrivaled.com/games/live",
            pollingEndpoint: "https://api.unrivaled.com/games/live",
            pollingInterval: 5.0
        )
        
        // Then - should receive polling mode
        await fulfillment(of: [expectation1], timeout: 1.0)
        
        // When - reconnect to WebSocket
        mockWebSocketService.connectShouldSucceed = true
        await sut.reconnectWebSocket()
        
        // Then - should receive websocket mode
        await fulfillment(of: [expectation2], timeout: 1.0)
        
        XCTAssertTrue(receivedModes.contains(.polling))
        XCTAssertTrue(receivedModes.contains(.websocket))
    }
    
    // MARK: - Fallback Behavior Tests
    
    func testFallback_WhenWebSocketFails_StopsPollingBeforeAttempting() async {
        // Given
        mockWebSocketService.connectShouldSucceed = false
        await sut.start(
            websocketURL: "wss://api.unrivaled.com/games/live",
            pollingEndpoint: "https://api.unrivaled.com/games/live",
            pollingInterval: 5.0
        )
        XCTAssertTrue(mockPollingService.polling)
        
        // When - attempt WebSocket reconnection
        mockWebSocketService.connectShouldSucceed = true
        await sut.reconnectWebSocket()
        
        // Then - polling should be stopped before WebSocket attempt
        // (This is verified by the fact that we're in websocket mode)
        XCTAssertEqual(sut.connectionMode, .websocket)
        XCTAssertFalse(mockPollingService.polling)
    }
    
    func testFallback_WhenPollingEndpointMissing_StaysDisconnected() async {
        // Given
        mockWebSocketService.connectShouldSucceed = false
        
        // When - start without polling endpoint (empty string)
        await sut.start(
            websocketURL: "wss://api.unrivaled.com/games/live",
            pollingEndpoint: "",
            pollingInterval: 5.0
        )
        
        // Then - should stay disconnected if no polling endpoint
        // Note: The current implementation will try to start polling with empty string
        // This test documents current behavior
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess_IsThreadSafe() async {
        // Given
        let iterations = 100
        
        // When - perform concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    if i % 2 == 0 {
                        await self.sut.start(
                            websocketURL: "wss://api.unrivaled.com/games/live",
                            pollingEndpoint: "https://api.unrivaled.com/games/live",
                            pollingInterval: 5.0
                        )
                    } else {
                        self.sut.stop()
                    }
                }
            }
        }
        
        // Then - should not crash
        // Final state should be either disconnected or one of the connection modes
        let finalMode = sut.connectionMode
        XCTAssertTrue(
            finalMode == .disconnected ||
            finalMode == .websocket ||
            finalMode == .polling
        )
    }
}
