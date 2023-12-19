
import UIKit
import Flutter
import libjeid
import CoreNFC

@available(iOS 13.0, *)
public class FlutterLibjeidPlugin: NSObject {
    var eventStream: FlutterLibjeidPluginEventStreamHandler
    var cardScanner: LibjeidCardScanner?

    init(eventStream: FlutterLibjeidPluginEventStreamHandler) {
        self.eventStream = eventStream
    }
}

// MARK: - FlutterPlugin

@available(iOS 13.0, *)
extension FlutterLibjeidPlugin: FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let eventStream = FlutterLibjeidPluginEventStreamHandler()
        let instance = FlutterLibjeidPlugin(eventStream: eventStream)

        let channel = FlutterMethodChannel(name: "flutter_libjeid", binaryMessenger: registrar.messenger())

        let streamChannel = FlutterEventChannel(name: "flutter_libjeid_card_data_event", binaryMessenger: registrar.messenger())
        streamChannel.setStreamHandler(eventStream)

        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "stopScan" {
            self.cardScanner?.stopScan()
            return
        }
        
        if call.method == "setMessage" {
            guard let args = call.arguments as? Dictionary<String, Any>, let message = args["message"] as? String else {
                result(InvalidMethodArgumentsError().toFlutterError())
                return
            }
            self.cardScanner?.setMessage(message: message)
        }

        do {
            guard let parser = try LibjeidCardParserFactory.make(fromFlutterMethod: call) else {
                result(FlutterMethodNotImplemented)
                return
            }

            // Stop the previous scanning session (if any)
            self.cardScanner?.stopScan()

            self.cardScanner = LibjeidCardScanner(parser: parser, delegate: self)
            self.cardScanner?.scan()
        } catch let error as FlutterLibjeidError {
            result(error.toFlutterError())
        } catch {
            result(UnknownError(message: error.localizedDescription).toFlutterError())
        }
    }
    
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        self.cardScanner?.stopScan()
    }
}

// MARK: - LibjeidCardScannerDelegate

@available(iOS 13.0, *)
extension FlutterLibjeidPlugin: LibjeidCardScannerDelegate {
    func libjeidCardScannerDidStartScanning(_ scanner: LibjeidCardScanner) {
        eventStream.emit(event: .scanning)
    }
    
    func libjeidCardScanner(_ scanner: LibjeidCardScanner, didStartConnectingToTag tag: NFCTag) {
        eventStream.emit(event: .connecting)
    }

    func libjeidCardScanner(_ scanner: LibjeidCardScanner, didStartParsingTag tag: NFCTag) {
        eventStream.emit(event: .parsing)
    }

    func libjeidCardScanner(_ scanner: LibjeidCardScanner, didFailWithError error: Error) {
        eventStream.emit(event: .failed(error: FlutterLibjeidError.from(error)))
    }
    
    func libjeidCardScanner(_ scanner: LibjeidCardScanner, didSuccessWithData data: CardData) {
        eventStream.emit(event: .success(data: data))
    }
    
    func libjeidCardScannerDidStopScanning(_ scanner: LibjeidCardScanner) {
        eventStream.emit(event: .cancelled)
    }
}
