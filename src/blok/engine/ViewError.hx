package blok.engine;

import haxe.Exception;

enum ViewError {
	ViewAlreadyExists(view:View);
	InsertionFailed(view:View, ?message:String);
	UpdateFailed(view:View, ?message:String);
	RemovalFailed(view:View, ?message:String);
	IncorrectNodeType(view:View, node:Node);
	HydrationMismatch(view:View, expected:String, actual:Any);
	NoNodeFoundDuringHydration(view:View, expected:String);
	CausedException(view:View, exception:Exception);
}
