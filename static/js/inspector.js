// extend version of $X
// $X(exp);
// $X(exp, context);
// $X(exp, type);
// $X(exp, context, type);
function $X (exp, context, type /* want type */) {
	if (typeof context == "function") {
		type    = context;
		context = null;
	}
	if (!context) context = document;
	exp = (context.ownerDocument || context).createExpression(exp, function (prefix) {
		var o = document.createNSResolver(context)(prefix);
		if (o) return o;
		return (document.contentType == "application/xhtml+xml") ? "http://www.w3.org/1999/xhtml" : "";
	});

	switch (type) {
		case String:  return exp.evaluate(context, XPathResult.STRING_TYPE, null).stringValue;
		case Number:  return exp.evaluate(context, XPathResult.NUMBER_TYPE, null).numberValue;
		case Boolean: return exp.evaluate(context, XPathResult.BOOLEAN_TYPE, null).booleanValue;
		case Array:
			var result = exp.evaluate(context, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
			for (var ret = [], i = 0, len = result.snapshotLength; i < len; i++) {
				ret.push(result.snapshotItem(i));
			}
			return ret;
		case undefined:
			var result = exp.evaluate(context, XPathResult.ANY_TYPE, null);
			switch (result.resultType) {
				case XPathResult.STRING_TYPE : return result.stringValue;
				case XPathResult.NUMBER_TYPE : return result.numberValue;
				case XPathResult.BOOLEAN_TYPE: return result.booleanValue;
				case XPathResult.UNORDERED_NODE_ITERATOR_TYPE:
					// not ensure the order.
					var ret = [], i = null;
					while ((i = result.iterateNext())) ret.push(i);
					return ret;
			}
			return null;
		default: throw(TypeError("$X: specified type is not valid type."));
	}
}
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

			XPathGenerator._inspect.addEventListener("click", function () {
				document.body.addEventListener("mouseover", XPathGenerator.mouseover, true);
				document.body.addEventListener("mousedown", XPathGenerator.mousedown, true);
				document.body.addEventListener("mouseout",  XPathGenerator.mouseout,  true);
			}, false);
			document.body.addEventListener("mouseover", XPathGenerator.mouseover, true);
			document.body.addEventListener("mousedown", XPathGenerator.mousedown, true);
			document.body.addEventListener("mouseout",  XPathGenerator.mouseout,  true);
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
})();
