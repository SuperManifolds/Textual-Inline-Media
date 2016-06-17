import Media from '../Media.js';

class xkcd {
  static insert (line, url, title, image, description) {
    let xkcdContainer = document.createElement('div');
    xkcdContainer.className = 'inline_media_xkcd';

    let xkcdHeader = document.createElement('h2');
    xkcdHeader.className = 'inline_media_xkcd_title';
    xkcdHeader.textContent = title;
    xkcdContainer.appendChild(xkcdHeader);

    let xkcdImage = new Image();
    xkcdImage.className = 'inline_media_xkcd_image';
    xkcdImage.src = `https://${image}`;
    xkcdImage.title = description;
    xkcdContainer.appendChild(xkcdImage);

    Media.insert(line, xkcdContainer, url);
  }
}

export default xkcd;
