function addProgram() {
    var name = prompt("[% loc('Bitte geben Sie den Programmnamen ein.') %]");
    var programs = document.getElementById("programs");
    for (var i=0,row;row=programs.rows[i];i++) {
		cell = row.cells[1];
		input = cell.childNodes[0];
		if( input != null && (input.name == name || input.value == name)) {
			alert("[% loc('Der Programmname existiert bereits!') %]");
			name = null;
		}
	}

    if (name != null) {
        var row = programs.insertRow();
        row.className = "even";
        var cell1 = row.insertCell(0);
        var input = document.createElement("input");
        input.name=name + "_name";
        input.value=name;
        cell1.appendChild(input);
        var cell2 = row.insertCell(1);
        var addbtn = document.createElement("input");
        addbtn.type = "button";
        addbtn.name = name;
        addbtn.onclick = function(e){addPath(this);};
        addbtn.value = "[% loc('+ Pfad') %]";
        cell2.appendChild(addbtn);
        row.insertCell(2);
        var cell3 = row.insertCell(2);
        var delbtn = document.createElement("input");
        delbtn.type = "button";
        delbtn.name = name;
        delbtn.value = "[% loc('- Programm') %]";
        delbtn.onclick = function(e){deleteProgram(this);};
        cell3.appendChild(delbtn);
    }
}

function deleteProgram(p) {
	var programs = document.getElementById("programs");
	for (var i=programs.rows.length-1,row;row=programs.rows[i];i--) {
		var input = row.cells[2].childNodes[0];
		if( input != null && input.name == p.name) {
			programs.deleteRow(i);
		}
	}
}

function addPath(p) {
	var programs = document.getElementById("programs");
	var current = p.closest('tr');
	
	var row = programs.insertRow(current.rowIndex+1);
	row.className = "odd";
	row.insertCell(0);
	var cell1 = row.insertCell(1);
	var input = document.createElement("input");
	input.type = "text";
	input.name = p.name+"_value";
	input.value = "";
	cell1.appendChild(input);
	var cell2 = row.insertCell(2);
	var delbtn = document.createElement("input");
	delbtn.name = p.name;
	delbtn.type = "button";
	delbtn.value= "[% loc('- Pfad') %]";
	delbtn.onclick=function(e){deletePath(this);};
	cell2.appendChild(delbtn);
}

function deletePath(p) {
	p.closest('tr').remove();
}
