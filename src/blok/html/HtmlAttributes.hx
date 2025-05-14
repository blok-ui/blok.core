package blok.html;

import blok.engine.Key;
import blok.signal.Signal;

// Taken from: https://github.com/haxetink/tink_domspec/blob/master/src/tink/domspec/Aria.hx
typedef AriaAttributes = {
	@:html('aria-label') var ?ariaLabel:ReadOnlySignal<String>;
	@:html('aria-current') var ?ariaCurrent:ReadOnlySignal<String>;
	@:html('aria-labeledby') var ?ariaLabelledby:ReadOnlySignal<String>;
	@:html('aria-describedby') var ?ariaDescribedby:ReadOnlySignal<String>;
	@:html('aria-autocomplete') var ?ariaAutocomplete:ReadOnlySignal<String>;
	@:html('aria-dropeffect') var ?ariaDropEffect:ReadOnlySignal<String>;
	@:html('aria-hidden') var ?ariaHidden:ReadOnlySignal<Bool>;
	@:html('aria-disabled') var ?ariaDisabled:ReadOnlySignal<Bool>;
	@:html('aria-checked') var ?ariaChecked:ReadOnlySignal<Bool>;
	@:html('aria-haspopup') var ?ariaHasPopup:ReadOnlySignal<Bool>;
	@:html('aria-grabbed') var ?ariaGrabbed:ReadOnlySignal<Bool>;
	@:html('aria-valuenow') var ?ariaValuenow:ReadOnlySignal<Float>;
	@:html('aria-valuemin') var ?ariaValuemin:ReadOnlySignal<Float>;
	@:html('aria-valuemax') var ?ariaValuemax:ReadOnlySignal<Float>;
	@:html('aria-valuetext') var ?ariaValuetext:ReadOnlySignal<String>;
	@:html('aria-modal') var ?ariaModal:ReadOnlySignal<String>;
}

// From https://github.com/haxetink/tink_domspec/blob/master/src/tink/domspec/Attributes.hx
typedef GlobalAttributes = AriaAttributes & {
	@:html('class') var ?className:ReadOnlySignal<String>;
	var ?id:ReadOnlySignal<String>;
	var ?title:ReadOnlySignal<String>;
	var ?lang:ReadOnlySignal<String>;
	var ?dir:ReadOnlySignal<String>;
	var ?contentEditable:ReadOnlySignal<Bool>;
	var ?inputMode:ReadOnlySignal<Bool>;
	var ?hidden:ReadOnlySignal<Bool>;
	var ?tabIndex:ReadOnlySignal<Int>;
	var ?accessKey:ReadOnlySignal<String>;
	var ?draggable:ReadOnlySignal<Bool>;
	var ?spellcheck:ReadOnlySignal<Bool>;
	var ?style:ReadOnlySignal<String>;
	var ?role:ReadOnlySignal<String>;
	var ?dataset:ReadOnlySignal<Map<String, String>>;
	var ?key:Key;
}

typedef DetailsAttributes = GlobalAttributes & {
	var ?open:ReadOnlySignal<Bool>;
}

typedef FieldSetAttributes = GlobalAttributes & {
	var ?disabled:ReadOnlySignal<Bool>;
	var ?name:ReadOnlySignal<String>;
}

typedef ObjectAttributes = GlobalAttributes & {
	var ?type:ReadOnlySignal<String>;
	var ?data:ReadOnlySignal<String>;
	var ?width:ReadOnlySignal<Int>;
	var ?height:ReadOnlySignal<Int>;
}

typedef ParamAttributes = GlobalAttributes & {
	var ?name:ReadOnlySignal<String>;
	var ?value:ReadOnlySignal<String>;
}

typedef TableCellAttributes = GlobalAttributes & {
	var ?abbr:ReadOnlySignal<String>;
	var ?colSpan:ReadOnlySignal<Int>;
	var ?headers:ReadOnlySignal<String>;
	var ?rowSpan:ReadOnlySignal<Int>;
	var ?scope:ReadOnlySignal<String>;
	var ?sorted:ReadOnlySignal<String>;
}

enum abstract InputType(String) to String {
	var Text = 'text';
	var Button = 'button';
	var Checkbox = 'checkbox';
	var Color = 'color';
	var Date = 'date';
	var DatetimeLocal = 'datetime-local';
	var Email = 'email';
	var File = 'file';
	var Hidden = 'hidden';
	var Image = 'image';
	var Month = 'month';
	var Number = 'number';
	var Password = 'password';
	var Radio = 'radio';
	var Range = 'range';
	var Reset = 'reset';
	var Search = 'search';
	var Tel = 'tel';
	var Submit = 'submit';
	var Time = 'time';
	var Url = 'url';
	var Week = 'week';
}

