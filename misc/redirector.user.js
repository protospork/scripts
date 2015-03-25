// ==UserScript==
// @name        Twitter Image Redirector
// @namespace   twimg
// @description Redirects tweets to direct images
// @include     https://twitter.com/*
// @version     1.1
// @updateURL   https://raw.githubusercontent.com/protospork/scripts/master/misc/redirector.user.js
// @grant       none
// ==/UserScript==
 
 
// ADDS A NEW ICON TO THE END OF THE (reply, retweet, etc) TOOLBAR
// CLICK THE ICON TO GO DIRECTLY TO THE PICTURES IN THE TWEET
 
var urls = [];
multiPics();
if (urls.length == 0){
  getPhoto();
}
makeButton();

function multiPics (){
  var box = document.getElementsByClassName('multi-photos');
  if (box.length == 0){ return 0; }
  var hashes = box[0].getElementsByClassName('media-thumbnail');
  for (var i = 0; i < hashes.length; i++){
    urls.push(hashes[i].getAttribute("data-url").match("(http.+/media/.+?(jpg|png))(:large)?")[1]+':orig');
  }
  return urls.length;
}
function getPhoto (){
  var pic = document.getElementsByClassName('media-thumbnail');
  var hash = pic[0].getAttribute("data-url").match("(http.+/media/.+?(jpg|png))(:large)?")[1]+':orig';
  urls.push(hash);
  return urls.length;
}
function newPage(){
  var newbody = document.createElement('body');
  newbody.setAttribute('style', 'background-color: #141414');
  newbody.innerHTML = '<img src='+urls.join('><img src=')+'>';
  document.body = newbody;
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
