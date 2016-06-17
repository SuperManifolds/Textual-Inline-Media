import Media from '../Media.js';


const youtubeVideoWidth = 560;
const youtubeVideoHeight = 315;

class YouTube {
  static insert (line, url, videoInfo) {
    let youtubeContainer = document.createElement('a');
    youtubeContainer.href = url;
    youtubeContainer.className = 'inline_media_youtube';

    let thumbnailContainer = document.createElement('div');
    thumbnailContainer.className = 'inline_media_youtube_thumbnail';
    youtubeContainer.appendChild(thumbnailContainer);

    let thumbnail = new Image();
    thumbnail.src = videoInfo.thumbnailUrl;
    thumbnailContainer.appendChild(thumbnail);

    let videoLength = document.createElement('span');
    videoLength.textContent = videoInfo.duration;
    thumbnailContainer.appendChild(videoLength);

    let infoContainer = document.createElement('div');
    infoContainer.className = 'inline_media_youtube_info';
    youtubeContainer.appendChild(infoContainer);

    let videoTitle = document.createElement('p');
    videoTitle.className = 'inline_media_youtube_title';
    videoTitle.textContent = videoInfo.title;
    infoContainer.appendChild(videoTitle);

    let videoAuthor = document.createElement('p');
    videoAuthor.className = 'inline_media_youtube_author';
    videoAuthor.textContent = `by ${videoInfo.author}`;
    infoContainer.appendChild(videoAuthor);

    let videoViews = document.createElement('p');
    videoViews.className = 'inline_media_youtube_views';
    videoViews.textContent = `${videoInfo.views} views`;
    infoContainer.appendChild(videoViews);

    Media.insert(line, youtubeContainer, url);
  }

  static insertPlayer (line, url, videoID, autoplay) {
    let youtubeVideo = document.createElement('iframe');
    youtubeVideo.className = 'inline_media_youtube_video';
    youtubeVideo.width = youtubeVideoWidth;
    youtubeVideo.height = youtubeVideoHeight;
    youtubeVideo.setAttribute('frameborder', '0');
    youtubeVideo.setAttribute('allowfullscreen', '0');
    youtubeVideo.setAttribute('enablejsapi', '1');
    youtubeVideo.src = `https://www.youtube.com/embed/${videoID}`;
    if (autoplay === true) {
      youtubeVideo.setAttribute('autoplay', '1');
    }

    Media.insert(line, youtubeVideo, url);
  }
}

export default YouTube;
