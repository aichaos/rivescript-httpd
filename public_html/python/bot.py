#!/usr/bin/python

from __future__ import print_function

"""
RiveScript::HTTPd Example Python CGI Bot

Invoke this script using an Ajax call. It uses JSON encoding for its input and
output. See public_html/python/bot.js for usage example.

NOTE: This CGI script would run on an Apache server using mod_cgi. This means
that for each and every request, your entire RiveScript brain will need to be
loaded from scratch. This should be okay for small-to-medium size bots,
especially when the bots won't be chatted with simultaneously by a significant
number of users.
"""

import sys
sys.path.append("public_html/python")

import os
import json
import cgi
import Cookie
import datetime
import random
import hashlib
import rivescript

# import the config file.
import config

# For getting parameters
q = cgi.FieldStorage()

# Eventual JSON response.
resp = {
	'status': 'error',
	'name': config.bot_name,
}

# Cancel early on obvious errors.
if not os.path.exists(config.brain_path):
	resp['error'] = "Couldn't find brain path (%s): no directory found at that path!" % config.brain_path

################################################################################
# Function declarations                                                        #
################################################################################

def generate_sessid ():
	""" Generates a random session ID. """
	rand = random.randint(0,999999)
	m = hashlib.md5()
	m.update(str(rand))
	return m.hexdigest()

def session_id ():
	""" Gets or creates a unique session ID for the user. """
	# See if they have a session cookie already.
	sessid = ""
	try:
		cookie = Cookie.SimpleCookie(os.environ["HTTP_COOKIE"])
		sessid = cookie[config.session_cookie].value
	except:
		# Need to generate a new one.
		sessid = generate_sessid()

		# Make sure it's still available.
		if config.session_method == "mysql":
			pass # TODO
		else:
			while os.path.exists("%s/%s.json" % (config.json_root, sessid)):
				sessid = generate_sessid()

	return sessid

def recall_session (sessid, rs):
	""" Reload a user's session file from persistent storage. """
	uservars = {}

	# From MySQL or a file?
	if config.session_method == "mysql":
		pass # TODO
	else:
		path = "%s/%s.json" % (config.json_root, sessid)
		if os.path.exists(path):
			fh = open("%s/%s.json" % (config.json_root, sessid), 'r')
			uservars = json.load(fh)
			fh.close()

	# Set the user vars.
	for key in uservars:
		rs.set_uservar(sessid, key, uservars[key])

def write_session (sessid, rs):
	""" Write a user's session info to persistent storage. """

	# Get their vars from RiveScript.
	uservars = rs.get_uservars(sessid)

	# To MySQL or a file?
	if config.session_method == "mysql":
		pass # TODO
	else:
		path = "%s/%s.json" % (str(config.json_root), str(sessid))
		fh = open(path, 'w')
		fh.write(json.dumps(uservars))
		fh.close()

# TODO: mysql support

# Get or generate their unique session ID.
sessid = session_id()

# Make a cookie for the sessid.
expiration = datetime.datetime.now() + datetime.timedelta(days=30) # TODO: make configurable
cookie = Cookie.SimpleCookie()
cookie[config.session_cookie] = sessid
cookie[config.session_cookie]["path"] = "/"
cookie[config.session_cookie]["expires"] = \
	expiration.strftime("%a, %d-%b-%Y %H:%M:%S PST")


print("Content-Type: application/json")
print(cookie.output())
print()

# Handle their request now.
if not "error" in resp:
	if "message" in q:
		msg = q["message"].value

		# Initialize RiveScript.
		rs = rivescript.RiveScript()
		rs.load_directory(config.brain_path)
		rs.sort_replies()

		# Load their session vars.
		recall_session(sessid, rs)

		# Get a reply for them.
		reply = rs.reply(sessid, msg)

		# Save their session info.
		write_session(sessid, rs)

		resp["status"] = "ok"
		resp["name"]   = config.bot_name
		resp["reply"]  = reply
	elif "welcome" in q:
		resp["status"] = "ok"
		resp["name"]   = config.bot_name
		resp["reply"]  = config.welcome
	else:
		resp["error"]  = "No message provided by the user."


print(json.dumps(resp))


