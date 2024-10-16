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
    
    //Perception ring visability
    //Boids
    private var avoidanceRingVisible = true
    private var alignmentRingVisible = true
    private var cohesionRingVisible = true
    private var fleeRingVisible = true
    //Predators
    private var predatorVisualRangeRingVisible = true
    private var predatorHuntingRangeRingVisible = true

    
    
    
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
    
    @IBOutlet weak var BoidAlphaOnly: UISwitch!
    
    @IBOutlet weak var PredatorAlphaOnly: UISwitch!
    
    
    
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
        initializeSwitches()
    }
    func initializeSwitches() {
        showBoidAlphaOnlySwitchChanged(BoidAlphaOnly) // Initialisera med aktuellt värde
        showPredatorAlphaOnlySwitchChanged(PredatorAlphaOnly)
        /*showAvoidancePerceptionRingSwitchChanged(avoidanceRingSwitch)
        showAlignmentPerceptionRingSwitchChanged(alignmentRingSwitch)
        showCohesionPerceptionRingSwitchChanged(cohesionRingSwitch)
        showFleePerceptionRingSwitchChanged(fleeRingSwitch)
        showPredatorVisualRangePerceptionRingSwitchChanged(predatorVisualRangeSwitch)
        showPredatorHuntingRangePerceptionRingSwitchChanged(predatorHuntingRangeSwitch)*/
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
    
    @IBAction func showBoidAlphaOnlySwitchChanged(_ sender: UISwitch) {
        guard let boidsChildren = gameScene?.boidsLayer.children else {
            return // Avsluta om det inte finns några barn i boidsLayer
        }

        // Loopa igenom alla boids
        for (index, boidNode) in boidsChildren.enumerated() {
            if let boidNode = boidNode as? SKShapeNode {
                let isLeader = index == 0 // Om detta är ledarboiden

                // Om showBoidAlphaOnly är på, visa bara ledarboidens ringar, annars visa alla
                if sender.isOn {
                    // Om vi visar bara ledaren, dölj alla ringar för andra boids
                    boidNode.childNode(withName: "alignmentRing")?.isHidden = !isLeader || !alignmentRingVisible
                    boidNode.childNode(withName: "avoidanceRing")?.isHidden = !isLeader || !avoidanceRingVisible
                    boidNode.childNode(withName: "cohesionRing")?.isHidden = !isLeader || !cohesionRingVisible
                    boidNode.childNode(withName: "fleeRing")?.isHidden = !isLeader || !fleeRingVisible
                } else {
                    // Annars, visa ringar för alla boids beroende på switcharnas status
                    boidNode.childNode(withName: "alignmentRing")?.isHidden = !alignmentRingVisible
                    boidNode.childNode(withName: "avoidanceRing")?.isHidden = !avoidanceRingVisible
                    boidNode.childNode(withName: "cohesionRing")?.isHidden = !cohesionRingVisible
                    boidNode.childNode(withName: "fleeRing")?.isHidden = !fleeRingVisible
                }
            }
        }
    }
    
    @IBAction func showPredatorAlphaOnlySwitchChanged(_ sender: UISwitch) {
        guard let predatorsChildren = gameScene?.boidsLayer.children else {
            return // Avsluta om det inte finns några barn i boidsLayer
        }

        // Loopa igenom alla predators
        for (index, predatorNode) in predatorsChildren.enumerated() {
            if let predatorNode = predatorNode as? SKShapeNode {
                let isLeader = index == 0 // Om detta är ledarpredatorn

                // Om showPredatorAlphaOnly är på, visa bara ledarpredatorns ringar, annars visa alla
                if sender.isOn {
                    // Visa bara ledarens ringar
                    predatorNode.childNode(withName: "outerChaseRing")?.isHidden = !isLeader || !predatorVisualRangeRingVisible
                    predatorNode.childNode(withName: "innerChaseRing")?.isHidden = !isLeader || !predatorHuntingRangeRingVisible
                } else {
                    // Visa ringar för alla predators beroende på switcharnas status
                    predatorNode.childNode(withName: "outerChaseRing")?.isHidden = !predatorVisualRangeRingVisible
                    predatorNode.childNode(withName: "innerChaseRing")?.isHidden = !predatorHuntingRangeRingVisible
                }
            }
        }
    }
    
    
    @IBAction func showAvoidancePerceptionRingSwitchChanged(_ sender: UISwitch) {
        avoidanceRingVisible = sender.isOn

        guard let boidsChildren = gameScene?.boidsLayer.children else {
            return // Avsluta om det inte finns några barn i boidsLayer
        }

        for boidNode in boidsChildren {
            if let boidNode = boidNode as? SKShapeNode {
                boidNode.childNode(withName: "avoidanceRing")?.isHidden = !avoidanceRingVisible
            }
        }
    }

    @IBAction func showAlignmentPerceptionRingSwitchChanged(_ sender: UISwitch) {
        alignmentRingVisible = sender.isOn

        guard let boidsChildren = gameScene?.boidsLayer.children else {
            return // Avsluta om det inte finns några barn i boidsLayer
        }

        for boidNode in boidsChildren {
            if let boidNode = boidNode as? SKShapeNode {
                boidNode.childNode(withName: "alignmentRing")?.isHidden = !alignmentRingVisible
            }
        }
    }

    @IBAction func showCohesionPerceptionRingSwitchChanged(_ sender: UISwitch) {
        cohesionRingVisible = sender.isOn

        guard let boidsChildren = gameScene?.boidsLayer.children else {
            return // Avsluta om det inte finns några barn i boidsLayer
        }

        for boidNode in boidsChildren {
            if let boidNode = boidNode as? SKShapeNode {
                boidNode.childNode(withName: "cohesionRing")?.isHidden = !cohesionRingVisible
            }
        }
    }

    @IBAction func showFleePerceptionRingSwitchChanged(_ sender: UISwitch) {
        fleeRingVisible = sender.isOn

        guard let boidsChildren = gameScene?.boidsLayer.children else {
            return // Avsluta om det inte finns några barn i boidsLayer
        }

        for boidNode in boidsChildren {
            if let boidNode = boidNode as? SKShapeNode {
                boidNode.childNode(withName: "fleeRing")?.isHidden = !fleeRingVisible
            }
        }
    }

    @IBAction func showPredatorVisualRangePerceptionRingSwitchChanged(_ sender: UISwitch) {
        predatorVisualRangeRingVisible = sender.isOn

        guard let predatorsChildren = gameScene?.boidsLayer.children else {
            return // Avsluta om det inte finns några barn i boidsLayer
        }

        for predatorNode in predatorsChildren {
            if let predatorNode = predatorNode as? SKShapeNode {
                predatorNode.childNode(withName: "outerChaseRing")?.isHidden = !predatorVisualRangeRingVisible
            }
        }
    }

    @IBAction func showPredatorHuntingRangePerceptionRingSwitchChanged(_ sender: UISwitch) {
        predatorHuntingRangeRingVisible = sender.isOn

        guard let predatorsChildren = gameScene?.boidsLayer.children else {
            return // Avsluta om det inte finns några barn i boidsLayer
        }

        for predatorNode in predatorsChildren {
            if let predatorNode = predatorNode as? SKShapeNode {
                predatorNode.childNode(withName: "innerChaseRing")?.isHidden = !predatorHuntingRangeRingVisible
            }
        }
    }
    
    
    
    
}
