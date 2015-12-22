// ==UserScript==
// @name        Twitter Image Redirector
// @namespace   twimg
// @description Redirects tweets to direct images
// @include     https://twitter.com/*
// @version     1.2.7
// @updateURL   https://raw.githubusercontent.com/protospork/scripts/master/misc/redirector.user.js
// @grant       none
// ==/UserScript==
 
// ADDS A NEW ICON TO THE END OF THE (reply, retweet, etc) TOOLBAR
// CLICK THE ICON TO GO DIRECTLY TO THE PICTURES IN THE TWEET

var urls = [];
var icon = 
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAzUlEQVQ4jWNgGHCgmDZjsWLazP/oWCl15hki"+
    "DcDUTJIhGJqIwIppMxbDDVDC4wJ8mGgDlNJm/vead+d/yJq3GDh49ZvFDISc6z7rBlbNMAw3QL9yI16F6Dh0zbv/IWve3WVQSpv5XzV7Pk"+
    "5n4jMgdM3brQxKaTP/axevIEkzwoB3kxmU0mb+N2nYSZYBwSvfBDBoF68g2fkha97+D1n97mLgipf6DJDAIFHzmrf/Q9e8XRO66rkoQ+iq"+
    "d2lQ/xCPV787E7TijSnpOQ8LAADZSeD4vPdeegAAAABJRU5ErkJggg==";
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
  newBody.setAttribute('style', 'background-color: #141414');
  newBody.innerHTML = '<a href="'+document.location+'"><img src='+urls.join('><img src=')+'></a>';
  document.body = newBody;
  document.title = "Click a picture to go back";
}
function makeButton(){
  var button = document.createElement('div');
  button.setAttribute('id', 'ostriches');
  button.setAttribute('class', "ProfileTweet-action u-textUserColorHover");
  button.innerHTML = '<a onclick="newPage()" href="#"><img src="'+icon+'" title="&#x1F4C2;" alt="&#x1F4C2;" /></a>';

  var toolbar = document.getElementsByClassName('permalink-tweet-container')[0];
  toolbar = toolbar.getElementsByClassName('ProfileTweet-actionList')[0];
  toolbar.insertBefore(button, toolbar.lastChild);
  
  document.getElementById('ostriches').addEventListener('click', newPage, false);
}
