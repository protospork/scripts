// ==UserScript==
// @name         mastodon UI tweaks
// @namespace    mastui
// @version      0.1
// @description  this ui is not great
// @author       protospork
// @match        https://mastodon.cx/web/*
// @grant        none
// @run-at       document-idle
// ==/UserScript==
(function() {
    'use strict';

    // disclaimer: I barely remember how to use JS 
    var cols = document.getElementsByClassName('column')[0];
    // three columns in the default UI: 
    //0 = home, 1= notifications, 2= the third one
    cols.setAttribute("style", "flex-grow: 1");    
})();
