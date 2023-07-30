/// @feather ignore all
/// @ignore
function __BundleEntryClass(_filename, _hash, _crc32, _cbuffSize, _buffSize, _compressed, _buff = -1) constructor {
	filename = _filename;
	hash = _hash;
	crc32 = _crc32;
	buffer = _buff;
	compressedSize = _cbuffSize;
	uncompressedSize = _buffSize;
	compressed = _compressed;
	pos = -1;
	filePos = -1;
	entrySize = 0;
	entryPos = 0;
}	