BundleAddFormat("json", function(_buff) {
	var _json = buffer_read(_buff, buffer_text);
	return json_parse(_json);	
});

bundle = new Bundle("test.bun");
	if (!file_exists("test.bun")) {
		var _str = "Hello World!";
		bundle.Begin();
		bundle.AddFile("test.json");
		bundle.AddFile(".bundleinfo\\bunnyloaf.jpg");
		bundle.AddFile("test\\test 2\\test2.json");
		bundle.AddString("hello_world.txt", _str);	
		bundle.End();
		bundle.Save();
		bundle.Unload();
		bundle.Reset();
	}
var _t = get_timer();
bundle.Load();
show_debug_message((get_timer() - _t) / 1000);

bundle.Unload();
var _t = get_timer();
bundle.Load();
show_debug_message((get_timer() - _t) / 1000);

//var _info = bundle.GetEntryInfo("Into_The_Cosmosv3.zip");
//var _folders = bundle.GetFolderMap();
//show_message(json_stringify(_folders, true));
//var _struct = bundle.LoadFile(_folders.test_json);
//
//show_debug_message(json_stringify(_struct, true));

//var _struct = bundle.LoadFile("test2.json");

//show_debug_message(json_stringify(_struct, true));