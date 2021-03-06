// ==UserScript==
// @name        Twitter Image Redirector
// @namespace   twimg
// @description Redirects tweets to direct images
// @include     https://twitter.com/*
// @version     1.4.0
// @updateURL   https://raw.githubusercontent.com/protospork/scripts/master/misc/redirector.user.js
// @grant       none
// ==/UserScript==
 
// ADDS A NEW ICON TO THE END OF THE (reply, retweet, etc) TOOLBAR
// CLICK THE ICON TO GO DIRECTLY TO THE PICTURES IN THE TWEET

var urls = [];
multiPics();

function multiPics (){
  var hashes = document.getElementsByClassName('js-adaptive-photo');
  for (var i = 0; i < hashes.length; i++){
    urls.push(hashes[i].getAttribute("data-image-url").match("(http.+/media/.+?(jpg|png))(:large)?")[1]+':orig');
    console.log('found '+urls[urls.length -1]);
  }
  console.log(hashes.length + ' images total');
  makeButton();
}
function newPage(){
  var newBody = document.createElement('body');
  newBody.setAttribute('style', 'background-color: #141414;');
  newBody.innerHTML = '<style>img { max-width: 100% }</style><a href="'+document.location+'"><img src='+urls.join('><img src=')+'></a>';
  
  document.body = newBody;
  document.title = "Click a picture to go back";
}
function makeButton(){
  var button = document.createElement('div');
  button.setAttribute('id', 'ostriches');
  button.setAttribute('class', "ProfileTweet-actionButton u-textUserColorHover");
  button.innerHTML = 
      '<button class="ProfileTweet-actionButton u-textUserColorHover js-actionButton" type="button" '+
      'data-nav="see_tweet_media"><div class="IconContainer js-tooltip" data-original-title="View Media">'+
      '<a style="color: #657786" onclick="newPage()" href="#"><span class="Icon Icon--medium Icon--camera"></span>'+
      '<span class="u-hiddenVisually">View Media</span></a></div></button>';

  var toolbar = document.getElementsByClassName('permalink-tweet-container')[0];
  toolbar = toolbar.getElementsByClassName('ProfileTweet-actionList')[0];
  toolbar.insertBefore(button, toolbar.lastChild);
  
  document.getElementById('ostriches').addEventListener('click', newPage, false);
}
