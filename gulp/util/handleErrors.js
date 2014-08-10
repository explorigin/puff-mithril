var notify = require("gulp-notify");

module.exports = function() {

    console.log(Object.keys(arguments[0]));
	var args = Array.prototype.slice.call(arguments);

	// Send error to notification center with gulp-notify
	notify.onError({
		title: "Compile Error",
		message: "<%= error.message %>\n<%= error.annotated %> - on line:<%= error.line %> column:<%= error.column %>"
	}).apply(this, args);

	// Keep gulp from hanging on this task
	this.emit('end');
};
