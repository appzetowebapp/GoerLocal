import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Look for the image URL in the userInfo dictionary.
            var imageUrlString: String? = nil
            
            // 1. Try fcm_options.image (Standard FCM)
            if let fcmOptions = bestAttemptContent.userInfo["fcm_options"] as? [String: Any] {
                imageUrlString = fcmOptions["image"] as? String
            }
            
            // 2. Try top-level 'image'
            if imageUrlString == nil {
                imageUrlString = bestAttemptContent.userInfo["image"] as? String
            }
            
            // 3. Try legacy gcm.notification.image
            if imageUrlString == nil {
                imageUrlString = bestAttemptContent.userInfo["gcm.notification.image"] as? String
            }

            if let urlString = imageUrlString, let fileUrl = URL(string: urlString) {
                downloadAndSave(url: fileUrl) { (processedPath) in
                    if let path = processedPath {
                        do {
                            let attachment = try UNNotificationAttachment(identifier: "image_attachment", url: path, options: nil)
                            bestAttemptContent.attachments = [attachment]
                        } catch {
                            print("[NotificationService] Attachment error: \(error)")
                        }
                    }
                    contentHandler(bestAttemptContent)
                }
            } else {
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func downloadAndSave(url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { (location, response, error) in
            guard let location = location else {
                completion(nil)
                return
            }
            
            let tmpDir = FileManager.default.temporaryDirectory
            let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
            let fileName = UUID().uuidString + "." + ext
            let destinationURL = tmpDir.appendingPathComponent(fileName)
            
            try? FileManager.default.removeItem(at: destinationURL)
            do {
                try FileManager.default.moveItem(at: location, to: destinationURL)
                completion(destinationURL)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
}
