//
//  imdb.swift
//  Textual Inline Media
//
//  Created by Alex S. Glomsaas on 2015-10-10.
//  Copyright © 2015 Alex S. Glomsaas. All rights reserved.
//

import Foundation

class imdb: NSObject, InlineMediaHandler {
    static func name() -> String {
        return "IMDB"
    }
    
    required convenience init(url: NSURL, controller: TVCLogController, line: String) {
        self.init()
        let requestString = url.pathComponents![2]
        let requestUrl = NSURL(string: "http://www.omdbapi.com/?i=\(requestString)&plot=short&r=json")
        guard requestUrl != nil else {
            return
        }
        
        let session = NSURLSession.sharedSession()
        session.dataTaskWithURL(requestUrl!, completionHandler: {(data : NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard data != nil else {
                return
            }
            
            do {
                /* Attempt to serialise the JSON results into a dictionary. */
                let root = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
                let title       = root["Title"]      as! String
                let pgRating    = root["Rated"]      as! String
                let year        = root["Year"]       as! String
                let releaseDate = root["Released"]   as! String
                let runtime     = root["Runtime"]    as! String
                let genres      = root["Genre"]      as! String
                let director    = root["Director"]   as! String
                let writers     = root["Writer"]     as! String
                let stars       = root["Actors"]     as! String
                let description = root["Plot"]       as! String
                let country     = root["Country"]    as! String
                let metascore   = root["Metascore"]  as! String
                let rating      = root["imdbRating"] as! String
                let thumbnail   = root["Poster"]     as! String
                
                self.performBlockOnMainThread({
                    let document = controller.webView.mainFrameDocument
                    
                    /* Create the container for the entire imdb card.  */
                    let imdbContainer = document.createElement("div")
                    imdbContainer.className = "inline_media_imdb"
                    
                    /* Create the element for the movie/series cover thumbnail */
                    let imdbThumbnail = document.createElement("img")
                    imdbThumbnail.className = "inline_media_imdb_thumbnail"
                    imdbThumbnail.setAttribute("src", value: thumbnail)
                    imdbContainer.appendChild(imdbThumbnail)
                    
                    
                    /* Create the container holding all the information on the right side of the thumbnail */
                    let infoContainer = document.createElement("div")
                    infoContainer.className = "inline_media_imdb_info"
                    imdbContainer.appendChild(infoContainer)
                    
                    /* Create the container holding the title and the release year */
                    let imdbHeader = document.createElement("div")
                    imdbHeader.className = "inline_media_imdb_header"
                    infoContainer.appendChild(imdbHeader)
                    
                    /* Create the title of the movie/series */
                    let imdbTitle = document.createElement("h3")
                    imdbTitle.className = "inline_media_imdb_title"
                    imdbTitle.textContent = title
                    imdbHeader.appendChild(imdbTitle)
                    
                    /* Set the relase year of this title */
                    let imdbYear = document.createElement("span")
                    imdbYear.className = "inline_media_imdb_year"
                    imdbYear.appendChild(document.createTextNode("("))
                    imdbHeader.appendChild(imdbYear)
                    
                    let imdbYearLink = document.createElement("a")
                    imdbYearLink.setAttribute("href", value: "http://www.imdb.com/year/\(year)")
                    imdbYearLink.textContent = year
                    imdbYear.appendChild(imdbYearLink)
                    
                    imdbYear.appendChild(document.createTextNode(")"))
                    
                    
                    
                    /* Create the container for the 'bar' holding the pg rating, duration, genre, and release info */
                    let imdbInfobar = document.createElement("div")
                    imdbInfobar.className = "inline_media_imdb_infobar"
                    infoContainer.appendChild(imdbInfobar)
                    
                    /* Create the PG-reating for this title */
                    let imdbPgRating = document.createElement("span")
                    imdbPgRating.className = "inline_media_imdb_pgRating"
                    imdbPgRating.textContent = pgRating
                    imdbInfobar.appendChild(imdbPgRating)
                    
                    /* Create the duration/runtime for this title */
                    let imdbDuration = document.createElement("span")
                    imdbDuration.className = "inline_media_imdb_duration"
                    imdbDuration.textContent = runtime
                    imdbInfobar.appendChild(imdbDuration)
                    
                    /* Create the list of genres for this title */
                    let imdbGenre = document.createElement("span")
                    imdbGenre.className = "inline_media_imdb_genre"
                    let seperatedGenres = genres.componentsSeparatedByString(",")
                    
                    /* The API gives us the genres in a comma seperated plain text list.
                    We will seperate them into an array, trim the whitespace, and turn it into a list of links.*/
                    for genre in seperatedGenres {
                        let trimmedGenre = genre.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        let genreLink = document.createElement("a")
                        genreLink.setAttribute("href", value: "http://www.imdb.com/genre/\(trimmedGenre)")
                        genreLink.textContent = trimmedGenre
                        imdbGenre.appendChild(genreLink)
                        
                        /* Seperate the items in the list with commas, making sure not to append a comma to the last item. */
                        if genre != seperatedGenres.last {
                            imdbGenre.appendChild(document.createTextNode(", "))
                        }
                    }
                    imdbInfobar.appendChild(imdbGenre)
                    
                    /* Create the release information link for this title */
                    let imdbReleaseInfo = document.createElement("a")
                    imdbReleaseInfo.className = "inline_media_imdb_releaseinfo"
                    imdbReleaseInfo.setAttribute("href", value: "http://www.imdb.com/title/\(requestString)/releaseinfo")
                    imdbReleaseInfo.textContent = "\(releaseDate) (\(country))"
                    imdbInfobar.appendChild(imdbReleaseInfo)
                    
                    
                    /* Create the container holding all the rating information */
                    let starbox = document.createElement("div")
                    starbox.className = "inline_media_imdb_starbox"
                    infoContainer.appendChild(starbox)
                    
                    /* Create the large star with the main IMDB rating */
                    let imdbRating = document.createElement("div")
                    imdbRating.className = "inline_media_imdb_rating"
                    imdbRating.textContent = rating
                    starbox.appendChild(imdbRating)
                    
                    /* Create the container holding the imdb and metacritic ratings */
                    let ratingDetails = document.createElement("span")
                    ratingDetails.className = "inline_media_imdb_rating_details"
                    ratingDetails.appendChild(document.createTextNode("Ratings: "))
                    
                    /* Insert the IMDB rating */
                    let ratingText = document.createElement("strong")
                    ratingText.textContent = rating
                    ratingDetails.appendChild(ratingText)
                    ratingDetails.appendChild(document.createTextNode("/10"))
                    ratingDetails.appendChild(document.createElement("br"))
                    
                    /* Insert the metacritic rating */
                    ratingDetails.appendChild(document.createTextNode("Metascore: "))
                    if metascore != "N/A" {
                        let metascoreLink = document.createElement("a")
                        metascoreLink.setAttribute("href", value: "http://www.imdb.com/title/\(requestString)/criticreviews")
                        metascoreLink.textContent = "\(metascore)/100"
                        ratingDetails.appendChild(metascoreLink)
                    } else {
                        ratingDetails.appendChild(document.createTextNode("N/A"))
                    }
                    starbox.appendChild(ratingDetails)
                    
                    
                    /* Insert the description of this title */
                    let imdbDescription = document.createElement("div")
                    imdbDescription.className = "inline_media_imdb_description"
                    imdbDescription.textContent = description
                    infoContainer.appendChild(imdbDescription)
                    
                    
                    /* Create the container holding the credit for the director, writers, and stars */
                    let creditContainer = document.createElement("div")
                    creditContainer.className = "inline_media_imdb_credit"
                    infoContainer.appendChild(creditContainer)
                    
                    /* Insert the director info */
                    let imdbDirectorTitle = document.createElement("strong")
                    imdbDirectorTitle.textContent = "Director: "
                    creditContainer.appendChild(imdbDirectorTitle)
                    
                    let imdbDirector = document.createElement("span")
                    imdbDirector.className = "inline_media_imdb_director"
                    imdbDirector.textContent = director
                    creditContainer.appendChild(imdbDirector)
                    
                    /* Insert the writers info  */
                    let imdbWritersTitle = document.createElement("strong")
                    imdbWritersTitle.textContent = "Writers: "
                    creditContainer.appendChild(imdbWritersTitle)
                    
                    let imdbWriters = document.createElement("span")
                    imdbWriters.className = "inline_media_imdb_writers"
                    imdbWriters.textContent = writers
                    creditContainer.appendChild(imdbWriters)
                    
                    /* Insert the stars info */
                    let imdbStarsTitle = document.createElement("strong")
                    imdbStarsTitle.textContent = "Stars: "
                    creditContainer.appendChild(imdbStarsTitle)
                    
                    let imdbStars = document.createElement("span")
                    imdbStars.className = "inline_media_imdb_strs"
                    imdbStars.textContent = stars
                    creditContainer.appendChild(imdbStars)
                    
                    /* Insert the IMDB card into the chat  */
                    InlineMedia.insert(controller, line: line, node: imdbContainer, url: url.absoluteString)
                })

            } catch {
                return
            }
        }).resume()
    }
    
    static func matchesServiceSchema(url: NSURL, hasImageExtension: Bool) -> Bool {
        return url.host?.hasSuffix("imdb.com") == true && url.path?.hasPrefix("/title/") == true
    }
}