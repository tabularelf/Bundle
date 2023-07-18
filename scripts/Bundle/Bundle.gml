// Config
#macro BUNDLE_CREATE_FILE_MAP true

/// @function Bundle
/// @param {String} filepath to bundle, existing or not.
/// @feather ignore all
function Bundle(_filepath) constructor {
	static _global = __BundleSystem();
	__building = false;
	__filename = _filepath;
	__parsed = false;
	__entriesNewList = undefined;
	__entriesNewMap = undefined;
	__entriesList = undefined;
	__entriesMap = undefined;
	__fileMap = undefined;
	__entriesCount = 0;
	__entriesSize = 0;
	__version = -1;
	__buffer = -1;
	__tempBuffer = -1;
	__asyncID = -1;
	__loaded = false;
	__asyncMode = BundleAsync.NONE;
	__asyncCallback = undefined;
	__timestamp = -1;
	__headerCrc32 = -1;
	__bufferCrc32 = -1;
	__hash = "";
	
	/// @self Bundle
	static Crc32Match = function() {
		if (!__loaded) Load();
		if (!__parsed) __Parse();
		return __headerCrc32 == __bufferCrc32;
	}
	
	/// @self Bundle
	static GetTimestamp = function() {
		return __timestamp;	
	}
	
	/// @self Bundle
	static IsLoaded = function() {
		return __loaded;	
	}
	
	/// @self Bundle
	static SetFilename = function(_filename) {
		if (__filename == _filename) return self;
		__filename = _filename;
		__Reload();
		return self;
	}
	
	/// @self Bundle
	static Unload = function() {
		if (!__loaded) return self;
		
		if (buffer_exists(__buffer)) {
			buffer_delete(__buffer);
			__buffer = -1;
		}
		
		__loaded = false;
	}
	
	/// @self Bundle
	static Load = function(_callback = undefined) {
		if (__loaded) || (__asyncMode != BundleAsync.NONE) return -1;
		if (_callback != undefined) {
			__asyncMode = BundleAsync.LOADING;
			__tempBuffer = buffer_create(1, buffer_grow, 1);
			var _id = buffer_load_async(__tempBuffer, __filename, 0, -1);
			__asyncID = _id;
			__asyncCallback = _callback;	
			array_push(_global.asyncList, self);
		} else {
			var _buff = buffer_load(__filename);
			__HandleLoad(_buff);
		}
	}
	
	static Save = function(_callback = undefined) {
		if (!__loaded) return -1;
		if (_callback != undefined) {
			if ((__asyncMode != BundleAsync.NONE) && (!__loaded)) show_error("Bad!", true);
			
			__asyncMode = BundleAsync.SAVING;
			var _size = buffer_get_size(__buffer);
			__tempBuffer = buffer_create(_size, buffer_fixed, 1);
			buffer_copy(__buffer, 0, _size, __tempBuffer, 0);
			var _id = buffer_save_async(__tempBuffer, __filename, 0, _size);
			__asyncID = _id;
			__asyncCallback = _callback;
			array_push(_global.asyncList, self);
		} else {
			buffer_save(__buffer, __filename);	
		}
	}
	
	static GetFileMap = function() {
		return __fileMap;
	}
	
	static Begin = function() {
		__building = true;
		if (!is_array(__entriesNewList)) __entriesNewList = [];
		if (!is_struct(__entriesNewMap)) __entriesNewMap = {};
		return self;
	}
	
	static AddFile = function(_filename, _compressed = true) {
		var _fileBuffer = buffer_load(_filename);
		AddBuffer(_filename, _fileBuffer, 0, buffer_get_size(_fileBuffer), _compressed);
		buffer_delete(_fileBuffer);
		return self;
	}	
	
	static AddBuffer = function(_filename, _buffer, _offset = 0, _size = buffer_get_size(_buffer), _compressedMain = true) {
		var _compressed = _compressedMain;
		var _hash = buffer_sha1(_buffer, _offset, _size);
		var _newBuffer;
		var _compressedSize = -1; 
		var _uncompressedSize = _size;
		var _crc32 = buffer_crc32(_buffer, _offset, _size);
		var _hash =  buffer_sha1(_buffer, _offset, _size);
		
		if (variable_struct_exists(__entriesNewMap, _filename)) || ((__entriesMap != undefined) && (variable_struct_exists(__entriesMap, _filename))) {
			show_error("File \""+_filename+"\" already exists!", true);	
		}
		
		if (_compressed) {
			_newBuffer = buffer_compress(_buffer, _offset, _size);
			_compressedSize = buffer_get_size(_newBuffer);
			if (buffer_get_size(_newBuffer) >= _size) {
				buffer_delete(_newBuffer);
				_newBuffer = buffer_create(_size, buffer_fixed, 1);
				buffer_copy(_buffer, _offset, _size, _newBuffer, 0);
				_compressedSize = 0;
				_compressed = false;
			}
		} else {
			_newBuffer = buffer_create(_size, buffer_fixed, 1);
			buffer_copy(_buffer, _offset, _size, _newBuffer, 0);
		}
		var _entry = new __BundleEntryClass(_filename, _hash, _crc32, _compressedSize, _uncompressedSize, _compressed, _newBuffer);
		array_push(__entriesNewList, _entry);
		__entriesNewMap[$ _filename] = _entry;
		return self;
	}	
	
	static AddString = function(_filename, _str, _compressed = true) {
		var _size = string_byte_length(_str);
		var _buff = buffer_create(_size, buffer_fixed, 1);
		buffer_write(_buff, buffer_text, _str);
		AddBuffer(_filename, _buff, 0, _size, _compressed);
		buffer_delete(_buff);
		return self;
	}
	
	static LoadFileAsBuffer = function(_file) {
		if (!__parsed) __Parse();
		var _entry = is_struct(_file) ? _file : __entriesMap[$ _file];
		if (_entry == undefined) {
			show_error("File \"" + string(_file) + "\" doesn't exist!", true);	
		}
		var _size = _entry.compressed ? _entry.compressedSize : _entry.uncompressedSize;
		var _buff = buffer_create(_size, buffer_fixed, 1);
		buffer_copy(__buffer, _entry.filePos, _size, _buff, 0);
		if (_entry.compressed) {
			var _dbuff = buffer_decompress(_buff);
			buffer_delete(_buff);
			_buff = _dbuff;
		}
		return _buff;
	}
	
	static LoadFile = function(_file) {
		if (!__parsed) __Parse();
		
		var _name = is_struct(_file) ? _file.filename : _file;
		var _ext = _name;
		_ext = string_lower(filename_ext(_name));
		if (string_pos(".", _ext) == 1) {
			_ext = string_delete(_ext, 1, 1);
		}
		var _buff = LoadFileAsBuffer(_name);
		if (variable_struct_exists(_global.formats, _ext)) {
			var _result = _global.formats[$ _ext].callback(_buff);
			if (_global.formats[$ _ext].autoConsume) {
				buffer_delete(_buff);	
			}
			return _result;
		}
		
		return _buff;
	}
	
	static GetEntryInfo = function(_filename) {
		var _entry = __entriesMap[$ _filename];	
		return {
			fullFilepath: _filename,
			name: filename_name(_filename),
			compressedSize: _entry.compressedSize,
			uncompressedSize: _entry.uncompressedSize,
			compressed: _entry.compressed,
			hash: _entry.hash,
			crc32: _entry.crc32,
			filepath: string_count("/", string_replace_all(_filename, "\\", "/")) > 0 ? filename_path(_filename) : ""
		}
	}
	
	static GetEntryHash = function(_file) {
		return (is_struct(_filename) ? _file.hash : __entriesMap[$ _file].hash);		
	}
	
	static GetEntryCrc32 = function(_file) {
		return (is_struct(_filename) ? _file.crc32 : __entriesMap[$ _file].crc32);			
	}
	
	static GetEntryUncompressedSize = function(_file) {
		return (is_struct(_filename) ? _file.uncompressedSize : __entriesMap[$ _file].uncompressedSize);			
	}
	
	static GetEntryCompressedSize = function(_file) {
		return (is_struct(_filename) ? _file.compressedSize : __entriesMap[$ _file].compressedSize);			
	}
	
	static GetEntryCompressedSize = function(_file) {
		return (is_struct(_filename) ? _file.compressedSize : __entriesMap[$ _file].compressedSize);			
	}
	
	
	static End = function() {
		__building = false;
		__UpdateBundle();
	}
	
	/// @self Bundle
	static __Reload = function() {
		__parsed = false;
		__EntriesMap = undefined;
		__fileMap = undefined;
		
		if (is_array(__entriesList)) array_resize(__entriesList, 0);
		
		if (is_array(__entriesNewList)) {
			var _i = 0;
			repeat(array_length(__entriesNewList)) {
				if (buffer_exists(__entriesNewList[_i].buffer)) {
					buffer_delete(__entriesNewList[_i].buffer);
				}
				++_i;
			}
			array_resize(__entriesNewList, 0)
		}	
	}
	
	static __WriteEntryInfo = function(_buff, _entry, _pos) {
		buffer_write(_buff, buffer_string, _entry.filename);
		buffer_write(_buff, buffer_string, _entry.hash);
		buffer_write(_buff, buffer_u32, _entry.crc32);
		buffer_write(_buff, buffer_u32, _entry.compressedSize);
		buffer_write(_buff, buffer_u32, _entry.uncompressedSize);
		buffer_write(_buff, buffer_u32, _pos); // Current position of databuff
		buffer_write(_buff, buffer_bool, _entry.compressed);	
	}
	
	static __UpdateBundle = function() {
		// Check if any files were added!
		if (array_length(__entriesNewList) == 0) return; 
		var _entriesCount = __entriesCount + array_length(__entriesNewList);
		
		if (!buffer_exists(__buffer)) {
			var _dataBuff = buffer_create(1, buffer_grow, 1);
			buffer_write(_dataBuff, buffer_string, __BUNDLE_HEADER);
			var _dataBuffPos = buffer_tell(_dataBuff);
			var _entriesBuff = buffer_create(1, buffer_grow, 1);
		} else {
			var _size = buffer_get_size(__buffer)-__entriesSize-9;
			var _dataBuff = buffer_create(_size, buffer_grow, 1);
			buffer_copy(__buffer, 0, _size, _dataBuff, 0);
			var _dataBuffPos = _size;
			var _entriesBuff = buffer_create(__entriesSize, buffer_grow, 1);
			buffer_copy(__buffer, _size, __entriesSize, _entriesBuff, 0);
			buffer_seek(_entriesBuff, buffer_seek_end, 0);
		}
		
		var _timestamp = date_current_datetime();
		var _t = get_timer();
		var _i = 0;
		repeat(array_length(__entriesNewList)) {
			var _entry = __entriesNewList[_i];
			
			__WriteEntryInfo(_entriesBuff, _entry, _dataBuffPos);
			var _size = buffer_get_size(_entry.buffer);
			buffer_copy(_entry.buffer, 0, _size, _dataBuff, _dataBuffPos);
			buffer_delete(_entry.buffer);
			_dataBuffPos += _size+1;
			
			++_i;
		}
		
					
		var _entriesSize = buffer_tell(_entriesBuff);
		buffer_copy(_entriesBuff, 0, _entriesSize, _dataBuff, _dataBuffPos);
		var _size = buffer_get_size(_dataBuff);
		buffer_seek(_dataBuff, buffer_seek_end, 0);
		buffer_write(_dataBuff, buffer_u8, __BUNDLE_VERSION);
		buffer_write(_dataBuff, buffer_u32, _entriesSize);
		buffer_write(_dataBuff, buffer_u32, _entriesCount);
		var _datetime = date_current_datetime();
		buffer_write(_dataBuff, buffer_f64, _datetime);
		buffer_resize(_dataBuff, buffer_tell(_dataBuff));
		var _crc32 = buffer_crc32(_dataBuff, 0, buffer_get_size(_dataBuff));
		buffer_seek(_dataBuff, buffer_seek_end, 0);
		buffer_write(_dataBuff, buffer_u32, _crc32);
		buffer_resize(_dataBuff, buffer_tell(_dataBuff));
		buffer_delete(_entriesBuff);
		buffer_delete(__buffer);
		buffer_seek(_dataBuff, buffer_seek_start, 0);
		__Reload();
		__buffer = _dataBuff;
		
		__entriesCount = _entriesCount;
		__entriesSize = _entriesSize;
		__parsed = false;
		show_debug_message("Time taken to build: " + string((get_timer() - _t) / 1000) + "ms (" + string_format(date_second_span(_timestamp, date_current_datetime()), 0, 0) + " seconds!)");
	}
	
	static __HandleLoad = function(_buffer) {
		__buffer = _buffer;
		__loaded = true;
		__Parse();
	}
	
	static __Parse = function() {
		var _hash = buffer_sha1(__buffer, 0, buffer_get_size(__buffer));
		if (__parsed) && (__hash == _hash) return;
		if (__entriesList == undefined) __entriesList = [];
		if (__entriesMap == undefined) __entriesMap = {};
		if (BUNDLE_CREATE_FILE_MAP) && (__fileMap = undefined) __fileMap = {};
		__hash = _hash;
		
		buffer_seek(__buffer, buffer_seek_start, 0);
		var _header = buffer_read(__buffer, buffer_string);
		if (_header != __BUNDLE_HEADER) show_error("Invalid header!", true);
		
		buffer_seek(__buffer, buffer_seek_end, 21);
		__version = buffer_read(__buffer, buffer_u8);
		__entriesSize = buffer_read(__buffer, buffer_u32);
		__entriesCount = buffer_read(__buffer, buffer_u32);
		__timestamp = buffer_read(__buffer, buffer_f64);
		__headerCrc32 = buffer_read(__buffer, buffer_u32);
		__bufferCrc32 = buffer_crc32(__buffer, 0, buffer_get_size(__buffer)-4);
		buffer_seek(__buffer, buffer_seek_end, 21+__entriesSize);
		var _i = 0;
		repeat(__entriesCount) {
			var _name = buffer_read(__buffer, buffer_string);
			var _hash = buffer_read(__buffer, buffer_string);
			var _crc32 = buffer_read(__buffer, buffer_u32);
			var _compressedSize = buffer_read(__buffer, buffer_u32);
			var _uncompressedSize = buffer_read(__buffer, buffer_u32);
			var _filePos = buffer_read(__buffer, buffer_u32);
			var _isCompressed = buffer_read(__buffer, buffer_bool);
			var _entry = new __BundleEntryClass(_name, _hash, _crc32, _compressedSize, _uncompressedSize, _isCompressed);
			_entry.pos = _i;
			_entry.filePos = _filePos;
			array_push(__entriesList, _entry);
			__entriesMap[$ _name] = _entry;
			// Early rejection
			if (BUNDLE_CREATE_FILE_MAP) && (string_copy(_name, 1, 11) != ".bundleinfo") {
			var _filepath = _name;//string_replace_all(string_replace_all(_name, ".", "_"), " ", "_");
				// Replace backslashes with forward slashes for paths
				var _path = string_replace_all(_name, "\\", "/");
				var _slashCount = string_count("/", _path);
				if (_slashCount > 0) {
					var _ii = 0;
					var _pos = 1;
					var _lastPos = string_pos("/", _path);
					var _currentFolder = __fileMap;
					repeat(_slashCount) {
						var _folder = string_copy(_path, _pos, _lastPos-_pos);
						if (!variable_struct_exists(_currentFolder, _folder)) {
							_currentFolder[$ _folder] = {}; 
						}
						// Enter inside folder
						_currentFolder = _currentFolder[$ _folder];
						_pos = string_pos_ext("/", _path, _pos+1)+1;
						_lastPos = string_pos_ext("/", _path, _pos+1);
						++_ii;
					}
					_currentFolder[$ filename_name(_filepath)] = _entry;
				} else {
					__fileMap[$ filename_name(_filepath)] = _entry;
				}
					++_i;
			}
		}
		__parsed = true;
	}
		
	static __HandleAsync = function(_id) {
		if (_id == __asyncID) {
			var _result = false;
			if (__asyncMode == BundleAsync.LOADING) {
				if (async_load[? "status"]) {
					__buffer = __tempBuffer;
					__loaded = true;
					__Parse();
					_result = true;
				} else {
					buffer_delete(__tempBuffer);	
					__loaded = false;
				}
				
				__asyncMode = BundleAsync.NONE;
				__tempBuffer = -1;
				__asyncID = -1;
			} else if (__asyncMode == BundleAsync.SAVING) {
				if (!async_load[? "status"]) {
					_result = true;
				}
				
				__asyncMode = BundleAsync.NONE;
				buffer_delete(__tempBuffer);
				__tempBuffer = -1;
				__asyncID = -1;
			}
			
			if (_result) && (__asyncCallback != undefined) {
				__asyncCallback();
				__asyncCallback = undefined;	
			}
			return true;
		}
		return false;
	}
}