typedef InputAttributes = GlobalAttributes & {
	var ?checked:ReadOnlySignal<Bool>;
	var ?disabled:ReadOnlySignal<Bool>;
	var ?required:ReadOnlySignal<Bool>;
	var ?autofocus:ReadOnlySignal<Bool>;
	var ?autocomplete:ReadOnlySignal<String>;
	var ?value:ReadOnlySignal<String>;
	var ?readOnly:ReadOnlySignal<Bool>;
	@:html('value') var ?defaultValue:ReadOnlySignal<String>;
	var ?type:ReadOnlySignal<InputType>;
	var ?name:ReadOnlySignal<String>;
	var ?placeholder:ReadOnlySignal<String>;
	var ?max:ReadOnlySignal<String>;
	var ?min:ReadOnlySignal<String>;
	var ?step:ReadOnlySignal<String>;
	var ?maxLength:ReadOnlySignal<Int>;
	var ?pattern:ReadOnlySignal<String>;
	var ?accept:ReadOnlySignal<String>;
	var ?multiple:ReadOnlySignal<Bool>;
}

typedef ButtonAttributes = GlobalAttributes & {
	var ?disabled:ReadOnlySignal<Bool>;
	var ?autofocus:ReadOnlySignal<Bool>;
	var ?type:ReadOnlySignal<String>;
	var ?name:ReadOnlySignal<String>;
}

typedef TextAreaAttributes = GlobalAttributes & {
	var ?autofocus:ReadOnlySignal<Bool>;
	var ?cols:ReadOnlySignal<Int>;
	var ?dirname:ReadOnlySignal<String>;
	var ?disabled:ReadOnlySignal<Bool>;
	var ?form:ReadOnlySignal<String>;
	var ?maxlength:ReadOnlySignal<Int>;
	var ?name:ReadOnlySignal<String>;
	var ?placeholder:ReadOnlySignal<String>;
	var ?readOnly:ReadOnlySignal<Bool>;
	var ?required:ReadOnlySignal<Bool>;
	var ?rows:ReadOnlySignal<Int>;
	var ?value:ReadOnlySignal<String>;
	var ?defaultValue:ReadOnlySignal<String>;
	var ?wrap:ReadOnlySignal<String>;
}

typedef IFrameAttributes = GlobalAttributes & {
	var ?sandbox:ReadOnlySignal<String>;
	var ?width:ReadOnlySignal<Int>;
	var ?height:ReadOnlySignal<Int>;
	var ?src:ReadOnlySignal<String>;
	var ?srcdoc:ReadOnlySignal<String>;
	var ?allowFullscreen:ReadOnlySignal<Bool>;
	@:deprecated var ?scrolling:ReadOnlySignal<IframeScrolling>;
}

enum abstract IframeScrolling(String) {
	var Yes = "yes";
	var No = "no";
	var Auto = "auto";
}

typedef ImageAttributes = GlobalAttributes & {
	var ?src:ReadOnlySignal<String>;
	var ?width:ReadOnlySignal<Int>;
	var ?height:ReadOnlySignal<Int>;
	var ?alt:ReadOnlySignal<String>;
	var ?srcset:ReadOnlySignal<String>;
	var ?sizes:ReadOnlySignal<String>;
}

private typedef MediaAttributes = GlobalAttributes & {
	var ?src:ReadOnlySignal<String>;
	var ?autoplay:ReadOnlySignal<Bool>;
	var ?controls:ReadOnlySignal<Bool>;
	var ?loop:ReadOnlySignal<Bool>;
	var ?muted:ReadOnlySignal<Bool>;
	var ?preload:ReadOnlySignal<String>;
	var ?volume:ReadOnlySignal<Float>;
}

typedef AudioAttributes = MediaAttributes & {};

typedef VideoAttributes = MediaAttributes & {
	var ?height:ReadOnlySignal<Int>;
	var ?poster:ReadOnlySignal<String>;
	var ?width:ReadOnlySignal<Int>;
	var ?playsInline:ReadOnlySignal<Bool>;
}

typedef SourceAttributes = GlobalAttributes & {
	var ?src:ReadOnlySignal<String>;
	var ?srcset:ReadOnlySignal<String>;
	var ?media:ReadOnlySignal<String>;
	var ?sizes:ReadOnlySignal<String>;
	var ?type:ReadOnlySignal<String>;
}

typedef LabelAttributes = GlobalAttributes & {
	@:html('for') var ?htmlFor:ReadOnlySignal<String>;
}

