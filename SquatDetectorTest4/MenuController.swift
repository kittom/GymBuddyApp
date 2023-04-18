//
//  MenuController.swift
//  SquatDetectorTest4
//
//  Created by Felix Bernstein on 08/04/2023.
//

import UIKit

class MenuController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(shareButton)

            // Set up constraints for the share button
            NSLayoutConstraint.activate([
                shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            ])
        view.addSubview(showFilesButton)

            NSLayoutConstraint.activate([
                showFilesButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                showFilesButton.bottomAnchor.constraint(equalTo: shareButton.topAnchor, constant: -20)
            ])

        // Do any additional setup after loading the view.
    }
    
    
    
    
    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share Latest CSV", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside) //Ignore the warning you may get here, if you use the suggested fix the app will crash
        return button
    }()
    
    
    private let showFilesButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Show Files", for: .normal)
        button.addTarget(self, action: #selector(showFilesList), for: .touchUpInside) //Ignore the warning you may get here, if you use the suggested fix the app will crash
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    @objc private func showFilesList() {
        let filesListViewController = FilesListViewController()
        let navigationController = UINavigationController(rootViewController: filesListViewController)
        navigationController.modalPresentationStyle = .automatic
        present(navigationController, animated: true, completion: nil)
    }

    @objc private func shareButtonTapped() {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not find the app's documents directory")
            return
        }

        let directoryContents: [URL]
        do {
            directoryContents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        } catch {
            print("Error: Could not list the contents of the documents directory: \(error)")
            return
        }

        // Find the latest CSV file
        let csvFiles = directoryContents.filter { $0.pathExtension == "csv" }
        guard let latestCSVFile = csvFiles.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }).first else {
            print("Error: No CSV files found")
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [latestCSVFile], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }

}
