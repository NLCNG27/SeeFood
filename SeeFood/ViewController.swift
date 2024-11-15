//
//  ViewController.swift
//  SeeFood
//
//  Created by Nguyen Lam on 11/15/24.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.cameraDevice = .front
        imagePicker.allowsEditing = false
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[.originalImage] as? UIImage {
            // Convert the image to sRGB
            if let cgImage = userPickedImage.cgImage, cgImage.colorSpace?.model == .rgb {
                let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
                let context = CIContext()
                let ciImage = CIImage(cgImage: cgImage)
                let convertedImage = ciImage.applyingFilter("CIColorSpaceConverter", parameters: ["inputColorSpace": colorSpace!])
                
                if let finalImage = context.createCGImage(convertedImage, from: convertedImage.extent) {
                    imageView.image = UIImage(cgImage: finalImage)
                } else {
                    imageView.image = userPickedImage
                }
            } else {
                imageView.image = userPickedImage
            }
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }


    
    func classifyImage(image: CIImage) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let model = try? VNCoreMLModel(for: MobileNetV2().model) else {
                fatalError("Could not load CoreML model.")
            }
            
            let request = VNCoreMLRequest(model: model) { request, error in
                guard let results = request.results as? [VNClassificationObservation] else {
                    fatalError("Model failed to process image.")
                }
                
                DispatchQueue.main.async {
                    if let firstResult = results.first {
                        self?.resultLabel.text = firstResult.identifier.contains("hotdog") ? "Hotdog!" : "Not Hotdog!"
                    }
                }
            }
            
            let handler = VNImageRequestHandler(ciImage: image)
            do {
                try handler.perform([request])
            } catch {
                print("Error performing classification: \(error)")
            }
        }
    }



    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

