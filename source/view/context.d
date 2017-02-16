module view.context;

import std.variant;
import std.array;
import std.string;
import std.typetuple;

import view;

class ViewContext
{
	public Variant[string] vars;

	void opDispatch(string name, T)(T val)
	{
		if (name !in vars)
			vars[name] = Variant();

		vars[name] = val;
	}
	Variant opDispatch(string name)()
	{
		return vars[name];	
	}
}
