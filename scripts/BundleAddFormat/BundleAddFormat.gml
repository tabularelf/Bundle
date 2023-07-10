/// @desc Function Description
/// @param {string} ext File extension
/// @param {Function} callback Function to run when loading in an extension with .LoadFile. Passes in buffer.
/// @param {bool} [autoConsume]=true Whether to free the buffer or not automatically.
/// @feather ignore all
function BundleAddFormat(_ext, _callback, _autoConsume = true) {
	static _global = __BundleSystem();	
	_global.formats[$ string_lower(_ext)] = {
		autoConsume: _autoConsume,
		callback: _callback
	};
}