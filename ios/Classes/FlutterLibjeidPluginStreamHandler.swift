import Foundation
import Flutter

class FlutterLibjeidPluginEventStreamHandler: NSObject, FlutterStreamHandler {
    var eventSink: FlutterEventSink?
    
    func emit(event: FlutterLibjeidEvent) {
        DispatchQueue.main.async {
            self.eventSink?(event.toJSON());
        }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil

        return nil
    }
}
