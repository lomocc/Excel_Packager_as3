package
{
	import com.lipi.excel.Excel;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	
	public class Packager
	{
		public function Packager()
		{
		}
		
		private var files:Array = [];
		
		/**
		 * 打包数据为swf
		 * @param from 数据所在文件夹
		 * @param to 要输出的文件
		 */
		public function packageData(from:File, to:File):void
		{
			foreachFiles(from);
			saveData(to);
		}
		
		private function saveData(newFile:File):void
		{
			var contentBytes:ByteArray = new ByteArray();
			contentBytes.endian = Endian.LITTLE_ENDIAN;
			
			var header:Object = {};
			for each (var file:File in files)
			{
				var name:String = file.name;
				var dotIndex:int = name.lastIndexOf(".");
				if(dotIndex != -1)
				{
					name = name.slice(0, dotIndex);
				}
				header[name] = contentBytes.position;
				contentBytes.writeObject(getFileSheetArray(file));
			}
			
			var fileBytes:ByteArray = new ByteArray();
			fileBytes.endian = Endian.LITTLE_ENDIAN;
			fileBytes.writeObject(header);
			fileBytes.writeBytes(contentBytes);
			fileBytes.compress();
			
			var stream:FileStream = new FileStream();
			stream.open(newFile, FileMode.WRITE);
			stream.writeBytes(fileBytes);
			stream.close();
		}
		
		private function doPack():ByteArray
		{
			var output:Object = {};
			for each (var file:File in files)
			{
				var name:String = file.name;
				var dotIndex:int = name.lastIndexOf(".");
				if(dotIndex != -1)
				{
					name = name.slice(0, dotIndex);
				}
				output[name] = getFileSheetArray(file);
				//            ret.writeUTF(name);
				//
				//            var stream:FileStream = new FileStream();
				//            var tempByteArray:ByteArray = new ByteArray();
				//            stream.open(file, FileMode.READ);
				//            if (isUnicode(stream))
				//            {
				//                trace(name);
				//                var utf8String:String = stream.readMultiByte(stream.bytesAvailable, 'unicode');
				//                stream.open(file, FileMode.WRITE);
				//                stream.writeUTFBytes(utf8String);
				//                stream.open(file, FileMode.READ);
				//            }
				//            stream.readBytes(tempByteArray);
				//            stream.close();
				//            removeUTF8BOM(tempByteArray);
				//            ret.writeUnsignedInt(tempByteArray.bytesAvailable);
				//            ret.writeBytes(tempByteArray, tempByteArray.position);
			}
			var bytes:ByteArray = new ByteArray();
			bytes.endian = Endian.LITTLE_ENDIAN;
			bytes.writeObject(output);
			bytes.compress();
			return bytes;
		}
		/**
		 * 获取excel文件里的列表项数组
		 * @param file
		 * @return 
		 */	
		private function getFileSheetArray(file:File):Array
		{
			var fileBytes:ByteArray = new ByteArray();
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.READ);
			stream.readBytes(fileBytes);
			stream.close();
			
			var excel:Excel = new Excel(fileBytes);
			var sheetArray:Array = excel.getSheetArray();
			var sheetCount:int = sheetArray.length;
			var totalColumns:int = 0;
			var columnKeys:Dictionary = new Dictionary();
			//哪些列没有key
			var noKeyClolumn:Dictionary = new Dictionary();
			var items:Array = [];
			for (var i:int = 0; i < sheetCount; i++)
			{
				var row:Array = sheetArray[i];
				//忽略第一行 key存放在第二行
				if(i == 0 || !row || row.length == 0)
					continue;
				//如果是第二行 确定key
				if (i == 1)
				{
					totalColumns = row.length;
					
					for (var k:int = 0; k < totalColumns; k++) 
					{
						//去除没有key的列
						if(!row[k]){
							noKeyClolumn[k] = true;
						}else
						{
							columnKeys[k] = row[k];
						}
					}
					
				}else
				{
					var rowObject:Object = {};
					for (var j:int = 0; j < totalColumns; j++)
					{
						//去除没有key的列
						if(noKeyClolumn[j])
							continue;
						rowObject[columnKeys[j]] =  row[j];
					}
					items.push(rowObject);
				}
			}
			return items;
		}
		/**
		 * 判断是不是unicode 编码一直是个麻烦的问题
		 */
		private function isUnicode(stream:FileStream):Boolean
		{
			var prePosition:Number = stream.position;
			stream.position = 0;
			var r:Boolean = stream.readUnsignedByte() == 0xFF
				&& stream.readUnsignedByte() == 0xFE;
			stream.position = prePosition;
			return r;
		}
		
		private function removeUTF8BOM(ba:ByteArray):void
		{
			//去掉 utf-8 BOM签名
			ba.position = 0;
			if (!(ba.readUnsignedByte() == 0xEF && ba.readUnsignedByte() == 0xBB
				&& ba.readUnsignedByte() == 0xBF))
			{
				ba.position = 0;
			}
		}
		
		private function foreachFiles(dirFile:File):void
		{
			if (dirFile.exists)
			{ //指定的file对象是否存在
				if (dirFile.isDirectory)
				{ //指定的file对象是否是目录
					var sonFileArray:Array = dirFile.getDirectoryListing();
					var sonsLength:uint = sonFileArray.length;
					for (var i:int = 0; i < sonsLength; i++)
					{
						if (sonFileArray[i].isDirectory)
						{ //是否为目录
							//trace("是目录---" + sonFileArray[i].nativePath);
							//makeDir(sonFileArray[i]);
							foreachFiles(sonFileArray[i]);
						}
						else
						{
							//只支持excel2007的文件
							if (sonFileArray[i].extension
								&& sonFileArray[i].extension.toLowerCase() == "xlsx")
							{
								files.push(sonFileArray[i]);
							}
						}
					}
				}
				else
				{
					//trace("指定的对象不是目录");
				}
			}
			else
			{
				//trace("指定的对象目录不存在");
			}
		}
	}
}
