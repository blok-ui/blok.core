package blok.html;

import blok.signal.Signal;

#if (js && !nodejs)
typedef Event = js.html.Event;
#else
typedef Event = Dynamic;
#end
typedef EventListener = (e:Event) -> Void;

// From https://github.com/haxetink/tink_domspec/blob/master/src/tink/domspec/Events.hx
typedef HtmlEvents = {
	@:html('onwheel') final ?onWheel:ReadOnlySignal<EventListener>;
	@:html('oncopy') final ?onCopy:ReadOnlySignal<EventListener>;
	@:html('oncut') final ?onCut:ReadOnlySignal<EventListener>;
	@:html('onpaste') final ?onPaste:ReadOnlySignal<EventListener>;
	@:html('onabort') final ?onAbort:ReadOnlySignal<EventListener>;
	@:html('onblur') final ?onBlur:ReadOnlySignal<EventListener>;
	@:html('onfocus') final ?onFocus:ReadOnlySignal<EventListener>;
	@:html('oncanplay') final ?onCanPlay:ReadOnlySignal<EventListener>;
	@:html('oncanplaythrough') final ?onCanPlayThrough:ReadOnlySignal<EventListener>;
	@:html('onchange') final ?onChange:ReadOnlySignal<EventListener>;
	@:html('onclick') final ?onClick:ReadOnlySignal<EventListener>;
	@:html('oncontextmenu') final ?onContextMenu:ReadOnlySignal<EventListener>;
	@:html('ondblclick') final ?onDblClick:ReadOnlySignal<EventListener>;
	@:html('ondrag') final ?onDrag:ReadOnlySignal<EventListener>;
	@:html('ondragend') final ?onDragEnd:ReadOnlySignal<EventListener>;
	@:html('ondragenter') final ?onDragEnter:ReadOnlySignal<EventListener>;
	@:html('ondragleave') final ?onDragLeave:ReadOnlySignal<EventListener>;
	@:html('ondragover') final ?onDragOver:ReadOnlySignal<EventListener>;
	@:html('ondragstart') final ?onDragStart:ReadOnlySignal<EventListener>;
	@:html('ondrop') final ?onDrop:ReadOnlySignal<EventListener>;
	@:html('ondurationchange') final ?onDurationChange:ReadOnlySignal<EventListener>;
	@:html('onemptied') final ?onEmptied:ReadOnlySignal<EventListener>;
	@:html('onended') final ?onEnded:ReadOnlySignal<EventListener>;
	@:html('oninput') final ?onInput:ReadOnlySignal<EventListener>;
	@:html('oninvalid') final ?onInvalid:ReadOnlySignal<EventListener>;
	@:html('oncompositionstart') final ?onCompositionStart:ReadOnlySignal<EventListener>;
	@:html('oncompositionupdate') final ?onCompositionUpdate:ReadOnlySignal<EventListener>;
	@:html('oncompositionend') final ?onCompositionEnd:ReadOnlySignal<EventListener>;
	@:html('onkeydown') final ?onKeyDown:ReadOnlySignal<EventListener>;
	@:html('onkeypress') final ?onKeyPress:ReadOnlySignal<EventListener>;
	@:html('onkeyup') final ?onKeyUp:ReadOnlySignal<EventListener>;
	@:html('onload') final ?onLoad:ReadOnlySignal<EventListener>;
	@:html('onloadeddata') final ?onLoadedData:ReadOnlySignal<EventListener>;
	@:html('onloadedmetadata') final ?onLoadedMetadata:ReadOnlySignal<EventListener>;
	@:html('onloadstart') final ?onLoadStart:ReadOnlySignal<EventListener>;
	@:html('onmousedown') final ?onMouseDown:ReadOnlySignal<EventListener>;
	@:html('onmouseenter') final ?onMouseEnter:ReadOnlySignal<EventListener>;
	@:html('onmouseleave') final ?onMouseLeave:ReadOnlySignal<EventListener>;
	@:html('onmousemove') final ?onMouseMove:ReadOnlySignal<EventListener>;
	@:html('onmouseout') final ?onMouseOut:ReadOnlySignal<EventListener>;
	@:html('onmouseover') final ?onMouseover:ReadOnlySignal<EventListener>;
	@:html('onmouseup') final ?onMouseUp:ReadOnlySignal<EventListener>;
	@:html('onpause') final ?onPause:ReadOnlySignal<EventListener>;
	@:html('onplay') final ?onPlay:ReadOnlySignal<EventListener>;
	@:html('onplaying') final ?onPlaying:ReadOnlySignal<EventListener>;
	@:html('onprogress') final ?onProgress:ReadOnlySignal<EventListener>;
	@:html('onratechange') final ?onRateChange:ReadOnlySignal<EventListener>;
	@:html('onreset') final ?onReset:ReadOnlySignal<EventListener>;
	@:html('onresize') final ?onResize:ReadOnlySignal<EventListener>;
	@:html('onscroll') final ?onScroll:ReadOnlySignal<EventListener>;
	@:html('onseeked') final ?onSeeked:ReadOnlySignal<EventListener>;
	@:html('onseeking') final ?onSeeking:ReadOnlySignal<EventListener>;
	@:html('onselect') final ?onSelect:ReadOnlySignal<EventListener>;
	@:html('onshow') final ?onShow:ReadOnlySignal<EventListener>;
	@:html('onstalled') final ?onStalled:ReadOnlySignal<EventListener>;
	@:html('onsubmit') final ?onSubmit:ReadOnlySignal<EventListener>;
	@:html('onsuspend') final ?onSuspend:ReadOnlySignal<EventListener>;
	@:html('ontimeupdate') final ?onTimeEpdate:ReadOnlySignal<EventListener>;
	@:html('onvolumechange') final ?onVolumeChange:ReadOnlySignal<EventListener>;
	@:html('onwaiting') final ?onWaiting:ReadOnlySignal<EventListener>;
	@:html('onpointercancel') final ?onPointerCancel:ReadOnlySignal<EventListener>;
	@:html('onpointerdown') final ?onPointerDown:ReadOnlySignal<EventListener>;
	@:html('onpointerup') final ?onPointerUp:ReadOnlySignal<EventListener>;
	@:html('onpointermove') final ?onPointerMove:ReadOnlySignal<EventListener>;
	@:html('onpointerout') final ?onPointerOut:ReadOnlySignal<EventListener>;
	@:html('onpointerover') final ?onPointerOver:ReadOnlySignal<EventListener>;
	@:html('onpointerenter') final ?onPointerEnter:ReadOnlySignal<EventListener>;
	@:html('onpointerleave') final ?onPointerLeave:ReadOnlySignal<EventListener>;
	@:html('ongotpointercapture') final ?onGotPointerCapture:ReadOnlySignal<EventListener>;
	@:html('onlostpointercapture') final ?onLostPointerCapture:ReadOnlySignal<EventListener>;
	@:html('onfullscreenchange') final ?onFullScreenChange:ReadOnlySignal<EventListener>;
	@:html('onfullscreenerror') final ?onFullScreenError:ReadOnlySignal<EventListener>;
	@:html('onpointerlockchange') final ?onPointerLockChange:ReadOnlySignal<EventListener>;
	@:html('onpointerlockerror') final ?onPointerLockError:ReadOnlySignal<EventListener>;
	@:html('onerror') final ?onError:ReadOnlySignal<EventListener>;
	@:html('ontouchstart') final ?onTouchStart:ReadOnlySignal<EventListener>;
	@:html('ontouchend') final ?onTouchEnd:ReadOnlySignal<EventListener>;
	@:html('ontouchmove') final ?onTouchMove:ReadOnlySignal<EventListener>;
	@:html('ontouchcancel') final ?onTouchCancel:ReadOnlySignal<EventListener>;
}
