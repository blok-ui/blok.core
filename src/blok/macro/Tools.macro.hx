package blok.macro;

import kit.macro.ClassBuilder;

inline function setupHook(builder:ClassBuilder) {
	return builder.hook('setup');
}

inline function updateHook(builder:ClassBuilder) {
	return builder.hook('update');
}
