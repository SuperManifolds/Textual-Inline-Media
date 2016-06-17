/* The Inline Media handlers are only ever called from Textual's webkit bridge therefor we will have to disable
the eslint 'variable never used' warning for these imports */

import 'babel-polyfill';

/* eslint-disable no-unused-vars */
import bash from './Inline Media Handlers/bash.js';
import gfycat from './Inline Media Handlers/gfycat.js';
import imdb from './Inline Media Handlers/imdb.js';
import imgur from './Inline Media Handlers/imgur.js';
import Streamable from './Inline Media Handlers/Streamable.js';
import Twitter from './Inline Media Handlers/Twitter.js';
import Vimeo from './Inline Media Handlers/Vimeo.js';
import Webpage from './Inline Media Handlers/Webpage.js';
import xkcd from './Inline Media Handlers/xkcd.js';
import YouTube from './Inline Media Handlers/YouTube.js';
/* eslint-enable no-unused-vars */

class InlineMedia {

}

InlineMedia.bash = bash;
InlineMedia.gfycat = gfycat;
InlineMedia.imdb = imdb;
InlineMedia.imgur = imgur;
InlineMedia.Streamable = Streamable;
InlineMedia.Twitter = Twitter;
InlineMedia.Vimeo = Vimeo;
InlineMedia.Webpage = Webpage;
InlineMedia.xkcd = xkcd;
InlineMedia.YouTube = YouTube;

/* In order to prevent Textual from displaying default media for types we are overriding, we will need to proxy the
implementation of the toggleInlineImageReally function.  */
/* new Proxy(Textual.toggleInlineImageReally, {
  apply: function (target, thisArg, argumentsList) {
    let imageId = argumentsList[0];

    if (imageId.startsWith('inlineImage-') === false) {
      imageId = `"inlineImage-${imageId}`;
    }

    let imageNode = document.getElementById();
    let imageUrl = imageNode.querySelector('a').href;

    if (imageUrl.includes('.gif')) {
      return;
    }

    Reflect.apply(target, thisArg, argumentsList);
  }
});*/


export default InlineMedia;
