package utils
{
	/**
	 * 格式化输出 
	 * Formats a String in .Net-style, with curly braces ("{0}"). Does not support any 
	 * number formatting options yet. 
	 * <pre>formatString("{0} + {1} = {2}", 5, 7, 12)</pre>
	 * */
	public function formatString(format:String, ...args):String
	{
		if (format == null) return '';
		
		// Replace all of the parameters in the msg string.
		var len:uint = args.length;
		if (len == 1 && args[0] is Array)
		{
			args = args[0] as Array;
			len = args.length;
		}
		
		for (var i:int = 0; i < len; i++)
		{
			format = format.replace(new RegExp("\\{"+i+"\\}", "g"), args[i]);
		}
		return format;
	}
}