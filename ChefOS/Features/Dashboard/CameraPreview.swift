import SwiftUI
import AVFoundation

final class CameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isAuthorized: Bool = false
    @Published var scannedBarcodes: Set<String> = []
    
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let metadataOutput = AVCaptureMetadataOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    
    var onBarcodeScanned: ((String) -> Void)?

    override init() {
        super.init()
        Task { await requestPermissionAndSetup() }
    }

    @MainActor
    private func requestPermissionAndSetup() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            if granted { setupSession() }
        default:
            isAuthorized = false
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input),
            session.canAddOutput(output),
            session.canAddOutput(metadataOutput)
        else { return }

        session.addInput(input)
        session.addOutput(output)
        session.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .code128]
        
        output.isHighResolutionCaptureEnabled = true
        session.commitConfiguration()
        session.startRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for object in metadataObjects {
            guard let readableObject = object as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { continue }
            
            if !scannedBarcodes.contains(stringValue) {
                scannedBarcodes.insert(stringValue)
                onBarcodeScanned?(stringValue)
                HapticManager.shared.play(.light)
            }
        }
    }

    func takePhoto(completion: @escaping (UIImage?) -> Void) {
        guard isAuthorized else { completion(nil); return }
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func captureOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error { print("Capture error: \(error.localizedDescription)") }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            captureCompletion?(nil); captureCompletion = nil; return
        }
        captureCompletion?(image)
        captureCompletion = nil
    }

    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var controller: CameraController

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = controller.isAuthorized ? controller.makePreviewLayer().session : nil
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = controller.makePreviewLayer().session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            guard let previewLayer = layer as? AVCaptureVideoPreviewLayer else {
                fatalError("Expected AVCaptureVideoPreviewLayer but got \(type(of: layer))")
            }
            return previewLayer
        }
    }
}

