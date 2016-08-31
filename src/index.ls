
#	irc-support-js-webcompat
#	------------------------
#	Web standards compatibility checker for irc-support-bot
#	This is an official plug-in
#
#	Provides one bot command: 'compat'


util = require 'util'
api  = require 'caniuse-api'


module.exports = ->

	this.register_special_command do
		name: 'compat'
		description: 'Check browser support for web standards.'
		admin_only: false
		fn: (event, input-data, output-data) ~>

			opts = this.bot-options.plugin-options?['irc-support-bot-webcompat']
			args = input-data.args.split ' '

			try api.set-browser-scope opts.browsers if opts.browsers

			if '?' in input-data.flags
				message = [
					'''Syntax: compat latest • List the latest stable browser versions'''
					'''Syntax: compat scope • List the scope of browsers used for checking support'''
					'''Syntax: compat legend • Explains the compatibility result message'''
					'''Syntax: compat find <query> • Search the features to find the name to use for compatibility details'''
					'''Syntax: compat <feature> • Query web standards browser support for a feature'''
					'''Syntax: compat <feature> <browser> • Check web standards support for a feature against a browser, e.g. « fileapi ie 8 »'''
				]

				return this.send 'notice', event.person.nick, message

			else if args.0 is 'latest'
				message = "« web compatibility » latest stable browsers: #{api.get-latest-stable-browsers!join ', '}"

			else if args.0 is 'scope'
				message = "« web compatibility » browser scope: #{api.get-browser-scope!join ', '}"

			else if args.0 is 'legend'
				message = "« web compatibility » result message legend: y = yes, since version • n = no, up to version • a = partial, up to version • x = prefixed, up to version"

			else if args.0 is 'find'
				query = args.1

				if not query
					message = "Unsufficient arguments specified for « find »"
				else
					result = api.find query

					if not result.length
						message = "« web compatibility » no results for query « #query »"
					else
						message = "« web compatibility » results for query « #query »: #{result.join ', '}"

			# The main course, query feature support
			else if args.0 and not args.1
				feature = args.0

				try result = api.get-support feature

				if result
					result-ary = []
					for own p, v of result
						s1 = "#p • "
						s2 = for own pp, vv of v
							"#pp: #vv" if not pp.starts-with '#'
						s2 = s2.join ', '
						result-ary.push s1 + s2

					# result-str = result-ary.join '\n'

					uri = "http://caniuse.com/\#feat=#feature"
					result-ary.push "« #feature » details: #uri"

					return this.send output-data.method, output-data.recipient, result-ary

				else
					message = "« web compatibility » unknown feature « #feature » • use « #{input-data.trigger}compat find <query> » to find feature names; see « #{input-data.trigger}compat/? » for details"

			# The main course, specified by browser
			else if args.0 and args.1
				feature = args.0
				browser = args.slice 1 .join ' '

				try result = api.is-supported feature, browser
				catch
					if e.name is 'BrowserslistError'
						message = "« web compatibility » unknown browser « #browser » (note: you need a space between the name and the version number)"
					else message = "« web compatibility » unknown feature « #feature » • use « #{input-data.trigger}compat find <query> » to find feature names; see « #{input-data.trigger}compat/? » for details"

				if result?
					yesno = if result then '' else ' *NOT*'
					message = "« #feature » is#yesno supported in « #browser »"

			# Nothing useful found in input :(
			else
				message = "« web compatibility » insufficient arguments specified; see « #{input-data.trigger}compat/? » for details"


			this.send output-data.method, output-data.recipient, message if message
