import Media from '../Media.js';

class Webpage {
  static insert (line, url, title, description = null, imageUrl = null) {
    /* Create the container for the entire inline media element. */
    let websiteContainer = document.createElement('a');
    websiteContainer.href = url;
    websiteContainer.className = 'inline_media_website';

    /* If we found a preview image element, we will add it. */
    if (imageUrl) {
      let previewImage = new Image();
      previewImage.src = imageUrl;
      previewImage.className = 'inline_media_website_thumbnail';
      websiteContainer.appendChild(previewImage);
    }

    /* Create the container that holds the title and description. */
    let infoContainer = document.createElement('div');
    infoContainer.className = 'inline_media_website_info';
    websiteContainer.appendChild(infoContainer);

    /* Create the title element */
    let titleElement = document.createElement('div');
    titleElement.className = 'inline_media_website_title';
    titleElement.textContent = title;
    infoContainer.appendChild(titleElement);

    /* If we found a description, create the description element. */
    if (description) {
      let descriptionElement = document.createElement('div');
      descriptionElement.className = 'inline_media_website_desc';
      descriptionElement.textContent = description;
      infoContainer.appendChild(descriptionElement);
    }

    console.log(websiteContainer);
    Media.insert(line, websiteContainer, url);
  }
}

export default Webpage;
