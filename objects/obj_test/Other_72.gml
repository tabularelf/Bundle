var _t = get_timer();
BundleHandleAsync();
show_debug_message("Load time (Pre-parsed): " + string((get_timer() - _t) / 1000));