typedef SelectAttributes = GlobalAttributes & {
	var ?autofocus:ReadOnlySignal<Bool>;
	var ?disabled:ReadOnlySignal<Bool>;
	var ?multiple:ReadOnlySignal<Bool>;
	var ?value:ReadOnlySignal<String>;
	var ?name:ReadOnlySignal<String>;
	var ?required:ReadOnlySignal<Bool>;
	var ?size:ReadOnlySignal<Int>;
}

typedef FormAttributes = GlobalAttributes & {
	var ?method:ReadOnlySignal<String>;
	var ?action:ReadOnlySignal<String>;
}

typedef AnchorAttributes = GlobalAttributes & {
	var ?href:ReadOnlySignal<String>;
	var ?target:ReadOnlySignal<String>;
	var ?type:ReadOnlySignal<String>;
	var ?rel:ReadOnlySignal<AnchorRel>;
}

typedef OptionAttributes = GlobalAttributes & {
	var ?disabled:ReadOnlySignal<Bool>;
	var ?label:ReadOnlySignal<String>;
	@:jsOnly var ?defaultSelected:ReadOnlySignal<Bool>;
	var ?selected:ReadOnlySignal<Bool>;
	var ?value:ReadOnlySignal<String>;
	var ?text:ReadOnlySignal<String>;
	var ?index:ReadOnlySignal<Int>;
}

typedef MetaAttributes = GlobalAttributes & {
	var ?content:ReadOnlySignal<String>;
	var ?name:ReadOnlySignal<String>;
	var ?charset:ReadOnlySignal<String>;
	var ?httpEquiv:ReadOnlySignal<MetaHttpEquiv>;
}

enum abstract MetaHttpEquiv(String) to String from String {
	var ContentType = "content-type";
	var DefaultStyle = "default-style";
	var Refresh = "refresh";
}

typedef LinkAttributes = GlobalAttributes & {
	var ?rel:ReadOnlySignal<LinkRel>;
	var ?crossorigin:ReadOnlySignal<LinkCrossOrigin>;
	var ?href:ReadOnlySignal<String>;
	var ?hreflang:ReadOnlySignal<String>;
	var ?media:ReadOnlySignal<String>;
	var ?sizes:ReadOnlySignal<String>;
	var ?type:ReadOnlySignal<String>;
}

enum abstract LinkRel(String) to String from String {
	var Alternate = "alternate";
	var Author = "author";
	var DnsPrefetch = "dns-prefetch";
	var Help = "help";
	var Icon = "icon";
	var License = "license";
	var Next = "next";
	var Pingback = "pingback";
	var Preconnect = "preconnect";
	var Prefetch = "prefetch";
	var Preload = "preload";
	var Prerender = "prerender";
	var Prev = "prev";
	var Search = "search";
	var Stylesheet = "stylesheet";
}

enum abstract AnchorRel(String) to String from String {
	var Alternate = "alternate";
	var Author = "author";
	var Bookmark = "bookmark";
	var External = "external";
	var Help = "help";
	var License = "license";
	var Next = "next";
	var NoFollow = "nofollow";
	var NoReferrer = "noreferrer";
	var NoOpener = "noopener";
	var Prev = "prev";
	var Search = "search";
	var Tag = "tag";
}

enum abstract LinkCrossOrigin(String) to String from String {
	final Anonymous = "anonymous";
	final UseCredentials = "use-credentials";
}

typedef ScriptAttributes = GlobalAttributes & {
	var ?async:ReadOnlySignal<Bool>;
	var ?charset:ReadOnlySignal<String>;
	var ?defer:ReadOnlySignal<Bool>;
	var ?src:ReadOnlySignal<String>;
	var ?type:ReadOnlySignal<String>;
}

typedef StyleAttributes = GlobalAttributes & {
	var ?type:ReadOnlySignal<String>;
	var ?media:ReadOnlySignal<String>;
	var ?nonce:ReadOnlySignal<String>;
}

typedef CanvasAttributes = GlobalAttributes & {
	var ?width:ReadOnlySignal<String>;
	var ?height:ReadOnlySignal<String>;
}

typedef TrackAttributes = {
	var ?src:ReadOnlySignal<String>;
	var ?kind:ReadOnlySignal<TrackKind>;
	var ?label:ReadOnlySignal<String>;
	var ?srclang:ReadOnlySignal<String>;
}

enum abstract TrackKind(String) to String from String {
	var Subtitles = 'subtitles';
	var Captions = 'captions';
	var Descriptions = 'descriptions';
	var Chapters = 'chapters';
	var Metadata = 'metadata';
}

typedef EmbedAttributes = {
	var ?height:ReadOnlySignal<Int>;
	var ?width:ReadOnlySignal<Int>;
	var ?src:ReadOnlySignal<String>;
	var ?typed:ReadOnlySignal<String>;
}
