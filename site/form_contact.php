<?
	// define vars:
	$mail_to = 'dinko@dizzylabs.com'; // who the mail gets sent to;	
	$subject = 'Contact from Queries WebSite'; // the subject for the mail
	$mail_from = 'From: igor.anic@minus5.hr'; // who the mail gets sent from;
	$redir = 'contact.html';
	
	// php takes POST and GET variables and resolves them straight to PHP variables. 
	// ie, HTTP_POST_VARS['myfield'] == $myfield, but for the purpose of this script,
	// i'm just spewing out all of the post vars into a mail.
	
	// this loops thru the post vars
	while(list($key,$val) = each($_REQUEST)) {
		$alldata[] = $key . ":\t" . $val;
	}
	
	// alldata is the array which i have all the data in
	// put it into a string.
	$alldata_str = join($alldata, "\n");
	
	// send the mail
	mail($mail_to, $subject, $alldata_str, $mail_from);
	
	// redirect to whatever page you like
	header("Location: $redir");
?>