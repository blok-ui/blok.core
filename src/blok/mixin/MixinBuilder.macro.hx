package blok.mixin;

import blok.macro.*;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import kit.macro.*;

using Lambda;
using blok.macro.Tools;
using haxe.macro.Tools;
using kit.macro.Tools;

function buildGeneric() {
	return switch Context.getLocalType() {
		case TInst(_, [params]):
			prepareMixin(params);
		default:
			throw 'assert';
	}
}

function build() {
	return ClassBuilder
		.fromContext()
		.addBundle(new MixinBuilder())
		.export();
}

private function prepareMixin(params:Type) {
	var cls = Context.getLocalClass().get();
	var raw = params.toComplexType();
	var parsedFields:Array<Field> = [];

	// Parse fields to match the generated field types in Components. This will have to
	// be kept in sync with the BuildSteps.
	switch raw {
		case TAnonymous(fields):
			for (field in fields) switch field.kind {
				case FVar(t, _) | FProp('default', 'never', t, _):
					switch field.meta {
						case null | []:
							field.pos.error('Expected metadata');
						case [{name: ':attribute'}]:
							parsedFields.push({
								name: field.name,
								kind: FProp('get', 'never', t),
								pos: field.pos,
							});
						case [{name: ':context'}]:
							parsedFields.push({
								name: field.name,
								kind: FProp('get', 'never', t),
								pos: field.pos,
							});
						case [{name: ':observable'}]:
							parsedFields.push({
								name: field.name,
								kind: FProp('get', 'never', macro :blok.signal.Signal.ReadOnlySignal<$t>),
								pos: field.pos,
							});
						case [{name: ':signal'}]:
							parsedFields.push({
								name: field.name,
								access: [AFinal],
								kind: FVar(macro :blok.signal.Signal<$t>),
								pos: field.pos,
							});
						case [{name: ':computed'}]:
							parsedFields.push({
								name: field.name,
								access: [AFinal],
								kind: FVar(macro :blok.signal.Computation<$t>),
								pos: field.pos,
							});
						case [other]:
							other.pos.error('Invalid attribute');
						case tooMany:
							tooMany[1].pos.error('Too many attributes');
					}
				case FFun(f):
					parsedFields.push(field);
				default:
					field.pos.error('Invalid definition');
			}
		default:
			cls.pos.error('Expected an anonymous type');
	}

	var parsed:ComplexType = TAnonymous(parsedFields);
	return macro :blok.mixin.MixinBase<$parsed>;
}

class MixinBuilder implements BuildBundle implements BuildStep {
	public final priority:Priority = Late;

	public function new() {}

	public function apply(builder:ClassBuilder) {
		var init = builder.hook(Init).getExprs();
		var late = builder.hook(LateInit).getExprs();
		var setup = builder.setupHook().getExprs();
		var currentConstructor:Maybe<Field> = switch builder.findField('new') {
			case Some(field):
				switch field.kind {
					case FFun(f):
						if (f.args.length > 0) {
							field.pos.error(
								'You cannot pass arguments to this constructor -- it can only '
								+ 'be used to run code at initialization.');
						}
						setup.push(f.expr);
						Some(field);
					default:
						throw 'assert';
				}
			case None:
				None;
		}
		var func:Function = (macro function(view) {
			super(view);
			@:mergeBlock $b{init};
			blok.core.Owner.capture(this, {
				@:mergeBlock $b{late};
				@:mergeBlock $b{setup};
				null;
			});
		}).extractFunction();

		switch currentConstructor {
			case Some(field):
				field.kind = FFun(func);
			case None:
				builder.addField({
					name: 'new',
					access: [APublic],
					kind: FFun(func),
					pos: (macro null).pos
				});
		}
	}

	public function steps():Array<BuildStep> {
		return [
			new ComputedFieldBuildStep(),
			new ResourceFieldBuildStep(),
			new EffectBuildStep(),
			this
		];
	}
}
