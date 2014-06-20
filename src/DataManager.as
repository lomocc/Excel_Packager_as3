package general.managers
{
	import flash.utils.ByteArray;
	
	import general.utils.HashMap;
	import general.utils.Injector;
	import general.utils.formatString;
	
	public class DataManager
	{
		public function DataManager()
		{

		}
		/**
		 * 语言/切换文件
		 */		
		private var _localeData:Object;
		
		/**
		 * 数据库的目录
		 */		
		private var _dataMap:Object;
		/**
		 * 数据库的实际内容
		 */		
		private var _bytesContent:ByteArray = new ByteArray();
		/**
		 * 缓存数据库
		 */		
		private var _dataCache:HashMap = new HashMap();
		/**
		 * 初始化数据库
		 * @param bytes
		 */
		public function init(bytes:ByteArray):void
		{
			bytes.uncompress();
			_dataMap = bytes.readObject();
			bytes.readBytes(_bytesContent);
			bytes.clear();
		}
		/**
		 * 读取数据库
		 * @param fileName 数据库名（excel文件名）
		 * @param needCache 是否需要缓存
		 * @return 数据列表
		 */				
		public function readContent(fileName:String, needCache:Boolean=true):Array
		{
			var result:* = _dataCache.get(fileName);
			if(!result && _dataMap)
			{
				_bytesContent.position = _dataMap[fileName];
				result = _bytesContent.readObject();
				_dataCache.put(fileName, result);//缓存数据
			}
			return result;
		}
		/**
		 * 清空缓存 不影响真实数据 适合一些暂时不再使用的数据
		 * @param fileName 要清空的数据库文件 默认为null 将会清空所有缓存
		 * @return 
		 */		
		public function clearCache(fileName:String=null):Array
		{
			var result:* = _dataCache.get(fileName);
			if(!result)
			{
				_bytesContent.position = _dataMap[fileName];
				result = _bytesContent.readObject();
				_dataCache.put(fileName, result);//缓存数据
			}
			return result;
		}
		/**
		 * 读取matchKey=matchValue的对象,如果找不到那么返回null
		 * @param fileName 要读取的文件名
		 * @param matchKey 要查找的键名
		 * @param matchValue matchKey对应的值
		 * @param readMulti 是否读取多条数据 默认为false，如果为true 则可能会返回一个数组
		 * @return 如果readMulti为true 返回结果是一个数组或者null<br>如果readMulti为false（默认），返回结果是一个对象或null
		 */
		public function readObject(fileName:String, matchKey:String, matchValue:*, readMulti:Boolean=false):*
		{
			var result:Array;
			var length:int;
			for each (var item:Object in readContent(fileName)) 
			{
				if (item[matchKey] == matchValue)
				{
					if(readMulti)
					{
						if(!result)
							result = [];
						result[length++] = item;
					}else
						return item;
				}
			}
			return result;
		}
		/**
		 * 读取matchKey=matchValue的对象的columnKey属性值
		 * @param fileName 要读取的文件名
		 * @param matchKey 要查找的键名
		 * @param matchValue matchKey对应的值
		 * @param columnKey 要获取找到的对象的哪个键的值？
		 * @return 满足条件的值为String类型
		 * @see #readInt() readInt
		 * @see #readNumber() readNumber
		 */
		public function readProperty(fileName:String, matchKey:String, matchValue:*, columnKey:String):String
		{
			var item:Object = readObject(fileName, matchKey, matchValue);
			return item[columnKey];
		}
		/**
		 * 读取转为int类型
		 * @see #readProperty() readProperty
		 */		
		public function readInt(fileName:String, matchKey:String, matchValue:*, columnKey:String):int
		{
			return int(readProperty(fileName, matchKey, matchValue, columnKey));
		}
		/**
		 * 读取转为Number类型
		 * @see #readProperty() readProperty
		 */	
		public function readNumber(fileName:String, matchKey:*, matchValue:*, columnKey:String):Number
		{
			return parseFloat(readProperty(fileName, matchKey, matchValue, columnKey)) || 0;
		}
		/**
		 * 获取经过翻译的文字内容
		 * @param key 要翻译的文字
		 * @param parameters 需要替代 {0}，{1},{2}格式的参数
		 * @return 
		 */		
		public function getString(key:String,
								  ...parameters):String
		{
			if(_localeData.hasOwnProperty(key))
			{
				var value:String = _localeData[key];
				return formatString(value, parameters);
			}
			return formatString(value, parameters);
		}
		public static function getInstance():DataManager
		{
			return Injector.getInstance(DataManager);
		}
	}
}
