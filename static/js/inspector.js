alert(1);
(function(scripts, callback, errorback) {
    if (typeof errorback != 'function')
        errorback = function(url) { alert('jsloader load error: ' + url) };

    var cssRegexp = /.css$/;
    var load = function(url) {
        if (cssRegexp.test(url)) {
            var link = document.createElement('link');
            link.href = url;
            link.type = 'text/css';
            link.rel = 'stylesheet';
            (document.getElementsByTagName('head')[0] || document.body).appendChild(link);
            if (scripts.length) {
                load(scripts.shift());
            } else {
                callback();
            }
        } else {
            var script = document.createElement('script');
            script.type = 'text/javascript';
            script.charset = 'utf-8';
            var current_callback;
            if (scripts.length) {
                var u = scripts.shift();
                current_callback = function() { load(u) }
            } else {
                current_callback = callback;
            }
            if (window.ActiveXObject) { // IE
                script.onreadystatechange = function() {
                    if (script.readyState == 'complete' || script.readyState == 'loaded') {
                        current_callback();
                    }
                }
            } else {
                script.onload = current_callback;
                script.onerror = function() { errorback(url) };
            }
            script.src = url;
            document.body.appendChild(script);
        }
    }

    load(scripts.shift());
})(["http://gist.github.com/raw/3238/dollarX.js"], function() {
/*
 * cho45のjAutoPagerizeに付属しているXPathジェネレータをコピペ改変
 * @license CCPL ( http://creativecommons.org/licenses/by/3.0/ )
 * @require http://gist.github.com/raw/3238/dollarX.js
 *
 */
(function() {
	var h = function(s) {
		var d = document.createElement("div");
		d.innerHTML = s;
		return d;
	}

	var XPathGenerator = {
		open : function () {
			XPathGenerator._prev = [];
			XPathGenerator._container = h("<textarea cols='40' rows='5'></textarea><br/>");
			XPathGenerator._inspect   = h("<button>Inspect</button>").firstChild;
			XPathGenerator._timer = setInterval(XPathGenerator.change, 1000);
			XPathGenerator._container.appendChild(XPathGenerator._inspect);
			with (XPathGenerator._container.style) {
				position = "fixed";
				right    = "0";
				top      = "2em";
				opacity  = "0.9";
				zIndex   = "10000";
			}
			document.body.appendChild(XPathGenerator._container);

			var elements = document.getElementsByTagName('a');
			for (var i = 0; i < elements.length; i++) { 
				elements[i].addEventListener("click", function(e){ e.preventDefault() }, true);
			}

			//XPathGenerator._inspect.addEventListener("click", function () {
				document.body.addEventListener("mouseover", XPathGenerator.mouseover, true);
				document.body.addEventListener("mousedown", XPathGenerator.mousedown, true);
				document.body.addEventListener("mouseout",  XPathGenerator.mouseout,  true);
			//}, false);
		},

		close : function () {
			XPathGenerator._container.parentNode.removeChild(XPathGenerator._container);
			clearInterval(XPathGenerator._timer);
		},

		mouseover : function (e) {
			e.target.style.outline = "2px solid red";
			XPathGenerator._container.firstChild.value = XPathGenerator.getXPathByElement(e.target);
		},

		mousedown : function (e) {
			e.target.style.outline = "";
			document.body.removeEventListener("mouseover", XPathGenerator.mouseover, true);
			document.body.removeEventListener("mousedown", XPathGenerator.mousedown, true);
			document.body.removeEventListener("mouseout",  XPathGenerator.mouseout,  true);
		},

		mouseout : function (e) {
			e.target.style.outline = "";
		},

		change : function (e) {
			var path = XPathGenerator._container.firstChild.value;
			if (XPathGenerator._prev.value != path) {
				while (XPathGenerator._prev[0]) XPathGenerator._prev.pop().style.outline = "";
				try {
					XPathGenerator._prev = $X(path).map(function (i) {
						i.style.outline = "2px solid red";
						return i;
					});
				} catch (e) {}
				XPathGenerator._prev.value = path;
			}
		},

		toggle : function () {
			if (XPathGenerator._opened) {
				this.close();
				XPathGenerator._opened = false;
			} else {
				XPathGenerator._opened = true;
				this.open();
			}
		},

		getXPathByElement : function (target) {
			function indexOf (node) {
				for (var i = 0, r = 1, c = node.parentNode.childNodes, len = c.length; i < len; i++) {
					if (c[i].nodeName == node.nodeName &&
						c[i].nodeType == node.nodeType) {
						if (c[i] == node) return r;
						r++;
					}
				}
				return -1;
			}

			var pathElement = "";
			var node = target;
			if (node.nodeType == 9 /*DOCUMENT_NODE=9*/) {
				return ""
			} else {
				var tagName = node.tagName.toLowerCase();
				if (node.hasAttribute("id")) {
					// pathElement = tagName + '[@id="'+node.getAttribute("id")+'"]';
					pathElement = 'id("'+node.getAttribute("id")+'")';
				} else {
					pathElement = arguments.callee(node.parentNode) + '/' + tagName;
					if (node.hasAttribute("class")) {
						pathElement += '[@class="'+node.getAttribute("class")+'"]';
					} else {
						pathElement += '['+indexOf(node)+']';
					}
				}
			}
			return pathElement;
		}
	};
	XPathGenerator.toggle();
})()
});
