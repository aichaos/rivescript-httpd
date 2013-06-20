config = dict(
    address = '127.0.0.1',
    port    = 2006,
    debug   = False,

    document_root = './public_html',
    cgi_scripts   = [ '.cgi', '.pl', '.py' ],
    indexes       = [ 'index.html', 'index.htm' ],

    # Where to find CGI interpreters.
    # The first item in each list is the 'usual' path (and will be the ones on
    # the shebang line in the scripts, e.g. #!/usr/bin/perl). The following
    # items are places to look for the interpreter if it wasn't found there.
    perl = [
        '/usr/bin/perl',
        'C:/Perl/bin/perl.exe',
        'C:/Perl64/bin/perl.exe',
    ],
    python = [
        '/usr/bin/python',
        'C:/Python27/python.exe',
        'C:/Python25/python.exe',
    ],

    # MIME type mappings. You probably don't need to touch these.
    mime = {
        '.html' : 'text/html',
        '.htm'  : 'text/html',
        '.text' : 'text/plain',
        '.txt'  : 'text/plain',
        '.rs'   : 'text/plain',
        '.css'  : 'text/css',
        '.js'   : 'text/javascript',
        '.gif'  : 'image/gif',
        '.png'  : 'image/png',
        '.jpeg' : 'image/jpeg',
        '.jpe'  : 'image/jpeg',
        '.jpg'  : 'image/jpeg',
        '.ico'  : 'image/x-icon',
    }
)
