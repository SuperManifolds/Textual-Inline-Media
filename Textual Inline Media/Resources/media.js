window.twttr = (function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0],
    t = window.twttr || {};
  if (d.getElementById(id)) return t;
  js = d.createElement(s);
  js.id = id;
  js.src = "https://platform.twitter.com/widgets.js";
  fjs.parentNode.insertBefore(js, fjs);
 
  t._e = [];
  t.ready = function(f) {
    t._e.push(f);
  };
 
  return t;
}(document, "script", "twitter-wjs"));

twttr.ready(
  function (twttr) {
      twttr.events.bind('rendered', function (event) {
          var style = document.createElement("style");
          style.textContent = ".embeddedtweet,.embeddedtweet-mediaforward,.EmbeddedTweet-tweet {background-color: transparent; border: 0; border-color: transparent; border-radius: 0; border-bottom-right-radius: 0 !important; border-bottom-left-radius: 0 !important; border-top-color: transparent !important; border-right-color: transparent !important; border-bottom-color: transparent !important; border-left-color: transparent !important; }";
          event.target.contentDocument.getElementsByTagName("head")[0].appendChild(style);
     });
  }
);