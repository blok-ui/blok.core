package blok.engine;

import haxe.Exception;

enum ViewError {
	ViewAlreadyExists(view:View);
	ViewInsertionFailed(view:View, ?message:String);
	ViewIncorrectNodeType(view:View, node:Node);
	ViewException(view:View, exception:Exception);
	ViewHydrationMismatch(view:View, expected:String, actual:Any);
	ViewHydrationNoNode(view:View, expected:String);
}
