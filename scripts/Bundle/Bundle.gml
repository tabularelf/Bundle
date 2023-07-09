#macro __BUNDLE_VERSION 0
#macro __BUNDLE_HEADER "BUN"

function Bundle(_filepath) constructor {
	static _global = __BundleSystem();
	__building = false;
	__filename = _filepath;
	__parsed = false;
	__entriesNewList = undefined;
	__entriesList = undefined;
	__entriesMap = undefined;
	__folderMap = undefined;
	__entriesCount = 0;
	__entriesSize = 0;
	__version = -1;
	__buffer = -1;
	__loaded = false;
	
	static SetFilename = function(_filename) {
		if (__filename == _filename) return self;
		__filename = _filename;
		Reset();
		return self;
	}
	
	static Unload = function() {
		if (!__loaded) return self;
		
		if (buffer_exists(__buffer)) {
			buffer_delete(__buffer);
			__buffer = -1;
		}
		
		__loaded = false;
		
		return self;
	}
	
	static Reset = function() {
		__parsed = false;
		__EntriesMap = undefined;
		__folderMap = undefined;
		
		if (is_array(__entriesList)) array_resize(__entriesList, 0);
		
		if (is_array(__entriesNewList)) {
			var _i = 0;
			repeat(array_length(__entriesNewList)) {
				if (buffer_exists(__entriesNewList[_i].__buffer)) {
					buffer_delete(__entriesNewList[_i].__buffer);
				}
				++_i;
			}
			array_resize(__entriesNewList, 0)
		}	
	}
		
	static Load = function() {
		var _buff = buffer_load(__filename);
		__HandleLoad(_buff);
		return self;
	}
	
	static LoadAsync = function() {
		
		return self;
	}
	
	static Save = function() {
		buffer_save(__buffer, __filename);
	}
	
	static SaveAsync = function() {
		
	}
	
	
	static GetFolderMap = function() {
		return __folderMap;	
	}
	
	static Begin = function() {
		__building = true;
		if (!is_array(__entriesNewList)) __entriesNewList = [];
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
		var _compressedSize = 0; 
		var _uncompressedSize = _size;
		
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
		var _entry = new __BundleEntry(_filename, _hash, _compressedSize, _uncompressedSize, _compressed, _newBuffer);
		array_push(__entriesNewList, _entry);
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
	
	static GetFileAsBuffer = function(_filename) {
		if (!__parsed) __Parse();
		var _name = is_struct(_filename) ? _filename.filepath + _filename.name : _filename;
		var _entry = __entriesMap[$ _name];
		var _size = _entry.__compressed ? _entry.__compressedSize : _entry.__uncompressedSize;
		var _buff = buffer_create(_size, buffer_fixed, 1);
		buffer_copy(__buffer, _entry.__filePos, _size, _buff, 0);
		if (_entry.__compressed) {
			var _dbuff = buffer_decompress(_buff);
			buffer_delete(_buff);
			_buff = _dbuff;
		}
		return _buff;
	}
	
	static LoadFile = function(_filename) {
		if (!__parsed) __Parse();
		
		var _name = is_struct(_filename) ? _filename.filepath + _filename.name : _filename;
		var _ext = _name;
		_ext = string_lower(filename_ext(_name));
		if (string_pos(".", _ext) == 1) {
			_ext = string_delete(_ext, 1, 1);
		}
		var _buff = GetFileAsBuffer(_name);
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
			name: filename_name(_filename),
			compressedSize: _entry.__compressedSize,
			uncompressedSize: _entry.__uncompressedSize,
			compressed: _entry.__compressed,
			hash: _entry.__hash,
			filepath: string_count("/", string_replace_all(_filename, "\\", "/")) > 0 ? filename_path(_filename) : ""
		}
	}
	
	static GetEntryHash = function(_filename) {
		return __entriesMap[$ _filename].__hash;		
	}
	
	
	static End = function() {
		__building = false;
		__UpdateBundle();
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
			
			var _i = 0;
			repeat(array_length(__entriesNewList)) {
				var _entry = __entriesNewList[_i];
				
				buffer_write(_entriesBuff, buffer_string, _entry.__name);
				buffer_write(_entriesBuff, buffer_string, _entry.__hash);
				buffer_write(_entriesBuff, buffer_u32, _entry.__compressedSize);
				buffer_write(_entriesBuff, buffer_u32, _entry.__uncompressedSize);
				buffer_write(_entriesBuff, buffer_u32, _dataBuffPos); // Current position of databuff
				buffer_write(_entriesBuff, buffer_bool, _entry.__compressed);
				var _size = buffer_get_size(_entry.__buffer);
				buffer_copy(_entry.__buffer, 0, _size, _dataBuff, _dataBuffPos);
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
			buffer_resize(_dataBuff, buffer_tell(_dataBuff));
			buffer_delete(_entriesBuff);
			__buffer = _dataBuff;
		} else {
			var _size = buffer_get_size(__buffer)-__entriesSize-9;
			var _dataBuff = buffer_create(_size, buffer_grow, 1);
			buffer_copy(__buffer, 0, _size, _dataBuff, 0);
			var _dataBuffPos = _size;
			var _entriesBuff = buffer_create(__entriesSize, buffer_grow, 1);
			buffer_copy(__buffer, _size, __entriesSize, _entriesBuff, 0);
			buffer_seek(_entriesBuff, buffer_seek_end, 0);
			
			var _i = 0;
			repeat(array_length(__entriesNewList)) {
				var _entry = __entriesNewList[_i];
				
				buffer_write(_entriesBuff, buffer_string, _entry.__name);
				buffer_write(_entriesBuff, buffer_string, _entry.__hash);
				buffer_write(_entriesBuff, buffer_u32, _entry.__compressedSize);
				buffer_write(_entriesBuff, buffer_u32, _entry.__uncompressedSize);
				buffer_write(_entriesBuff, buffer_u32, _dataBuffPos); // Current position of databuff
				buffer_write(_entriesBuff, buffer_bool, _entry.__compressed);
				var _size = buffer_get_size(_entry.__buffer);
				buffer_copy(_entry.__buffer, 0, _size, _dataBuff, _dataBuffPos);
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
			buffer_resize(_dataBuff, buffer_tell(_dataBuff));
			buffer_delete(_entriesBuff);
			buffer_delete(__buffer);
			Reset();
			__buffer = _dataBuff;
		}
		__entriesCount = _entriesCount;
		__entriesSize = _entriesSize;
		__parsed = false;
	}
	
	static __HandleLoad = function(_buffer) {
		__buffer = _buffer;
		__loaded = true;
		__Parse();
	}
	
	static __Parse = function() {
		if (__parsed) return;
		if (__entriesList == undefined) __entriesList = [];
		if (__entriesMap == undefined) __entriesMap = {};
		if (__folderMap == undefined) __folderMap = {};
		
		buffer_seek(__buffer, buffer_seek_start, 0);
		var _header = buffer_read(__buffer, buffer_string);
		if (_header != __BUNDLE_HEADER) show_error("Invalid header!", true);
		
		buffer_seek(__buffer, buffer_seek_end, 9);
		__version = buffer_read(__buffer, buffer_u8);
		__entriesSize = buffer_read(__buffer, buffer_u32);
		__entriesCount = buffer_read(__buffer, buffer_u32);
		buffer_seek(__buffer, buffer_seek_end, 9+__entriesSize);
		var _i = 0;
		repeat(__entriesCount) {
			var _name = buffer_read(__buffer, buffer_string);
			var _hash = buffer_read(__buffer, buffer_string);
			var _compressedSize = buffer_read(__buffer, buffer_u32);
			var _uncompressedSize = buffer_read(__buffer, buffer_u32);
			var _filePos = buffer_read(__buffer, buffer_u32);
			var _isCompressed = buffer_read(__buffer, buffer_bool);
			var _entry = new __BundleEntry(_name, _hash, _compressedSize, _uncompressedSize, _isCompressed);
			_entry.__pos = _i;
			_entry.__filePos = _filePos;
			array_push(__entriesList, _entry);
			__entriesMap[$ _name] = _entry;
			// Early rejection
			if (string_copy(_name, 1, 11) != ".bundleinfo") {
			// Replace backslashes with forward slashes for paths
			var _path = string_replace_all(_name, "\\", "/");
			var _slashCount = string_count("/", _path);
			if (_slashCount > 0) {
				var _ii = 0;
				var _pos = 1;
				var _lastPos = string_pos("/", _path);
				var _currentFolder = __folderMap;
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
					_currentFolder[$ string_replace_all(filename_name(_name), ".", "_")] = GetEntryInfo(_name);
				} else {
					__folderMap[$ string_replace_all(filename_name(_name), ".", "_")] = GetEntryInfo(_name);
				}
				++_i;
			}
		}
		__parsed = true;
	}
}

function BundleAddFormat(_ext, _callback, _autoConsume = true) {
	static _global = __BundleSystem();	
	_global.formats[$ string_lower(_ext)] = {
		autoConsume: _autoConsume,
		callback: _callback
	};
}

function __BundleSystem() {
	static _inst = {
		bundles: [],
		formats: {}
	}
	
	return _inst;
}

function __BundleEntry(_name, _hash, _cbuffSize, _buffSize, _compressed, _buff = -1) constructor {
	__name = _name;
	__hash = _hash;
	__buffer = _buff;
	__compressedSize = _cbuffSize;
	__uncompressedSize = _buffSize;
	__compressed = _compressed;
	__pos = -1;
	__filePos = -1;
}	