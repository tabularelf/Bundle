BundleAddFormat("json", function(_buff) {
	var _json = buffer_read(_buff, buffer_text);
	return json_parse(_json);	
});

BundleAddFormat("txt", function(_buff) {
	return buffer_read(_buff, buffer_text);
});

loopTest = function() {
		bundle.Unload();
		bundle.LoadAsync(loopTest);	
	};

var _buff = buffer_load("Untitled.png");

bundle = new Bundle("test.bun");
	if (!file_exists("test.bun")) {
		var _t = get_timer();
		var _str = "Hello World!";
		bundle.Begin();
		bundle.AddFile("test.json");
		bundle.AddFile(".bundleinfo\\bunnyloaf.jpg");
		bundle.AddFile("test\\test 2\\test2.json");
		bundle.AddFile("Untitled.png");
		bundle.AddString("hello_world.txt", _str);		
		//var _i = 0;
		//repeat(1024) {
		//	bundle.AddString("hello_world.txt" + string(_i++), _str);		
		//}
		bundle.End();
		show_debug_message("Build time: " + string((get_timer() - _t) / 1000));
		bundle.Save();
		bundle.Unload();
	}
var _t = get_timer();
//bundle.LoadAsync(function() {
//	var _str = bundle.LoadFile("hello_world.txt");
//	//show_message(date_datetime_string(bundle.__datetime));
//	show_debug_message("\n\n\n" + json_stringify(bundle.GetEntryInfo("Untitled.png"), true));
//	
//	show_debug_message(bundle.Crc32Match());
//	
//	bundle.Unload();
//	bundle.LoadAsync(loopTest);
//});
bundle.Load();
show_debug_message("Load time (Pre-parsed): " + string((get_timer() - _t) / 1000));
repeat(10) {
	bundle.Unload();
	var _t = get_timer();
	bundle.Load();
	show_debug_message("Load time (Post-parsed): " + string((get_timer() - _t) / 1000));
}
var _json = json_stringify (bundle.GetFolderMap(), true);
show_debug_message(_json +"\n\n\n");
show_debug_message(json_stringify(bundle.LoadFile(bundle.GetFolderMap().test_json), true));

//var _str = bundle.LoadFile("hello_world.txt");
////show_message(date_datetime_string(bundle.__datetime));
//show_debug_message("\n\n\n" + json_stringify(bundle.GetEntryInfo("Untitled.png"), true));
//
//show_debug_message(bundle.Crc32Match());