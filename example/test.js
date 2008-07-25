if(confirm('hello')) { 
  this.create_form(); 
}
else {
  dlg.onclick = function (){ __obj.create_form(); }
}

if(confirm("blah")) do_it;
