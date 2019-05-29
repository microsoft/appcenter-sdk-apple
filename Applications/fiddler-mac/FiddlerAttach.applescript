on run argv
	do shell script setCorrectFormat(argv, " ") with administrator privileges
end run

on setCorrectFormat(aList, delimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delimiter
	
	set arguments to item 1 of aList
	set pathToScript to item 2 of aList
	set argumentsInCorrectFormat to replaceText(arguments, ",", space)
	
	set AppleScript's text item delimiters to oldDelimiters
	
	return "\"" & pathToScript & "\"" & " " & argumentsInCorrectFormat
end setCorrectFormat

to replaceText(someText, oldItem, newItem)
	(*
     replace all occurances of oldItem with newItem
          parameters -     someText [text]: the text containing the item(s) to change
                    oldItem [text, list of text]: the item to be replaced
                    newItem [text]: the item to replace with
          returns [text]:     the text with the item(s) replaced
     *)
	set {tempTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, oldItem}
	try
		set {itemList, AppleScript's text item delimiters} to {text items of someText, newItem}
		set {someText, AppleScript's text item delimiters} to {itemList as text, tempTID}
	on error errorMessage number errorNumber -- oops
		set AppleScript's text item delimiters to tempTID
		error errorMessage number errorNumber -- pass it on
	end try
	
	return someText
end replaceText