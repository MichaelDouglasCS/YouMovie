//
//  MovieEntity.swift
//  YouMovie
//
//  Created by Michael Douglas on 26/11/19.
//  Copyright © 2019 Michael Douglas. All rights reserved.
//

import Foundation
import ObjectMapper

class MovieEntity: BaseEntity {

    // MARK: - Internal Properties

    var id: Int?
    var title: String?
    var releaseDate: Date?
    var voteAverage: Double?
    var videos: [MovieVideoEntity]?
    var overview: String?
    var posterPathURL: String?
    var backdropPathURL: String?
    var runtime: Int?
    var budget: Double?
    var revenue: Double?
    var genres: [String]?
    var cast: [MovieCastEntity]?
    var crew: [MovieCrewEntity]?
    var recommendations: [MovieEntity]?
    var isNew: Bool = true

    // MARK: - Internal Methods

    override func mapping(map: Map) {

        self.id <- map["id"]
        self.title <- map["title"]

        if let releaseDates = map.JSON["release_dates"] as? JSON,
           let results = releaseDates["results"] as? [JSON],
           let releaseDate = results.first(where: { $0.contains(where: { $0.key == "iso_3166_1" && $0.value as! String == "BR" }) }),
           let rawReleaseDate = releaseDate["release_dates"] as? [JSON],
           let releaseDateString = rawReleaseDate.first?["release_date"] as? String,
           let formattedReleaseDateString = releaseDateString.split(separator: "T").first {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = .init(identifier: "pt_BR")
            self.releaseDate = formatter.date(from: String(formattedReleaseDateString))
        } else if let releaseDateString = map.JSON["release_date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = .init(identifier: "pt_BR")
            self.releaseDate = formatter.date(from: releaseDateString)
        }

        self.voteAverage <- map["vote_average"]
        self.videos <- map["videos.results"]
        self.overview <- map["overview"]
        self.posterPathURL <- map["poster_path"]
        self.backdropPathURL <- map["backdrop_path"]
        self.runtime <- map["runtime"]
        self.budget <- map["budget"]
        self.revenue <- map["revenue"]

        if let genresJSON = map.JSON["genres"] as? [JSON] {
            self.genres = genresJSON.compactMap({ $0["name"] as? String })
        }

        self.cast <- map["credits.cast"]
        self.crew <- map["credits.crew"]
        self.recommendations <- map["recommendations.results"]
    }
}
