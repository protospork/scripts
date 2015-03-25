// ==UserScript==
// @name        Twitter Image Redirector
// @namespace   twimg
// @description Redirects tweets to direct images
// @include     https://twitter.com/*
// @version     1.2.2
// @updateURL   https://raw.githubusercontent.com/protospork/scripts/master/misc/redirector.user.js
// @grant       none
// ==/UserScript==
 
// ADDS A NEW ICON TO THE END OF THE (reply, retweet, etc) TOOLBAR
// CLICK THE ICON TO GO DIRECTLY TO THE PICTURES IN THE TWEET

var urls = [];
multiPics();

function multiPics (){
  var hashes = document.getElementsByClassName('media-thumbnail');
  for (var i = 0; i < hashes.length; i++){
    urls.push(hashes[i].getAttribute("data-url").match("(http.+/media/.+?(jpg|png))(:large)?")[1]+':orig');
  }
  makeButton();
}
function newPage(){
  var newBody = document.createElement('body');
  newBody.setAttribute('style', 'background-color: #141414');
  newBody.innerHTML = '<a href="'+document.location+'"><img src='+urls.join('><img src=')+'></a>';
  document.body = newBody;
  document.title = "Click a picture to go back";
}
function makeButton(){
  var button = document.createElement('div');
  button.setAttribute('id', 'ostriches');
  button.setAttribute('class', "ProfileTweet-action u-textUserColorHover");
  button.innerHTML = '<a onclick="newPage()" href="#"><span class="Icon Icon--photo"></span></a>';
  
  var toolbar = document.getElementsByClassName('ProfileTweet-actionList')[0];
  toolbar.insertBefore(button, toolbar.lastChild);
  
  document.getElementById('ostriches').addEventListener('click', newPage, false);
}
