class InlineVideo {
  static create (source, videoSettings) {
    let video = document.createElement('video');
    video.setAttribute('loop', videoSettings.loop);
    video.setAttribute('autoplay', videoSettings.autoplay);
    video.setAttribute('muted', videoSettings.mute);

    video.addEventListener('click', InlineVideo.videoPauseToggleClicked, false);

    let videoSource = document.createElement('source');
    videoSource.type = 'video/mp4';
    videoSource.src = source;
    video.appendChild(videoSource);

    return video;
  }

  static videoPauseToggleClicked () {
    if (this.paused) {
      this.play();
    } else {
      this.pause();
    }
  }
}

export default InlineVideo;
