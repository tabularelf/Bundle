/// @feather ignore all
/// @ignore

#macro __BUNDLE_VERSION 0
#macro __BUNDLE_HEADER "BUN"
enum BundleAsync {
	NONE,
	LOADING,
	SAVING
}

function __BundleSystem() {
	static _inst = {
		formats: {},
		asyncList: []
	}
	
	return _inst;
}

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣤⣤⡄⢠⣤⣤⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡟⢦⡀⠛⣿⠁⠀⢹⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢻⡆⠓⡆⠛⣶⠀⠀⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢹⡆⠓⡄⢹⡆⠀⠉⣷⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⡇⢹⠈⢹⡇⠀⡿⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⡀⠈⣿⣀⣹⠀⠙⠛⠃⠘⠛⢣⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⣰⠶⠞⠛⠛⠛⠛⠳⠶⣆⡿⠀⠀⠀⠀⢀⣀⣤⠀⠙⣷⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⣤⠾⠉⠀⠀⠀⠀⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀⠉⠉⠉⠉⠀⣉⣷⠀⠀⠀
// ⠀⢸⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⣿⠀⠀
// ⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣤⣤⡟⠛⠀⠀⠀
// ⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠸⢧⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀
// ⠀⠺⣧⡀⢠⣀⠀⠀⣀⣟⠛⠛⣧⣄⡀⠀⠀⣸⡇⠀⣿⠉⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠀⠀⠀⠀⠀⠀⠀⠀