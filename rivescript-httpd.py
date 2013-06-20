#!/usr/bin/env python

from __future__ import print_function
import os
import re
import sys
import subprocess
from cStringIO import StringIO
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
from httpconfig import config as C

def debug(line):
    if C['debug']:
        print(line)

################################################################################
# Locate the Perl & Python CGI Interpreters                                    #
################################################################################

interp = dict(
    perl   = None,
    python = None,
)

def find_interpreter(name, search):
    """Find an interpreter on the filesystem."""
    debug("Searching for %s" % name)
    for path in search:
        if os.path.isfile(path):
            debug("Found it at: %s" % path)
            return path
    return None

interp['perl']   = find_interpreter('perl', C['perl'])
interp['python'] = find_interpreter('python', C['python'])

################################################################################
# HTTP Server Request Handler                                                  #
################################################################################

def resolve_uri(uri):
    """Resolve an HTTP request URI to a local file on disk."""
    uri = re.sub(r'\.\.', '.', uri) # Remove duplicate dots.
    uri = re.sub(r'/+', '/', uri)   # Remove duplicate /'s.
    uri = re.sub(r'^/', '', uri)    # Remove leading /'s.
    debug("Resolve URI to file: %s" % uri)

    # Try the obvious first.
    root = C['document_root']
    if len(uri) > 0:
        root += "/" + uri
    if os.path.isfile(root):
        return root

    # Look for indexes.
    for index in C['indexes']:
        if os.path.isfile(root + "/" + index):
            return root + "/" + index

    return None

class Request(BaseHTTPRequestHandler):
    """HTTP Request Handler for rivescript-httpd."""

    def handle_request(self):
        method = self.command
        uri    = self.path
        query  = None
        ip     = self.client_address[0]

        reply   = 200 # Response status code
        content = ''  # Outgoing content
        header  = {   # Outgoing response headers
            'Content-Type' : 'text/plain',
            #'Server'       : 'rivescript-httpd.py',
        }

        if '?' in uri:
            uri, query = uri.split('?', 1)

        # Resolve the URI to a file.
        target = resolve_uri(uri)
        debug("File on disk: %s" % target)
        if target == None:
            # It's a 404!
            reply  = 404
            target = resolve_uri('/errors/404.html')

        # Check if it's a CGI script.
        is_cgi = False
        for ext in C['cgi_scripts']:
            if target.endswith(ext):
                is_cgi = True
                break
        debug("Is a CGI script? %r" % is_cgi)

        # Handle CGI scripts.
        if is_cgi:
            # What kind of CGI script is it?
            fh = open(target, 'r')
            shebang = fh.readline()
            shebang = re.sub(r'^#!', '', shebang)
            shebang = shebang.strip()

            # Identify Perl or Python.
            exe = None
            for lang in interp:
                if lang in shebang:
                    # Do we have the interpreter?
                    if interp[lang] != None:
                        exe = interp[lang]
            if exe == None:
                # Check if the raw shebang is there.
                fbin = shebang
                if ' ' in fbin:
                    fbin = fbin.split(' ', 1)
                if os.path.isfile(fbin):
                    exe = fbin

            # No exe? If it's Python, we can try to execute it ourselves.
            if exe == None:
                if 'python' in shebang:
                    debug("Gonna attempt to run this Python CGI ourselves.")
                    exe = '__self__'
                else:
                    # No interpreter found.
                    reply  = 500
                    target = resolve_uri('/errors/interp.html')
                    is_cgi = False

            # Have anything to execute this with?
            if exe:
                # Set up the environment variables.
                env = dict(
                    SERVER_SOFTWARE   = self.version_string(),
                    SERVER_NAME       = self.server.server_name,
                    GATEWAY_INTERFACE = 'CGI/1.1',
                    SERVER_PROTOCOL   = self.protocol_version,
                    SERVER_PORT       = str(self.server.server_port),
                    REQUEST_METHOD    = self.command,
                    PATH_INFO         = uri,
                    SCRIPT_NAME       = target,
                    REMOTE_ADDR       = ip,
                )
                if query:
                    env['QUERY_STRING'] = query
                referer = self.headers.getheader('referer')
                cookie  = self.headers.getheader('cookie')
                if referer:
                    env['HTTP_REFERER'] = referer
                if cookie:
                    env['HTTP_COOKIE'] = cookie

                # Since we're setting the env in the parent, provide empty
                # values to override previously set values.
                for key in ['QUERY_STRING', 'REMOTE_HOST', 'CONTENT_LENGTH',
                            'HTTP_USER_AGENT', 'HTTP_COOKIE', 'HTTP_REFERER']:
                    env.setdefault(key, '')
                os.environ.update(env)

                # Execute that script!
                results = list()
                if exe != '__self__':
                    proc = subprocess.Popen([ exe, target ],
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                    )
                    proc.wait()
                    err = proc.stderr.read()
                    rc  = proc.returncode
                    if rc != 0:
                        reply = 500
                    results = proc.stdout.readlines()
                else:
                    # Execute it ourself.
                    save_argv   = sys.argv
                    save_stdin  = sys.stdin
                    save_stdout = sys.stdout
                    save_stderr = sys.stderr
                    mystdout = StringIO()
                    mystderr = StringIO()
                    try:
                        sys.argv = [ target ]
                        sys.stdout = mystdout
                        sys.stderr = mystderr
                        execfile(target, {"__name__": "__main__"})
                    finally:
                        sys.argv   = save_argv
                        sys.stdin  = save_stdin
                        sys.stdout = save_stdout
                        sys.stderr = save_stderr
                        results = mystdout.getvalue().split("\n")

                # Parse out the headers.
                in_header = True
                for line in results:
                    tmpline = line.strip() # Remove line ending characters

                    # Process the HTTP headers in the response.
                    if in_header:
                        if len(tmpline) == 0: # End of headers
                            in_header = False
                            continue
                        if ":" in tmpline:
                            key, value = tmpline.split(":", 1)
                            key   = key.strip()
                            value = value.strip()

                            # The response status code?
                            if key.lower() == 'status':
                                reply = value
                            else:
                                # Normalize some headers.
                                if key.lower() == 'content-type':
                                    key = 'Content-Type'

                                # Store it.
                                header[key] = value
                    else:
                        content += line

        if not is_cgi:
            # Resolve the MIME type.
            for ext, mime in C['mime'].iteritems():
                if target.endswith(ext):
                    header['Content-Type'] = mime

            # Read and send.
            with open(target, 'rb') as fh:
                while True:
                    chunk = fh.read(8192)
                    if chunk:
                        content += chunk
                    else:
                        break


        if content:
            self.send_response(int(reply))
            for key, value in header.iteritems():
                self.send_header(key, value)
            self.end_headers()
            self.wfile.write(content)
        elif reply == 500:
            self.send_error(500, "Internal server error")
        else:
            self.send_error(404, "File not found")

    def do_GET(self):
        self.handle_request()

    def do_POST(self):
        self.handle_request()

    def do_HEAD(self):
        self.handle_request()

httpd = HTTPServer((C['address'], C['port']), Request)
print("Listening on http://%s:%d/" % (C['address'], C['port']))
httpd.serve_forever()
