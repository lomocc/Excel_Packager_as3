package utils
{
	import com.lipi.excel.Excel;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	import vo.KeyVo;
	import vo.PackageVo;
	import vo.SheetVo;
	
	public class Packager
	{
		public function Packager()
		{
		}
		/**
		 * 打包数据为swf
		 * @param from 数据所在文件夹
		 * @param to 要输出的文件
		 */
		public static function write(from:File, saveto:File):void
		{
			var packageVo:PackageVo =  filesToBytes(from);
			var stream:FileStream = new FileStream();
			stream.open(saveto, FileMode.WRITE);
			stream.writeBytes(packageVo.resultBytes);
			stream.close();
			
			var savetoFormat:File = saveto.parent.resolvePath(saveto.name + ".txt");
			var stream2:FileStream = new FileStream();
			stream2.open(savetoFormat, FileMode.WRITE);
			stream2.writeBytes(packageVo.formatBytes);
			stream2.close();
		}
		private static function getFileXMLArray(file:File):SheetVo
		{
			var fileBytes:ByteArray = new ByteArray();
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.READ);
			stream.readBytes(fileBytes);
			stream.close();
			var xml:XML = new XML(fileBytes);
			var items:Array = [];
			for each(var item:XML in xml.children()) 
			{
				var obj:Object = {};
				for each(var attr:XML in item.attributes() )
				{
					obj[attr.name().toString()] = attr.toString();
				}

				items[items.length] = obj;
			}
			var sheet:SheetVo = new SheetVo();
//			sheet.columnKeys = columnKeys;
			sheet.contents = items;
			return sheet;
		}
		/**
		 * 获取excel文件里的列表项数组
		 * @param file
		 * @return 
		 */	
		private static function getFileSheetArray(file:File):SheetVo
		{
			var fileBytes:ByteArray = new ByteArray();
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.READ);
			stream.readBytes(fileBytes);
			stream.close();
			
			var excel:Excel = new Excel(fileBytes);
			var sheetArray:Array = excel.getSheetArray();
			
			var columnKeys:Dictionary = new Dictionary();
			
			var row0:Array = sheetArray[0];
			var row1:Array = sheetArray[1];
			var row2:Array = sheetArray[2];
			var totalColumns:int = row2.length;
			var keyVo:KeyVo;
			for (var k:int = 0; k < totalColumns; k++) 
			{
				//去除没有key的列
				if(row2[k])
				{
//					keyVo.type = row1[k];
					
					var isArray:Boolean = false;
					var secondType:String = null;
					var keytype:String = row1[k];
					
					if(keytype)
					{
						var lowerCaseKeytype:String = keytype.toLowerCase();
						if(lowerCaseKeytype.indexOf("int") != -1)
						{
							secondType = "int";
						}else if(lowerCaseKeytype.indexOf("number") != -1)
						{
							secondType = "Number";
						}else
						{
							secondType = "String";
						}
						if(lowerCaseKeytype.indexOf("array") != -1)
						{
							isArray = true;
						}
					}else
					{
						secondType = "String";
					}
					keyVo = new KeyVo();
					keyVo.name = trim(row2[k]);
					keyVo.isArray = isArray;
					keyVo.secondType = secondType;
					keyVo.desc = row0[k];
					columnKeys[k] = keyVo;
				}
			}
			var items:Array = [];
			for (var i:int = 3, l:int = sheetArray.length; i < l; i++)
			{
				var row:Array = sheetArray[i];
				var rowObject:Object = {};
				var validRow:Boolean = false;// 是否合法（是否全为空）
				for (var j:int = 0; j < totalColumns; j++)
				{
					keyVo = columnKeys[j];
					//去除没有key的列
					if(keyVo && row.hasOwnProperty(j))
					{
						if(!validRow && row[j] != null)
						{
							validRow = true;
						}
						// 把excel里的值转化为Array、int、Number
						var propValue:* = null;
						var valueStr:String = row[j] || "";
						if(keyVo.isArray)
						{
							propValue = valueStr.split(",").map(
								function(item:String, ...args):*
								{
									return getValueByType(item, keyVo.secondType)
								}
							);
						}else
						{
							propValue = getValueByType(valueStr, keyVo.secondType);
						}
						rowObject[keyVo.name] = propValue;
					}
				}
				if(validRow)
				{
					items[items.length] = rowObject;
				}else
				{
					trace();
				}
			}
			var sheet:SheetVo = new SheetVo();
			sheet.columnKeys = columnKeys;
			sheet.contents = items;
			return sheet;
		}
		/**
		 * 去掉非合法的id的字符
		 * @param v
		 * @return 
		 * 
		 */		
		private static function trim(v:String):String
		{
			return v.replace(/[^a-zA-Z_0-9]/g, "");
		}
		protected static function getValueByType(input:String, type:String):*
		{
			switch(type)
			{
				case "int":
				{
					return parseInt(input) || 0;
					break;
				}
				case "Number":
				{
					return parseFloat(input) || 0;
					break;
				}
				default:
				{
					return input;
					break;
				}
			}
			return input;
		}
		
		private static function filesToBytes(dirFile:File):PackageVo
		{
			if (!dirFile.exists)
			{
				Alert.show("指定的对象目录不存在: " + dirFile.url);
				return null;
			}
			var classContens:Array = [];
			var formatBytes:ByteArray = new ByteArray();
			var header:Object = {};
			var contentBytes:ByteArray = new ByteArray();
			
			var name:String;
			var dotIndex:int;
			var sheet:SheetVo;
			//指定的file对象是否存在
			eachFile(dirFile, 
				function(file:File):void
			{
				if (file.extension
					&& file.extension.toLowerCase() == "xlsx")
				{
					//只支持excel2007的文件
					name = file.name;
					dotIndex = name.lastIndexOf(".");
					if(dotIndex != -1)
					{
						name = name.slice(0, dotIndex);
					}
					header[name] = contentBytes.position;
					try{
						sheet = getFileSheetArray(file);
					}catch(e:*)
					{
						// 空文件
						return;
					}
					contentBytes.writeObject(sheet.contents);
					
					
					var props:Array = [];
					for each (var keyVo:KeyVo in sheet.columnKeys)
					{
						props[props.length] = formatString(
							"\t\t/**\r\n\t\t * {3}\r\n\t\t */\r\n\t\tpublic var {0}:{1};{2}",
							keyVo.name, 
							keyVo.isArray?"Array":keyVo.secondType,
							keyVo.isArray?"// Aray of " + keyVo.secondType:"",
							keyVo.desc || ""
						);
					}
					classContens[classContens.length] = formatString("////////////////////////////////////////////////////////////////////////////////" +
						"\r\n// {0}.xlsx\r\n" +
						"////////////////////////////////////////////////////////////////////////////////" +
						"\r\npackage\r\n{\r\n\tpublic class {0}Vo\r\n\t{\r\n{1}\r\n\t}\r\n}", name, props.join("\r\n"));
				}else if (file.extension
					&& file.extension.toLowerCase() == "xml")
				{
					name = file.name;
					dotIndex = name.lastIndexOf(".");
					if(dotIndex != -1)
					{
						name = name.slice(0, dotIndex);
					}
					header[name] = contentBytes.position;
					sheet = getFileXMLArray(file);
					contentBytes.writeObject(sheet.contents);
				}
			});
			
			formatBytes.writeUTFBytes(classContens.join("\r\n"));
			
			var resultBytes:ByteArray = new ByteArray();
			resultBytes.writeObject(header);
			resultBytes.writeBytes(contentBytes);
			resultBytes.compress();
			
			var packageVo:PackageVo = new PackageVo();
			packageVo.resultBytes = resultBytes;
			packageVo.formatBytes = formatBytes;
			return packageVo;
		}
		
		
		private static function eachFile(dirFile:File, fun:Function):void
		{
			for each (var file:File in dirFile.getDirectoryListing()) 
			{
				if(file.isDirectory)
				{
					eachFile(file, fun);
				}else
				{
					fun(file);
				}
			}
		}
		/**
		 * 判断是不是unicode 编码一直是个麻烦的问题
		 */
		internal function isUnicode(stream:FileStream):Boolean
		{
			var prePosition:Number = stream.position;
			stream.position = 0;
			var r:Boolean = stream.readUnsignedByte() == 0xFF
				&& stream.readUnsignedByte() == 0xFE;
			stream.position = prePosition;
			return r;
		}
		
		internal function removeUTF8BOM(ba:ByteArray):void
		{
			//去掉 utf-8 BOM签名
			ba.position = 0;
			if (!(ba.readUnsignedByte() == 0xEF && ba.readUnsignedByte() == 0xBB
				&& ba.readUnsignedByte() == 0xBF))
			{
				ba.position = 0;
			}
		}
	}
}
