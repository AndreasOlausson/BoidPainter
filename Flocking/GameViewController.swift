//
//  GameViewController.swift
//  Flocking
//
//  Created by Andreas Olausson on 2024-09-25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //GameScene reference
    var gameScene: GameScene?
    
    private var isSettingsPanelVisible = false
    private var isRunningSimulation = false
    
    
    //Outlets
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var settingsPanel: UIView!
    
    @IBOutlet weak var showBoids: UISwitch!
    
    @IBOutlet weak var showArt: UISwitch!
    
    @IBOutlet weak var showImage: UISwitch!
    
    
    @IBOutlet weak var AvoidanceRing: UISwitch!
    
    @IBOutlet weak var AlignmentRing: UISwitch!
    
    @IBOutlet weak var CohesionRing: UISwitch!
    
    @IBOutlet weak var FleeRing: UISwitch!
    
    @IBOutlet weak var predatorVisualRange: UISwitch!
    
    @IBOutlet weak var predatorHuntingRange: UISwitch!
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
                // Lagra referensen till scenen
                self.gameScene = scene as? GameScene
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
        setupLooks(in: self.view)
    }
    
    private func setupLooks(in view: UIView) {
        
        //Settingspanel
        settingsPanel.alpha = 0.5
        
        //Fix z position
        view.bringSubviewToFront(playButton)
        view.bringSubviewToFront(settingsButton)
        view.bringSubviewToFront(settingsPanel)
        
    }

    @IBAction func playButtonPressed(_ sender: UIButton) {
        if let view = self.view as? SKView {
            if let scene = view.scene as? GameScene {
                // Om GameScene redan visas, hantera spelstatus (starta/pausa fåglar)
                scene.toggleBoidMovement()

                // Uppdatera knappens ikon beroende på spelstatus
                sender.setImage(UIImage(systemName: scene.isPlaying ? "pause.fill" : "play.fill"), for: .normal)
            } else {
                // Om GameScene inte visas, skapa och presentera den
                if let newScene = SKScene(fileNamed: "GameScene") as? GameScene {

                    
                    // Ställ in scenstorleken
                    newScene.scaleMode = .aspectFill

                    // Visa scenen
                    view.presentScene(newScene)

                    // Starta boid-rörelsen eftersom scenen är ny
                    newScene.toggleBoidMovement()

                    // Uppdatera knappens ikon till "pause" eftersom vi startar direkt
                    sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                }
            }
        }
    }
    @IBAction func imageUploadButtonPressed(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    // Handling the selected image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            // Notify the GameScene about the selected image
            if let view = self.view as? SKView, let scene = view.scene as? GameScene {
                scene.addImage(selectedImage)
            }
        }
        dismiss(animated: true, completion: nil)
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    @IBAction func toggleSettingsPanel(_ sender: Any) {
        if(isSettingsPanelVisible) {
            settingsPanel.isHidden = false
            isSettingsPanelVisible = false
        } else {
            settingsPanel.isHidden = true
            isSettingsPanelVisible = true
        }
    }
    
    
    @IBAction func showBoidsSwitchChanged(_ sender: UISwitch) {
        guard let gameScene = self.gameScene else { return }
            // Visa eller dölj boidsLayer och alla dess children
            gameScene.boidsLayer.isHidden = !sender.isOn
            // Visa eller dölj alla children till boidsLayer
            for child in gameScene.boidsLayer.children {
                child.isHidden = !sender.isOn
            }
    }
    
    @IBAction func showArtSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            gameScene?.canvasImageView?.isHidden = false
        } else {
            gameScene?.canvasImageView?.isHidden = true
        }
    }
    
    @IBAction func showImageSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            gameScene?.imageLayer.isHidden = false
        } else {
            gameScene?.imageLayer.isHidden = true
        }
    }
    
    
}
