import Foundation
import CoreNFC
import libjeid
import Flutter

// MARK: - NFCScannerDelegate

@available(iOS 13.0, *)
protocol LibjeidCardScannerDelegate {
    func libjeidCardScannerDidStartScanning(_ scanner: LibjeidCardScanner)
    
    func libjeidCardScanner(_ scanner: LibjeidCardScanner, didStartConnectingToTag tag: NFCTag)
        
    func libjeidCardScanner(_ scanner: LibjeidCardScanner, didStartParsingTag tag: NFCTag)
    
    func libjeidCardScanner(_ scanner: LibjeidCardScanner, didFailWithError error: Error)
    
    func libjeidCardScanner(_ scanner: LibjeidCardScanner, didSuccessWithData data: CardData)
    
    func libjeidCardScannerDidStopScanning(_ scanner: LibjeidCardScanner)
}

// MARK: - NFCScanner

@available(iOS 13.0, *)
class LibjeidCardScanner: NSObject {
    typealias ScanCompletionHandler = (_ result: (any CardData)?, _ error: Error?) -> Void
    
    static var isAvailable: Bool { NFCReaderSession.readingAvailable }
    
    var delegate: LibjeidCardScannerDelegate?
    var parser: any LibjeidCardParser

    private var session: NFCTagReaderSession?

    init(parser: any LibjeidCardParser, delegate: LibjeidCardScannerDelegate? = nil) {
        self.delegate = delegate
        self.parser = parser
    }
    
    func scan() {
        if (!NFCReaderSession.readingAvailable) {
            self.delegate?.libjeidCardScanner(self, didFailWithError: NfcNotAvailableError())
            return
        }
        
        self.session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: DispatchQueue.global())
        self.session?.begin()
    }
    
    func stopScan(errorMessage: String? = nil) {
        guard self.session?.isReady == true else { return }

        if let nonNullMessage = errorMessage {
            self.session?.invalidate(errorMessage: nonNullMessage)
        } else {
            self.session?.invalidate()
        }
        
        delegate?.libjeidCardScannerDidStopScanning(self)
    }
    
    func setMessage(message: String) {
        self.session?.alertMessage = message
    }
}

// MARK: - NFCTagReaderSessionDelegate

@available(iOS 13.0, *)
extension LibjeidCardScanner: NFCTagReaderSessionDelegate {

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        self.delegate?.libjeidCardScannerDidStartScanning(self)
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        self.delegate?.libjeidCardScanner(self, didFailWithError: error)
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            self.delegate?.libjeidCardScanner(self, didFailWithError: NfcTagUnableToConnectError())
            return
        }
        
        self.delegate?.libjeidCardScanner(self, didStartConnectingToTag: tag)
        
        session.connect(to: tag) { (error: Error?) in
            if let error = error {
                self.delegate?.libjeidCardScanner(self, didFailWithError: error)
                return
            }
            
            self.tagReaderSession(session, didConnect: tag)
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didConnect tag: NFCTag) {        
        self.delegate?.libjeidCardScanner(self, didStartParsingTag: tag)

        do {
            let data = try parser.read(tag: tag)
            self.delegate?.libjeidCardScanner(self, didSuccessWithData: data)
        } catch {
            self.delegate?.libjeidCardScanner(self, didFailWithError: error)
        }
    }
}
