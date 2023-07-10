/// @feather ignore all
/// @ignore
function __BundleEntryClass(_name, _crc32, _cbuffSize, _buffSize, _compressed, _buff = -1) constructor {
	__name = _name;
	__crc32 = _crc32;
	__buffer = _buff;
	__compressedSize = _cbuffSize;
	__uncompressedSize = _buffSize;
	__compressed = _compressed;
	__pos = -1;
	__filePos = -1;
}	