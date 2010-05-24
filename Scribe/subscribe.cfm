<cfoutput>
	<form action="#cgi.script_name#" method="get">
		<input type="hidden" name="event" value="scribe-subscribe" />
		<p>Please enter the email address you want to <strong><em>subscribe</em></strong>:</p>
		<p><input type="text" name="email" value="" size="30" /></p>
		<p><input type="submit" value="Subscribe" /></p>
	</form>
</cfoutput>