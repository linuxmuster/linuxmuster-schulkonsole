var timer = 1801;

function timer_step() {
	timer -= 1;

	if (timer > 0) {
		var sec = timer;
		var hours = (sec / 3600) - 0.5;
		hours = hours < 0 ? 0 : hours.toFixed(0);
		sec -= hours * 3600;
		var min = sec / 60 - 0.5;
		min = min < 0 ? 0 : min.toFixed(0);
		sec -= min * 60;
		sec = sec.toFixed(0);


		var element = document.getElementById("timer");
		if (element && element.firstChild) {
			element.firstChild.nodeValue =
			    hours + ":"
			  + (min < 10 ? "0" : "") + min + ":"
			  + (sec < 10 ? "0" : "") + sec;

			window.setTimeout("timer_step()", 1000);
		}
	} else {
		var element = document.getElementById("timer");
		if (element && element.firstChild) {
			element.firstChild.nodeValue = "0:00:00";
		}
	}
}



function command_name(name)
{
	var i = name.indexOf(';');
	if (i != -1) {
		return name.substr(i + 1);
	}

	return "";
}


function check_uncheck(command_button)
{
	var form = command_button.form;
	var command = command_button.name;
	var checked = 1;

	if (command_button.value == "Aus") {
		checked = 0;
		command_button.value = "An";
	} else {
		command_button.value = "Aus";
	}

	for (var i = 0; i < form.length; i++) {
		if (   form[i].type == 'checkbox'
		    && command_name(form[i].name) == command) {
			form[i].checked = checked;
		}
	}
}

