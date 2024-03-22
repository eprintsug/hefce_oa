document.observe("dom:loaded",function(){
	// hefce compliance help
	$$(".hoa_show_description").invoke( "on", "click", function(event) {
		$(Event.element(event)).next(".hoa_test_description").toggleClassName( "hoa_hidden" );
	});
	// hefce tab title
	var status_el = $("hoa_status");
	var title_el = $("hoa_tab_title");
	if( status_el && title_el )
	{   
		var status = status_el.readAttribute( "data-status" );
		title_el.toggleClassName( "hoa_" + status );
	}   
});
