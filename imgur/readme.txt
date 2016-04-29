takes an imgur link and embeds the actual image.  

imgur redirects mobile users to a landing page featuring ads and shit. this tool grabs the image's hash and
dumps it in a plain black html page, which is the closest I could get to a direct link.

this is most useful if you're using phones or tablets on your home wifi and you have a pc you can
install [privoxy](http://www.privoxy.org/) on.

protip: open user.action and add these lines:
```
{ +redirect{s@^@https://muy.moe/i.html?url=@} }
.imgur.com
```

or you could just use it manually or with some other sort of url filtering/transform solution

KNOWN ISSUE: this thing turns gifv/webm links into plain gifs

live at https://muy.moe/i.html
use: /i.html?url=[imgur url]
