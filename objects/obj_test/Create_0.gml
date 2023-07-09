BundleAddFormat("json", function(_buff) {
	var _json = buffer_read(_buff, buffer_text);
	return json_parse(_json);	
});

BundleAddFormat("txt", function(_buff) {
	return buffer_read(_buff, buffer_text);
});

bundle = new Bundle("test.bun");
	if (!file_exists("test.bun")) {
		var _t = get_timer();
		var _str = "Hello World!";
		bundle.Begin();
		bundle.AddFile("test.json");
		var _buff = buffer_load("Untitled.png");
		bundle.AddFile(".bundleinfo\\bunnyloaf.jpg");
		bundle.AddFile("test\\test 2\\test2.json");
		bundle.AddFile("Untitled.png");
		//var _i = 0;
		//repeat(10240) {
		//	//bundle.AddString("hello_world"+string(_i++)+".txt", _str);		
		//	bundle.AddBuffer("Untitled" + string(_i++) + ".png", _buff);
		//}
		bundle.AddString("hello_world.txt", _str);	
		bundle.End();
		show_debug_message("Build time: " + string((get_timer() - _t) / 1000));
		bundle.Save();
		bundle.Unload();
		bundle.Reset();
	}
var _t = get_timer();
bundle.Load();
show_debug_message("Load time (Pre-parsed): " + string((get_timer() - _t) / 1000));

bundle.Unload();
var _t = get_timer();
bundle.Load();
show_debug_message("Load time (Post-parsed): " + string((get_timer() - _t) / 1000));

//var _info = bundle.GetEntryInfo("Into_The_Cosmosv3.zip");
//var _folders = bundle.GetFolderMap();
//show_message(json_stringify(_folders, true));
//var _struct = bundle.LoadFile(_folders.test_json);
//
//show_debug_message(json_stringify(_struct, true));

var _str = bundle.LoadFile("hello_world.txt");
//show_message(date_datetime_string(bundle.__datetime));
show_debug_message("\n\n\n" + json_stringify(bundle.GetEntryInfo("Untitled.png"), true));

show_debug_message(bundle.Crc32Match());