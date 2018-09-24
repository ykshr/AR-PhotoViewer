//
//  ViewController.swift
//  AR-PhotoViewer
//
//  Created by ykshr on 2018/09/10.
//  Copyright © 2018年 ykshr. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Photos

class ViewController: UIViewController, ARSCNViewDelegate {
    var imgAssets = [UIImage]()
    var avUrls = [URL]()

    var person: Dictionary = [
        0: "Everyone",
        1: "Abe"
    ]
    var currentPersonNo = 0

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var personButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        // let scene = SCNScene(named: "art.scnassets/ship.scn")!
        let scene = SCNScene()

        updateImgAssets(personNo: self.currentPersonNo)

        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) {Void in
            let p = CGPoint(x: Int(arc4random() % 1000), y: Int(arc4random() % 1000))
            let hitTestResult = self.sceneView.hitTest(p, types: .existingPlaneUsingExtent)
            if !hitTestResult.isEmpty {
                if let hitResult = hitTestResult.first {
                    let bubbleBoxNode = self.createBubble(image: self.imgAssets[Int(arc4random_uniform(UInt32(self.imgAssets.count)))])

                    bubbleBoxNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y - 0.2, hitResult.worldTransform.columns.3.z)

                    scene.rootNode.addChildNode(bubbleBoxNode)
                }
            }
        }

        // Set the scene to the view
        sceneView.scene = scene
    }

    func updateImgAssets(personNo: Int) -> Void {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "AR_" + String(personNo))
        let collections: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        for i in 0 ..< collections.count {
            let collection = collections.object(at: i)
            let assetCollection: PHAssetCollection = collection as! PHAssetCollection
            let arAssets = PHAsset.fetchAssets(in: assetCollection, options: nil)
            
            self.imgAssets = [UIImage]()
            self.avUrls = [URL]()
            arAssets.enumerateObjects { (asset, index, stop) -> Void in
                let filename: String = asset.value(forKey: "filename") as! String
                let isPhoto: Bool = asset.value(forKey: "isPhoto") as! Bool
                let isVideo: Bool = asset.value(forKey: "isVideo") as! Bool
                
                // Photo
                if (isPhoto) {
                    PHImageManager.default().requestImage(for: asset,
                                                          targetSize: CGSize(width: 400, height: 400),
                                                          contentMode: .aspectFill,
                                                          options: nil) {
                                                            (image, info) -> Void in self.imgAssets.append(image!)
                    }
                    
                // Video
                } else if (isVideo) {
                    PHImageManager.default().requestAVAsset(forVideo: asset,
                                                            options: nil) {
                                                                (avurlAsset, audioMix, info) -> Void in
                                                                let avurlasset = avurlAsset as! AVURLAsset
                                                                self.avUrls.append(avurlasset.url)
                    }
                }
            }
        }
    }

    func createBubble(image: UIImage) -> SCNNode {
        let plane = SCNPlane(width: 0.1, height: 0.1)
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.diffuse.contents = image
        let planeNode = SCNNode(geometry: plane)
        let prx = Float(arc4random_uniform(360)) * (Float.pi / 180)
        let pry = Float(arc4random_uniform(360)) * (Float.pi / 180)
        planeNode.eulerAngles = SCNVector3(prx, pry, 0)

        let sphere = SCNSphere(radius: 0.1)
        sphere.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "ar-bubbleText")
        sphere.firstMaterial?.isDoubleSided = true
        sphere.firstMaterial?.writesToDepthBuffer = false
        sphere.firstMaterial?.blendMode = .screen
        //sphere.firstMaterial?.lightingModel = .physicallyBased
        //sphere.firstMaterial?.metalness.contents = 1.0
        //sphere.firstMaterial?.roughness.contents = 0
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.opacity = 0.1
        let srx = Float(arc4random_uniform(360)) * (Float.pi / 180)
        let sry = Float(arc4random_uniform(360)) * (Float.pi / 180)
        sphereNode.eulerAngles = SCNVector3(srx, sry, 0)

        let bubbleNode = SCNNode()
        bubbleNode.addChildNode(planeNode)
        bubbleNode.addChildNode(sphereNode)
        
        let box = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.0)
        let bubbleBoxNode = SCNNode(geometry: box)
        bubbleBoxNode.addChildNode(bubbleNode)

        // ボックスの外に出す
        let firstAction = SCNAction.move(by: SCNVector3(0, 0.4, 0), duration: 2)
        firstAction.timingMode = .easeOut
        bubbleNode.runAction(firstAction)
        // フワフワさせる
        let secondAction = SCNAction.move(by: SCNVector3(randomNumbers(firstNum: -1.5, secondNum: 1.5 ),randomNumbers(firstNum: 0, secondNum: 3), randomNumbers(firstNum: -1.5, secondNum: 1.5 )), duration: TimeInterval(randomNumbers(firstNum: 10, secondNum: 30)))
        secondAction.timingMode = .easeOut
        bubbleNode.runAction(secondAction, completionHandler: {
            bubbleNode.runAction(SCNAction.fadeOut(duration: 0), completionHandler: {
                DispatchQueue.main.async {
                    self.playSoftImpact()
                }
                bubbleNode.removeFromParentNode()
                bubbleBoxNode.removeFromParentNode()
            })
        })
        
        return bubbleBoxNode
    }
    
    @IBAction func touchPersonButton(_ sender: Any) {
        currentPersonNo = (currentPersonNo + 1 < person.count) ? currentPersonNo + 1 : 0
        personButton.setTitle(person[currentPersonNo], for: .normal)
        updateImgAssets(personNo: currentPersonNo)
    }
    
    func randomNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }

    func playSoftImpact() {
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // configuration.environmentTexturing = .automatic

        configuration.planeDetection = .horizontal

        configuration.detectionImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main)

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    // 追加されたとき
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async(execute: {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                // 平面ジオメトリを作成
                let geometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
                geometry.materials.first?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.5)
                
                let planeNode = SCNNode(geometry: geometry)
                planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)

                node.addChildNode(planeNode)
            }

            if let imageAnchor = anchor as? ARImageAnchor {
                // pass
            }
        })
    }
    
    // 更新されたとき
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async(execute: {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                // 平面ジオメトリのサイズを更新
                for childNode in node.childNodes {
                    guard let plane = childNode.geometry as? SCNPlane else {continue}
                    plane.width = CGFloat(planeAnchor.extent.x)
                    plane.height = CGFloat(planeAnchor.extent.z)
                    break
                }
            }

            if let imageAnchor = anchor as? ARImageAnchor {
                // 平面ジオメトリのサイズを更新
                if (node.childNodes.count == 0) {
                    // AVPlayerを生成する
                    let avPlayer = AVPlayer(url: self.avUrls[Int(arc4random_uniform(UInt32(self.avUrls.count)))])
                    avPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.none;
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(ViewController.didPlayToEnd),
                                                           name: NSNotification.Name("AVPlayerItemDidPlayToEndTimeNotification"),
                                                           object: avPlayer.currentItem)
                    
                    let skScene = SKScene(size: CGSize(width: 1000, height: 1000))
                    let skNode = SKVideoNode(avPlayer: avPlayer)
                    skNode.position = CGPoint(x: skScene.size.width / 2.0, y: skScene.size.height / 2.0)
                    skNode.size = skScene.size
                    skNode.yScale = -1.0
                    skScene.addChild(skNode)
                    
                    // 平面ジオメトリを作成
                    let geometry = SCNPlane(width: CGFloat(imageAnchor.referenceImage.physicalSize.width), height: CGFloat(imageAnchor.referenceImage.physicalSize.height))
                    // geometry.materials.first?.diffuse.contents = UIColor.darkGray.withAlphaComponent(0.5)
                    geometry.materials.first?.diffuse.contents = skScene
                    
                    let planeNode = SCNNode(geometry: geometry)
                    planeNode.eulerAngles.x = -.pi / 2
                    planeNode.runAction(
                        SCNAction.sequence([
                            SCNAction.fadeIn(duration: 3),
                            SCNAction.wait(duration: 15),
                            SCNAction.fadeOut(duration: 3)]),
                        completionHandler: {
                            planeNode.removeFromParentNode()
                    })

                    node.addChildNode(planeNode)
                    
                    skNode.play()

                } else {
                    for childNode in node.childNodes {
                        guard let plane = childNode.geometry as? SCNPlane else { continue }
                        plane.width = CGFloat(imageAnchor.referenceImage.physicalSize.width)
                        plane.height = CGFloat(imageAnchor.referenceImage.physicalSize.height)
                        break
                    }
                }
            }

        })
    }

    // 削除されたとき
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        if let imageAnchor = anchor as? ARImageAnchor {
            for childNode in node.childNodes {
                childNode.removeFromParentNode()
            }
        }
    }

    @objc func didPlayToEnd(notification: NSNotification) {
        let item: AVPlayerItem = notification.object as! AVPlayerItem
        item.seek(to: kCMTimeZero, completionHandler: nil)
    }

/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
