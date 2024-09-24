package blok.html;

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
typedef GlobalAttr = AriaAttributes & {
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
}

typedef DetailsAttr = GlobalAttr & {
	var ?open:ReadOnlySignal<Bool>;
}

typedef FieldSetAttr = GlobalAttr & {
	var ?disabled:ReadOnlySignal<Bool>;
	var ?name:ReadOnlySignal<String>;
}

typedef ObjectAttr = GlobalAttr & {
	var ?type:ReadOnlySignal<String>;
	var ?data:ReadOnlySignal<String>;
	var ?width:ReadOnlySignal<Int>;
	var ?height:ReadOnlySignal<Int>;
}

typedef ParamAttr = GlobalAttr & {
	var ?name:ReadOnlySignal<String>;
	var ?value:ReadOnlySignal<String>;
}

typedef TableCellAttr = GlobalAttr & {
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

typedef InputAttr = GlobalAttr & {
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

typedef ButtonAttr = GlobalAttr & {
	var ?disabled:ReadOnlySignal<Bool>;
	var ?autofocus:ReadOnlySignal<Bool>;
	var ?type:ReadOnlySignal<String>;
	var ?name:ReadOnlySignal<String>;
}

typedef TextAreaAttr = GlobalAttr & {
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

typedef IFrameAttr = GlobalAttr & {
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

typedef ImageAttr = GlobalAttr & {
	var ?src:ReadOnlySignal<String>;
	var ?width:ReadOnlySignal<Int>;
	var ?height:ReadOnlySignal<Int>;
	var ?alt:ReadOnlySignal<String>;
	var ?srcset:ReadOnlySignal<String>;
	var ?sizes:ReadOnlySignal<String>;
}

private typedef MediaAttr = GlobalAttr & {
	var ?src:ReadOnlySignal<String>;
	var ?autoplay:ReadOnlySignal<Bool>;
	var ?controls:ReadOnlySignal<Bool>;
	var ?loop:ReadOnlySignal<Bool>;
	var ?muted:ReadOnlySignal<Bool>;
	var ?preload:ReadOnlySignal<String>;
	var ?volume:ReadOnlySignal<Float>;
}

typedef AudioAttr = MediaAttr & {};

typedef VideoAttr = MediaAttr & {
	var ?height:ReadOnlySignal<Int>;
	var ?poster:ReadOnlySignal<String>;
	var ?width:ReadOnlySignal<Int>;
	var ?playsInline:ReadOnlySignal<Bool>;
}

typedef SourceAttr = GlobalAttr & {
	var ?src:ReadOnlySignal<String>;
	var ?srcset:ReadOnlySignal<String>;
	var ?media:ReadOnlySignal<String>;
	var ?sizes:ReadOnlySignal<String>;
	var ?type:ReadOnlySignal<String>;
}

typedef LabelAttr = GlobalAttr & {
	@:html('for') var ?htmlFor:ReadOnlySignal<String>;
}

typedef SelectAttr = GlobalAttr & {
	var ?autofocus:ReadOnlySignal<Bool>;
	var ?disabled:ReadOnlySignal<Bool>;
	var ?multiple:ReadOnlySignal<Bool>;
	var ?value:ReadOnlySignal<String>;
	var ?name:ReadOnlySignal<String>;
	var ?required:ReadOnlySignal<Bool>;
	var ?size:ReadOnlySignal<Int>;
}

typedef FormAttr = GlobalAttr & {
	var ?method:ReadOnlySignal<String>;
	var ?action:ReadOnlySignal<String>;
}

typedef AnchorAttr = GlobalAttr & {
	var ?href:ReadOnlySignal<String>;
	var ?target:ReadOnlySignal<String>;
	var ?type:ReadOnlySignal<String>;
	var ?rel:ReadOnlySignal<AnchorRel>;
}

typedef OptionAttr = GlobalAttr & {
	var ?disabled:ReadOnlySignal<Bool>;
	var ?label:ReadOnlySignal<String>;
	@:jsOnly var ?defaultSelected:ReadOnlySignal<Bool>;
	var ?selected:ReadOnlySignal<Bool>;
	var ?value:ReadOnlySignal<String>;
	var ?text:ReadOnlySignal<String>;
	var ?index:ReadOnlySignal<Int>;
}

typedef MetaAttr = GlobalAttr & {
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

typedef LinkAttr = GlobalAttr & {
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

typedef ScriptAttr = GlobalAttr & {
	var ?async:ReadOnlySignal<Bool>;
	var ?charset:ReadOnlySignal<String>;
	var ?defer:ReadOnlySignal<Bool>;
	var ?src:ReadOnlySignal<String>;
	var ?type:ReadOnlySignal<String>;
}

typedef StyleAttr = GlobalAttr & {
	var ?type:ReadOnlySignal<String>;
	var ?media:ReadOnlySignal<String>;
	var ?nonce:ReadOnlySignal<String>;
}

typedef CanvasAttr = GlobalAttr & {
	var ?width:ReadOnlySignal<String>;
	var ?height:ReadOnlySignal<String>;
}

typedef TrackAttr = {
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

typedef EmbedAttr = {
	var ?height:ReadOnlySignal<Int>;
	var ?width:ReadOnlySignal<Int>;
	var ?src:ReadOnlySignal<String>;
	var ?typed:ReadOnlySignal<String>;
}
