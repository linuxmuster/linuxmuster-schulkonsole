var timer = 1801;



window.onload = function()
{
    var element = document.getElementById("timer");
    if (element && element.firstChild) {
        timer = max_idle_time(element.firstChild.nodeValue);
    }

    window.setTimeout(info_off, 2000);
    
    timer_step();

    if (! window.location.hash) {
        var elements = document.getElementsByTagName("input");
        if (elements) {
            elements[0].focus();
        }
    }
}



function max_idle_time(hh_mm_ss)
{
    var h_m_s = hh_mm_ss.split(":");
    var h = h_m_s[0] * 1;
    var m = h_m_s[1] * 1;
    var s = h_m_s[2] * 1;


    return ((h * 60) + m * 1) * 60 + s + 1;
}



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
            && command_name(form[i].name) == command && !form[i].disabled) {
            form[i].checked = checked;
        }
    }
}

function toggle_visibility(id)
{
    var e = document.getElementById(id);
    if(e.style.display == 'block')
          e.style.display = 'none';
    else
          e.style.display = 'block';
}

function info_on()
{
    var e = document.getElementById('info');
    var b = document.getElementById('block-info-link');
    var ein = document.getElementById('info-einblenden');
    var aus = document.getElementById('info-ausblenden');
    e.style.display = 'block';
    b.style.right = '248px';
    ein.style.display = 'none';
    aus.style.display = 'block';
}

function info_off()
{
    var e = document.getElementById('info');
    var b = document.getElementById('block-info-link');
    var ein = document.getElementById('info-einblenden');
    var aus = document.getElementById('info-ausblenden');
    e.style.display = 'none';
    b.style.right = '0px';
    ein.style.display = 'block';
    aus.style.display = 'none';
}
