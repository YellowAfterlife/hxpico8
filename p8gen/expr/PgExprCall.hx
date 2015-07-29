package p8gen.expr;
import haxe.macro.Type;
import p8gen.PgBuffer;
import p8gen.struct.PgClass;
import p8gen.PgMain.error;
using p8gen.PgExpr;

/**
 * ...
 * @author YellowAfterlife
 */
@:publicFields
class PgExprCall {
	static function addArgs(r:PgBuffer, args:Array<TypedExpr>, ?inst:TypedExpr) {
		var comma:Bool = false;
		if (inst != null) {
			switch (inst.expr) {
			case TConst(TSuper): r.addString("this");
			default: r.addExpr(inst);
			}
			comma = true;
		}
		for (arg in args) {
			if (comma) r.addComma(); else comma = true;
			r.addExpr(arg);
		}
	}
	static function addExprCall(r:PgBuffer, e:TypedExpr, args:Array<TypedExpr>) {
		var fname = {
			var b = new PgBuffer();
			b.addExpr(e);
			b.toString();
		};
		//
		var inst:TypedExpr = null;
		switch (e.expr) {
		case TField(e, fa):
			inst = e;
			switch (fa) {
			case FEnum(et_ref, ef):
				r.addChar("{".code);
				r.addSep();
				r.addInt(ef.index);
				if (args.length > 0) {
					r.addComma();
					addArgs(r, args);
				}
				r.addSep();
				r.addChar("}".code);
				return;
			case FStatic(_, _): inst = null;
			default:
			}
		default:
		}
		//
		switch (fname) {
		case "`trace": {
			var i:Int = 0, n:Int = args.length;
			r.addString("print(");
			switch (args[n - 1].expr) {
			case TObjectDecl(fields):
				if (fields[0].name == "fileName" && fields[1].name == "lineNumber") {
					r.addChar('"'.code);
					switch (fields[0].expr.expr) {
					case TConst(TString(s)): r.addString(s.toLowerCase());
					default:
					}
					r.addChar(":".code);
					switch (fields[1].expr.expr) {
					case TConst(TInt(i)): r.addInt(i);
					default:
					}
					r.addChar2(":".code, " ".code);
					while (i < n) {
						switch (args[i].expr) {
						case TConst(TString(s)): {
							r.addString(s);
							i++;
							continue;
						};
						case TBinop(OpAdd, { expr: TConst(TString(s)) }, e2): {
							r.addString(s);
							r.addChar('"'.code);
							r.addSepChar2(".".code, ".".code);
							r.addExpr(e2);
							i++;
						};
						default: r.addChar('"'.code);
						}
						break;
					}
				} // (if correct format)
				n--;
			default:
			}
			while (i < n) {
				r.addSepChar2(".".code, ".".code);
				r.addExpr(args[i]);
				i++;
			}
			r.addChar(")".code);
		}
		case "collection": {
			switch (args[0].expr) {
			case TArrayDecl(args):
				r.addChar("{".code);
				if (args.length > 0) {
					r.addSep();
					var trail = false;
					for (arg in args) {
						if (trail) r.addComma(); else trail = true;
						r.addExpr(arg);
					}
				}
				r.addSep();
				r.addChar("}".code);
			default: r.addExpr(args[0]);
			}
		}
		case "super": {
			r.addString(PgClass.current.parent.constructor.path);
			r.addChar("(".code);
			inst = { expr: TConst(TThis), pos: e.pos, t: e.t };
			addArgs(r, args, inst);
			r.addChar(")".code);
		}
		default: {
			r.addString(fname);
			r.addChar("(".code);
			addArgs(r, args, inst);
			r.addChar(")".code);
		}
		}
	}
}