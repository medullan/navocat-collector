$(document).ready(function() {
	// Menu collapse logic
	var dupe = $('nav ul').clone().addClass('fixie').appendTo('body');
	$('#about').waypoint(function(direction) {
		if (direction == 'down') dupe.addClass('collapsed')
			else dupe.removeClass('collapsed');
	}, { offset: 2 });
	$('#about').waypoint(function(direction) {
		if (direction == 'down') dupe.show()
			else dupe.hide();
	}, { offset: 100 });

	// Activate breadcrumb
	$('section').waypoint(function(direction) {
		var section = direction == 'down' ? $(this).attr('id') : $(this).prev().attr('id');
		$('ul.fixie li a.active').removeClass('active');
		$('ul.fixie li a[href="#'+section+'"]').addClass('active');
	}, { offset: 150 });

	$('a[href*=#]:not([href=#])').click(function() {
		if (location.pathname.replace(/^\//,'') == this.pathname.replace(/^\//,'') && location.hostname == this.hostname) {
			var target = $(this.hash);
			target = target.length ? target : $('[name=' + this.hash.slice(1) +']');
			if (target.length) {
				$('html,body').animate({
					scrollTop: target.offset().top
				}, 666);
				return false;
			}
		}
	});
});
