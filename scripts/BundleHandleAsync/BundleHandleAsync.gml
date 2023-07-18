// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function BundleHandleAsync() {
	static _global = __BundleSystem();
	var _id = async_load[? "id"];
	var _i = 0;
	repeat(array_length(_global.asyncList)) {
		if (_global.asyncList[_i].__HandleAsync(_id)) {
			array_delete(_global.asyncList, _i, 1);
			break;
		}
		++_i;
	}
}