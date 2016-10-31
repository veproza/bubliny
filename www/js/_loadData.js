// based on http://stackoverflow.com/questions/2879509/dynamically-loading-javascript-synchronously
// get some kind of XMLHttpRequest
var xhrObj = (new XMLHttpRequest() || new ActiveXObject("Microsoft.XMLHttp"))
// open and send a synchronous request
xhrObj.open('GET', "./data.js", false);
xhrObj.send('');
// add the returned content to a newly created script tag
var se = document.createElement('script');
se.type = "text/javascript";
se.text = xhrObj.responseText;
document.getElementsByTagName('head')[0].appendChild(se);
