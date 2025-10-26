//
//  MovieDetailsWireframe.swift
//  YouMovie
//
//  Created by Michael Douglas on 26/11/19.
//  Copyright © 2019 Michael Douglas. All rights reserved.
//

import UIKit
import SafariServices

class MovieDetailsWireframe: NSObject {

    // MARK: - Viper Properties

    private(set) weak var view: MovieDetailsView!

    // MARK: - Private Properties

    private let nibName = String(describing: MovieDetailsView.self)

    // MARK: - Private Methods

    private func setupView(with movie: MovieEntity) -> MovieDetailsView {

        let view = MovieDetailsView(nibName: self.nibName, bundle: nil)
        let presenter = MovieDetailsPresenter()
        let interactor = MovieDetailsInteractor(movie: movie)

        presenter.wireframe = self
        presenter.view = view
        presenter.interactor = interactor

        view.presenter = presenter
        interactor.output = presenter

        self.view = view
        return view
    }
}

// MARK: - MovieDetailsWireframeProtocol

extension MovieDetailsWireframe: MovieDetailsWireframeProtocol {

    // MARK: - Internal Methods

    func instantiateView(with movie: MovieEntity) -> MovieDetailsView {
        let view = self.setupView(with: movie)
        return view
    }

    func presentVideo(byKey videoKey: String) {
        // Open YouTube video in Safari view controller
        // Using mobile URL to encourage fullscreen video playback
        guard let youtubeURL = URL(string: "https://m.youtube.com/watch?v=\(videoKey)") else {
            print("❌ Invalid YouTube URL for video key: \(videoKey)")
            return
        }

        let safariViewController = SFSafariViewController(url: youtubeURL)
        safariViewController.preferredControlTintColor = UIColor.Style.blackAdaptative
        safariViewController.preferredBarTintColor = UIColor.Style.whiteAdaptative

        // Present as modal card (pageSheet) but video will play fullscreen
        safariViewController.modalPresentationStyle = .pageSheet
        safariViewController.modalTransitionStyle = .coverVertical

        // Configure modal presentation
        if #available(iOS 15.0, *) {
            if let sheet = safariViewController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 20
            }
        }

        self.view.present(safariViewController, animated: true)
    }

    func presentDetails(from recommendation: MovieEntity) {
        guard let navigationView = self.view.navigationController else { return }
        let movieDetails = MovieDetailsWireframe().instantiateView(with: recommendation)
        navigationView.pushViewController(movieDetails, animated: true)
    }

    func closeView() {
        self.view.navigationController?.popViewController(animated: true)
    }
}
