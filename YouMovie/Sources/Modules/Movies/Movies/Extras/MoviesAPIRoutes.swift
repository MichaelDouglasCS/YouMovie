//
//  MoviesAPIRoutes.swift
//  YouMovie
//
//  Created by Michael Douglas on 26/11/19.
//  Copyright © 2019 Michael Douglas. All rights reserved.
//

import Foundation

extension APIRoutes {

    struct Movies {

        static func fetchMovies(from section: MoviesSectionType, atPage page: Int) -> String {

            let baseURL: String = APIRoutes.apiBaseURL
            let apiKey: String = APIRoutes.apiKey
            let language: String = "&language=pt-BR"

            switch section {
            case .trending:
                return "\(baseURL)/trending/movie/day?api_key=\(apiKey)\(language)&page=\(page)"
            case .popular:
                return "\(baseURL)/movie/popular?api_key=\(apiKey)\(language)&page=\(page)"
            case .topRated:
                return "\(baseURL)/movie/top_rated?api_key=\(apiKey)\(language)&page=\(page)"
            case .upcoming:
                return "\(baseURL)/movie/upcoming?api_key=\(apiKey)\(language)&page=\(page)"
            }
        }

        static func fetchImage(fromPath path: String, size: ImageSize) -> String {
            return "https://image.tmdb.org/t/p/\(size.rawValue)/\(path)"
        }
    }
}
