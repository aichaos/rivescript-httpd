#!/usr/bin/python

from __future__ import print_function
import os
import glob
import re

# Get the file list.
files = list()
for item in glob.glob(os.path.join('public_html', 'brain', '*.rive')):
    item = item.replace('\\', '/')
    files.append(item.split("/")[-1])

# Format them for the JS.
filelist = map(lambda x: "\t'%s'," % x, files)

# Remove the last comma.
filelist[-1] = re.sub(r',$', '', filelist[-1])

# Generate the JS.
js = """/* This file was automatically generated. You shouldn't
 * need to edit this file by hand. If you need to add files
 * to this list, instead run the "Refresh the File List"
 * command in the RiveScript::HTTPd index page. */

var rs_filelist = [
%s
];
""" % "\n".join(filelist)

fh = open(os.path.join('public_html', 'js', 'brain.js'), 'w')
fh.write(js)

print("""Content-Type: text/html

<!DOCTYPE html>
<html>
<head>
<title>Refresh the File List</title>
<link rel="stylesheet" type="text/css" href="/css/rs-httpd.css">
</head>
<body>

<div id="header">Refresh the File List</div>

<div id="content">
	<h1>File list refreshed!</h1>

	The file <code>public_html/js/brain.js</code> has been regenerated based
	on the files in the <code>public_html/brain</code> directory.<p>

	<a href="/">Return to the main page</a>
</div>

</body>
</html>""")
