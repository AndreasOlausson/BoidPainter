//
//  AccordionView.swift
//  Flocking
//
//  Created by Andreas Olausson on 2024-10-09.
//

import UIKit

class AccordionView: UIView {
    
    private var contentView: UIView!
    private var isExpanded = false
    private let contentHeight: CGFloat = 200 // Höjden på innehållet
    private var heightConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAccordion()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAccordion()
    }
    
    private func setupAccordion() {
        // Skapa en knapp för att toggla expansion
        let headerButton = UIButton(type: .system)
        headerButton.setTitle("Toggle Content", for: .normal)
        headerButton.addTarget(self, action: #selector(toggleContent), for: .touchUpInside)
        
        // Skapa headerView
        let headerView = UIView()
        headerView.addSubview(headerButton)
        headerButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerButton.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        // Skapa contentView (som ska expanderas/kollapsas)
        contentView = UIView()
        contentView.backgroundColor = .lightGray
        
        let contentLabel = UILabel()
        contentLabel.text = "Här är ditt dolda innehåll"
        contentLabel.numberOfLines = 0
        contentView.addSubview(contentLabel)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            contentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        // Lägg till både header och content i en stackView
        let stackView = UIStackView(arrangedSubviews: [headerView, contentView])
        stackView.axis = .vertical
        stackView.spacing = 8
        addSubview(stackView)
        
        // Placera stackView
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Ställ in contentView höjd (startar som 0 om den är kollapsad)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
    }
    
    @objc func toggleContent() {
        isExpanded.toggle()
        let newHeight: CGFloat = isExpanded ? contentHeight : 0
        
        UIView.animate(withDuration: 0.3) {
            self.heightConstraint.constant = newHeight
            self.layoutIfNeeded() // Uppdatera layouten
        }
    }
}
