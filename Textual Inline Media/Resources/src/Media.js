

class Media {
  static insert (lineId, node, url) {
    let line = document.getElementById(`line-${lineId}`);
    if (line) {
      let message = line.querySelector('.innerMessage');

      let mediaContainer = document.createElement('span');
      mediaContainer.className = 'InlineMediaCell';
      mediaContainer.setAttribute('href', url);
      mediaContainer.addEventListener('click', Media.hideInlineMediaClicked, false);

      let messageLinks = message.querySelectorAll('a');
      for (let link of messageLinks) {
        if (link.href === url) {
          link.removeAttribute('onclick');
          link.addEventListener('click', Media.toggleHideInlineMediaClicked, false);
        }
      }

      mediaContainer.appendChild(node);
      message.appendChild(mediaContainer);
    }
  }

  static hideInlineMediaClicked (event) {
    if (event.shiftKey === true) {
      this.classList.add('hidden');
      event.preventDefault();
    }
  }

  static toggleHideInlineMediaClicked (event) {
    if (event.shiftKey === true) {
      let url = this.href;

      let mediaElement = this.parentElement.querySelector(`.inlineMediaCell[href='${url}']`);
      if (mediaElement) {
        if (mediaElement.classList.contains('hidden')) {
          mediaElement.classList.remove('hidden');
        } else {
          mediaElement.classList.add('hidden');
        }
      }
    }
  }
}

export default Media;
