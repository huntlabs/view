module view.parser;

import std.stdio;
import std.conv;
import std.algorithm;
import std.variant;
import std.array;
import std.string;
import std.typetuple;

import view;

abstract class Expression
{
	public string Evaluate(ViewContext ctx = null);
}
class Constant : Expression
{
	public string value;
	public this(string value)
	{
		this.value = value;
	}
	override public string Evaluate(ViewContext ctx = null )
	{
		return " str ~= `" ~ value ~ "`;";
	}
}

class VariableReference : Expression
{
	public string value;
	public this(string value)
	{
		this.value = value;
	}
	override public string Evaluate(ViewContext ctx = null)
	{
		return " str ~= std.conv.to!string(" ~ value ~ ");";
	}
}
class ExecuteBlock : Expression
{
	public string value;
	public this(string value)
	{
		this.value = value;
	}
	override public string Evaluate(ViewContext ctx = null)
	{
		return value;
	}
}
class Operation : Expression
{
	public Expression left;
	public Expression value;
	public Expression right;
	public this(Expression left,Expression value,Expression right)
	{
		this.left = left;
		this.value = value;
		this.right = right;
	}
	override public string Evaluate(ViewContext ctx = null)
	{  
		auto x = left.Evaluate(ctx);  
		auto y = right.Evaluate(ctx);  
		return x ~ value.Evaluate(ctx) ~ y;  
	}  
}
Expression strToTree(string str,int s,int t)
{
	if(s >= t)return new Constant(null);
	//version(Debug){writeln(__FUNCTION__," ",__LINE__,"= s:",s," t:",t," str:",str[s..t]);}
	bool findVar = false;
	bool findExe = false;
	int ves,vet;
	for(int i = s;i<t;i++)
	{
		if((i+2 <= t ) && canFind(["{{","{%"],str[i..i+2]))
		{
			ves = i;
			if(str[i+1] == '{') findVar = true;
			else findExe = true;
			for(int k = i;k<t;k++)
			{
				if(canFind(["}}","%}"],str[k..k+2]))
				{
					vet = k+2;
					break;
				}
			}
			break;
		}
	}
	//version(Debug){writeln(__FUNCTION__," ",__LINE__,"= findVar:",findVar,
	//		" findExe:",findExe," ves:",ves," vet:",vet);}
	if(ves==0 && !findVar && !findExe)return new Constant(str[s..t]);
	if(findVar && ves==s && vet==t)return new VariableReference(str[ves+2 .. vet-2]);
	if(findExe && ves==s && vet==t)return new ExecuteBlock(str[ves+2 .. vet-2]);
	if(str[ves .. ves+2] == "{%")
		return new Operation(strToTree(str,s,ves),new ExecuteBlock(str[ves+2 .. vet-2]),strToTree(str,vet,t));
	else 
		return new Operation(strToTree(str,s,ves),new VariableReference(str[ves+2 .. vet-2]),strToTree(str,vet,t));
}

class Parser 
{
	public string str;
	public string FunHeader = `
		static string TempleFunc(ViewContext var,CompiledTemple* ct = null){
			string render(string _view_file)(){
				return render_with!_view_file(var);
			}
			string render_with(string _view_file)(ViewContext var = null){
				auto r = display!(_view_file)();
				return r.toString(var);
			}
			string yield(){
				return ct.toString(var);
			}
			string str;
			with(var){
				`;
				public string FunFooter = `
			}
			return str;
		}`;
	public Expression ast = null;
	public ViewContext ctx = null;
	this(string str)
	{
		//version(Debug){writeln(__FUNCTION__," ",__LINE__,"= str:",str);}
		this.str = str;
		this.ast = strToTree(str,0,str.length.to!int );
	}
	override string toString()
	{
		return FunHeader ~ ast.Evaluate(ctx) ~ FunFooter;
	}

}


unittest 
{
	auto p = new Parser(```{% import std.stdio; %}<div>{{value["name"]}}```);	
	assert(p.ast.Evaluate() == " str ~= ``; import std.stdio;  str ~= `<div>`; str ~= std.conv.to!string(value[\"name\"]); str ~= ``;");
}

