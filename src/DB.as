package com.throne.utils
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;


	public class DB
	{

		private static var _instance:DB;

		private static function getInstance():DB
		{
			if (_instance == null)
				return _instance = new DB();
			return _instance;
		}

		public static function readObject(fileName:String, mainKey:*, matchValue:*, columnKey:String = null):Object
		{
			var obj:Object = getInstance().read(fileName, mainKey, matchValue, columnKey);
			if (obj is Array)
				return obj[0];
			return obj;
		}

		public static function readValue(fileName:String, mainKey:*, matchValue:*):String
		{
			return getInstance().read(fileName, mainKey, matchValue, null);
		}
		
		public static function readExcel(fileName:String):Array
		{
			return getInstance().read(fileName, null, null, null, true) as Array;
		}
			
		public static function initDB(db:ByteArray):void
		{
			getInstance().initDB(db);
		}

		protected var _db:ByteArray;
		protected var _fileNameDic:Object;
		protected var _database:Object;

		/**
		 * 构造函数（客户端数据库）
		 * @param db
		 *
		 */
		public function DB(db:ByteArray = null)
		{
			if (db)
				initDB(db);
		}

		/**
		 * 初始化数据库
		 * @param db
		 *
		 */
		private function initDB(db:ByteArray):void
		{
			try
			{
				db.uncompress();
			} 
			catch(error:Error) 
			{
				
			}
			db.endian = Endian.LITTLE_ENDIAN;
			db.position = 0;
			_fileNameDic = db.readObject();
			
			_db = new ByteArray();
			_db.endian = Endian.LITTLE_ENDIAN;
			db.readBytes(_db);
			db.clear();
		}

		/**
		 * 读取数据库
		 * @param fileName
		 * @param mainKey
		 * @param matchValue
		 * @param columnKey
		 * @return
		 *
		 */
		private function read(fileName:String, mainKey:* = null, matchValue:* = null, columnKey:String = null, readMulti:Boolean = false):Object
		{
			if (mainKey == null || matchValue == null)
				return readAll(fileName);

			var targetRowArr:Array = new Array();

			var mainKeys:Array = (mainKey is Array)?mainKey:[String(mainKey)];
			var matchValues:Array = (matchValue is Array)?matchValue:[String(matchValue)];
			var mainKeyCount:int = Math.min(mainKeys.length, matchValues.length);

			var rowObjArr:Array = readAll(fileName);
			var rowCount:int = rowObjArr.length;
			for (var i:int = 0; i < rowCount; i++)
			{
				var flag_tmp:Boolean = true;
				var rowObj:Object = rowObjArr[i];
				for (var j:int = 0; j < mainKeyCount; j++)
				{
					if (rowObj[mainKeys[j]] != matchValues[j])
					{
						flag_tmp = false;
						break;
					}
				}
				if (flag_tmp)
				{
					targetRowArr.push(rowObj);
					if (!readMulti)
						break;
				}
			}

			if (columnKey && columnKey != "")
			{
				var returnArr:Array = new Array();
				rowCount = targetRowArr.length;
				for (i = 0; i < rowCount; i++)
					returnArr.push(targetRowArr[i][columnKey]);
				if (!readMulti)
					return rowCount == 0 ? "" : returnArr[0];
				return returnArr;
			}
			return targetRowArr;
		}
		private function readAll(fileName:String):Array
		{
			_db.position = _fileNameDic[fileName];
			return _database[fileName] = _db.readObject();
		}
	}
}
