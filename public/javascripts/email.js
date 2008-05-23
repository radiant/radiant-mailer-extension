// Email.js version 5
var tld_ = new Array()
tld_[0] = "com";
tld_[1] = "org";
tld_[2] = "net";
tld_[3] = "edu";
tld_[4] = "info";
tld_[5] = "mil";
tld_[6] = "gov";
tld_[7] = "biz";
tld_[8] = "ws";
tld_[10] = "co.uk";
tld_[11] = "org.uk";
tld_[12] = "gov.uk";
tld_[13] = "ac.uk";
var topDom_ = 13;
var m_ = "mailto:";
var a_ = "@";
var d_ = ".";

function mail(name, dom, tl, params)
{
	var s = e(name,dom,tl);
	document.write('<a href="'+m_+s+params+'">'+s+'</a>');
}
function mail2(name, dom, tl, params, display)
{
	document.write('<a href="'+m_+e(name,dom,tl)+params+'">'+display+'</a>');
}
function mail3(names, doms, tls, params, display)
{
    var a = "";
    for(var i = 0; i < names.length; i++)
    {
        if(i > 0)
          a += ",";
        a += e(names[i], doms[i], tls[i]);
    }
    document.write('<a href="'+m_+a+params+'">'+display+'</a>');
}
function mail4(name, dom, tl, display)
{
    document.write('<option value="'+e(name,dom,tl)+'">'+display+'</option>');
}
function mail5(ary)
{
   for(var i = 0; i < ary.length; i++)
     mail4(ary[i][0], ary[i][1], ary[i][2], ary[i][3]);
}
function e(name, dom, tl)
{
	var s = name+a_;
	if (tl!=-2)
	{
		s+= dom;
		if (tl>=0)
			s+= d_+tld_[tl];
	}
	else
		s+= swapper(dom);
	return s;
}
function swapper(d)
{
	var s = "";
	for (var i=0; i<d.length; i+=2)
		if (i+1==d.length)
			s+= d.charAt(i)
		else
			s+= d.charAt(i+1)+d.charAt(i);
	return s.replace(/\?/g,'.');
}